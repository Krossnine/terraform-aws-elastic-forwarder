import { CloudWatchLogsDecodedData, CloudWatchLogsEvent, Handler } from 'aws-lambda';
import { match } from 'ts-pattern';
import { memoize } from 'lodash/fp';
import axios, { AxiosInstance } from 'axios';
import axiosRetry, { exponentialDelay } from 'axios-retry';
import pino from 'pino';
import z from 'zod';
import zlib from 'zlib';

export enum Log {
  ELK_ERROR = 'internal ELK error',
  HANDLER_ERROR = 'log forwarding error',
  HANDLER_SUCCEED = 'log forwarding succeed',
  PARSE_EVENT_DATA_ERROR = 'parse event data error',
  PARSE_MESSAGE_ERROR = 'parse message error',
  REQUEST_RETRY = 'retrying request',
  UNCOMPRESS_ERROR = 'uncompress error',
  UNEXPECTED_ERROR = 'unexpected error',
}

const logger = pino({
  level: process.env.LOG_LEVEL ?? 'info',
});

export const EnvSchema = z.object({
  ELASTIC_ALLOWED_LOG_FIELDS: z.string(),
  ELASTIC_SEARCH_INDEX: z.string(),
  ELASTIC_SEARCH_PASSWORD: z.string(),
  ELASTIC_SEARCH_RETRY_COUNT: z.string().regex(/^\d+$/).default('3').transform(Number),
  REQUEST_TIMEOUT_MS: z.string().regex(/^\d+$/).default('15000').transform(Number),
  ELASTIC_SEARCH_URL: z.string(),
  ELASTIC_SEARCH_USERNAME: z.string(),
});

export const getEnv = () => {
  const env = process.env;
  const result = EnvSchema.safeParse(env);

  return match(result)
    .with({ success: true }, ({ data }) => data)
    .with({ success: false }, ({ error }) => {
      throw error;
    })
    .exhaustive();
};

export const getClient = (): AxiosInstance => {
  const {
    ELASTIC_SEARCH_URL,
    REQUEST_TIMEOUT_MS,
    ELASTIC_SEARCH_PASSWORD,
    ELASTIC_SEARCH_RETRY_COUNT,
    ELASTIC_SEARCH_USERNAME,
  } = getEnv();

  const instance = axios.create({
    baseURL: ELASTIC_SEARCH_URL,
    timeout: REQUEST_TIMEOUT_MS,
    auth: {
      username: ELASTIC_SEARCH_USERNAME,
      password: ELASTIC_SEARCH_PASSWORD,
    },
  });

  axiosRetry(instance, {
    onRetry: (retryCount, error) => logger.info({ retryCount, error }, Log.REQUEST_RETRY),
    retries: ELASTIC_SEARCH_RETRY_COUNT,
    retryCondition: (error) => {
      const { response } = error;
      if (response) {
        const { status } = response;
        return status === 502 || status === 503 || status === 504;
      }
      return axiosRetry.isNetworkError(error);
    },
    retryDelay: exponentialDelay,
    shouldResetTimeout: true,
  });

  return instance;
};

export const unzipLogsEventData = (buff: Buffer): Promise<Buffer> =>
  new Promise((resolve, reject) => {
    zlib.unzip(buff, (err, result) => {
      if (err) {
        logger.error(err, Log.UNCOMPRESS_ERROR);
        return reject(err);
      }

      return resolve(result);
    });
  });

export const decodeLogsEventData = (buff: Buffer): CloudWatchLogsDecodedData => {
  try {
    return JSON.parse(buff.toString('utf8'));
  } catch (err) {
    logger.error(err, Log.PARSE_EVENT_DATA_ERROR);
    throw err;
  }
};

export const parseMessageObj = (message: string): Record<string, unknown> | undefined => {
  try {
    // Quick and dirty check if message seems to be a JSON object
    return message.startsWith('{') && message.endsWith('}')
      ? parseAndFilterMessageFields(message)
      : undefined;
  } catch (err) {
    logger.error(err, Log.PARSE_MESSAGE_ERROR);
    throw err;
  }
};

export const parseAndFilterMessageFields = (message: string): Record<string, unknown> => {
  const parsedMessage = JSON.parse(message);
  const flattenMessage = deepFlatObject(parsedMessage);

  return filterLog(flattenMessage) as Record<string, unknown>;
};

export const filterLog = memoize((args: object): object | Record<string, unknown> => {
  const { ELASTIC_ALLOWED_LOG_FIELDS } = getEnv();
  const allowedFields = ELASTIC_ALLOWED_LOG_FIELDS.split(',').filter(Boolean);

  return match(allowedFields)
    .with([], () => args)
    .otherwise(() => {
      const schema = z
        .object(allowedFields.reduce((s, k) => ({ ...s, [k]: z.any() }), {}))
        .partial();
      return schema.parse(args);
    });
});

export const deepFlatObject = (
  obj: { [key: string]: unknown },
  parent?: string,
): Record<string, unknown> => {
  let result: Record<string, unknown> = {};

  Object.keys(obj).forEach((key) => {
    const value = obj[key];
    const newKey = parent ? `${parent}.${key}` : key;

    // Be careful with null values
    match(value === null || typeof value)
      .with('object', () => {
        result = { ...result, ...deepFlatObject(value as { [key: string]: unknown }, newKey) };
      })
      .otherwise(() => {
        result[newKey] = value;
      });
  });
  return result;
};

export const transform = (logs: CloudWatchLogsDecodedData): string => {
  const { ELASTIC_SEARCH_INDEX } = getEnv();
  const { logEvents } = logs;
  const bulkData: object[] = [];

  logEvents.forEach((logEvent) => {
    const message = parseMessageObj(logEvent.message) ?? logEvent.message;
    const action = {
      index: {
        _index: ELASTIC_SEARCH_INDEX,
        _id: logEvent.id,
        require_alias: true,
      },
    };
    const data = {
      '@id': logEvent.id,
      '@timestamp': logEvent.timestamp,
      '@log_group': logs.logGroup,
      '@log_stream': logs.logStream,
      '@message_type': logs.messageType,
      '@owner': logs.owner,
      ...(typeof message === 'object' ? message : { message }),
    };

    bulkData.push(action, data);
  });

  return bulkData.map((d) => JSON.stringify(d)).join('\n') + '\n';
};

export const send = async (messages: string) => {
  const client = getClient();

  return client.post('', messages, {
    headers: {
      'content-type': 'application/x-ndjson',
    },
  });
};

export const handler: Handler<CloudWatchLogsEvent, void> = async (event, ctx) => {
  logger.info(ctx);

  const buff = Buffer.from(event.awslogs.data, 'base64');

  try {
    const eventData = await unzipLogsEventData(buff);
    const decodedData = decodeLogsEventData(eventData);
    const messages = transform(decodedData);

    const res = await send(messages);

    match(res)
      .with({ status: 200, data: { errors: false } }, () =>
        logger.debug(res.data, Log.HANDLER_SUCCEED),
      )
      .with({ status: 200, data: { errors: true } }, () => logger.error(res.data, Log.ELK_ERROR))
      .otherwise(() => logger.error(res, Log.UNEXPECTED_ERROR));
  } catch (e) {
    logger.fatal(e, Log.HANDLER_ERROR);
  }
};
