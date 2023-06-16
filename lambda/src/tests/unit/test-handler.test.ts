import { CloudWatchLogsEvent, Context } from 'aws-lambda';
import {
  handler,
  getEnv,
  getClient,
  unzipLogsEventData,
  Log,
  decodeLogsEventData,
  parseMessageObj,
  filterLog,
  parseAndFilterMessageFields,
  deepFlatObject,
  transform,
} from '../../app';
import { describe, expect, it, jest } from '@jest/globals';
import axios from 'axios';
import fixture from './event.fixture.json';

const mockedLoggerError = jest.fn();
jest.mock('pino', () => ({
  __esModule: true,
  default: jest.fn(() => ({
    info: jest.fn(),
    error: (...args: unknown[]) => mockedLoggerError(...args),
    debug: jest.fn(),
    fatal: jest.fn(),
  })),
}));

const mockedAxiosRetry = jest.fn();
jest.mock('axios-retry', () => {
  return {
    __esModule: true,
    default: (...args: unknown[]) => mockedAxiosRetry(...args),
    exponentialDelay: jest.fn(),
  };
});

const defaultEnv = {
  ELASTIC_ALLOWED_LOG_FIELDS: 'a,b,c',
  ELASTIC_SEARCH_INDEX: 'my-super-index',
  ELASTIC_SEARCH_PASSWORD: 'password',
  ELASTIC_SEARCH_RETRY_COUNT: '3',
  REQUEST_TIMEOUT_MS: '15000',
  ELASTIC_SEARCH_URL: 'http://localhost:9200',
  ELASTIC_SEARCH_USERNAME: 'username',
};

describe('Lambda', () => {
  const env = process.env;

  beforeEach(() => {
    jest.resetModules();
    process.env = { ...env, ...defaultEnv };
  });

  afterEach(() => {
    process.env = env;
  });

  describe('Handler', () => {
    it('should not throw error', async () => {
      const ctx: Context = {
        callbackWaitsForEmptyEventLoop: false,
        functionName: 'log-forwarder',
        functionVersion: '1',
        invokedFunctionArn: 'arn:aws:lambda:us-east-1:123456789012:function:log-forwarder',
        memoryLimitInMB: '128',
        awsRequestId: '1234567890',
        logGroupName: 'log-forwarder',
        logStreamName: 'log-forwarder',
        getRemainingTimeInMillis: () => 1000,
        done: function (): void {
          throw new Error('Function is deprecated.');
        },
        fail: function (): void {
          throw new Error('Function is deprecated.');
        },
        succeed: function (): void {
          throw new Error('Function is deprecated.');
        },
      };

      const event: CloudWatchLogsEvent = {
        awslogs: {
          data: 'H4sIAAAAAAAAAHWPwQqCQBCGX0Xm7EFtK+smZBEUgXoLCdMhFtKV3akI8d0bLYmibvPPN3wz00CJxmQnTO41whwWQRIctmEcB6sQbFC3CjW3XW8kxpOpP+OC22d1Wml1qZkQGtoMsScxaczKN3plG8zlaHIta5KqWsozoTYw3/djzwhpLwivWFGHGpAFe7DL68JlBUk+l7KSN7tCOEJ4M3/qOI49vMHj+zCKdlFqLaU2ZHV2a4Ct/an0/ivdX8oYc1UVX860fQDQiMdxRQEAAA==',
        },
      };

      const res = await handler(event, ctx, () => null);
      expect(res).toBeUndefined();
    });
  });

  describe('getEnv', () => {
    describe('when env is valid', () => {
      it('should return env with casting', () => {
        expect(getEnv).not.toThrow();
        expect(getEnv()).toEqual({
          ...defaultEnv,
          ELASTIC_SEARCH_RETRY_COUNT: 3,
          REQUEST_TIMEOUT_MS: 15000,
        });
      });
    });

    describe('when env is invalid', () => {
      it('should throw error', () => {
        process.env = {
          ...defaultEnv,
          ELASTIC_SEARCH_RETRY_COUNT: 'invalid',
        };

        expect(getEnv).toThrow();
      });
    });
  });

  describe('getClient', () => {
    it('should return a configured axios instance', () => {
      const spyedAxiosCreate = jest.spyOn(axios, 'create');
      const client = getClient();

      expect(spyedAxiosCreate).toHaveBeenCalledWith({
        baseURL: defaultEnv.ELASTIC_SEARCH_URL,
        timeout: 15000,
        auth: {
          username: defaultEnv.ELASTIC_SEARCH_USERNAME,
          password: defaultEnv.ELASTIC_SEARCH_PASSWORD,
        },
      });

      expect(client).toEqual(
        expect.objectContaining({
          post: expect.any(Function),
          interceptors: expect.any(Object),
        }),
      );
    });

    it('should wrap axios instance with axiosRetry', () => {
      getClient();
      expect(mockedAxiosRetry).toHaveBeenCalled();
    });

    it('should correctly define retry strategy', () => {
      getClient();

      expect(mockedAxiosRetry).toHaveBeenCalledWith(
        expect.any(Function),
        expect.objectContaining({
          onRetry: expect.any(Function),
          retries: parseInt(defaultEnv.ELASTIC_SEARCH_RETRY_COUNT, 10),
          retryCondition: expect.any(Function),
          retryDelay: expect.any(Function),
        }),
      );
    });

    it('should reset timeout in retry strategy', () => {
      getClient();

      expect(mockedAxiosRetry).toHaveBeenCalledWith(
        expect.any(Function),
        expect.objectContaining({
          shouldResetTimeout: true,
        }),
      );
    });
  });

  describe('unzipLogsEventData', () => {
    it('should reject with error log when unzip failed', async () => {
      const buff = Buffer.from('invalid', 'base64');
      await expect(unzipLogsEventData(buff)).rejects.toThrow();
      expect(mockedLoggerError).toHaveBeenCalledWith(expect.anything(), Log.UNCOMPRESS_ERROR);
    });

    it('should resolve with unzipped data', async () => {
      const buff = Buffer.from(
        'H4sIAAAAAAAAAHWPwQqCQBCGX0Xm7EFtK+smZBEUgXoLCdMhFtKV3akI8d0bLYmibvPPN3wz00CJxmQnTO41whwWQRIctmEcB6sQbFC3CjW3XW8kxpOpP+OC22d1Wml1qZkQGtoMsScxaczKN3plG8zlaHIta5KqWsozoTYw3/djzwhpLwivWFGHGpAFe7DL68JlBUk+l7KSN7tCOEJ4M3/qOI49vMHj+zCKdlFqLaU2ZHV2a4Ct/an0/ivdX8oYc1UVX860fQDQiMdxRQEAAA==',
        'base64',
      );
      const res = await unzipLogsEventData(buff);
      expect(res).toBeInstanceOf(Buffer);
    });
  });

  describe('decodeLogsEventData', () => {
    describe('when data is a valid JSON', () => {
      it('should return decoded data', () => {
        const initialData = { myProp: 'myValue' };
        const stringifiedData = JSON.stringify(initialData);
        const bufferizedData = Buffer.from(stringifiedData);
        const res = decodeLogsEventData(bufferizedData);
        expect(res).toEqual(initialData);
      });
    });

    describe('when data is not a valid JSON', () => {
      it('should throw error and log it', () => {
        const initialData = 'invalid';
        const bufferizedData = Buffer.from(initialData);
        expect(() => decodeLogsEventData(bufferizedData)).toThrow();
        expect(mockedLoggerError).toHaveBeenCalledWith(
          expect.anything(),
          Log.PARSE_EVENT_DATA_ERROR,
        );
      });
    });
  });

  describe('parseMessageObj', () => {
    describe('when message is a valid JSON', () => {
      it('should return parsed message', () => {
        const initialData = {
          a: 'myValue',
          b: 'myValue',
          c: 'myValue',
        };
        const stringifiedData = JSON.stringify(initialData);
        const res = parseMessageObj(stringifiedData);
        expect(res).toEqual(initialData);
      });
    });

    describe('when message is not a valid JSON', () => {
      it("should return undefined if message doesn't start with a curly bracket", () => {
        const initialData = 'myProp: "myValue"}';
        const res = parseMessageObj(initialData);
        expect(res).toBeUndefined();
      });

      it("should return undefined if message doesn't end with a curly bracket", () => {
        const initialData = '{myProp: "myValue"';
        const res = parseMessageObj(initialData);
        expect(res).toBeUndefined();
      });

      it('should return undefined and log an error with a corrupted stringified object', () => {
        const malforedData = '{"a":"myValue","b":' + 'corruptValue10 ' + '"myValue","c":"myValue"}';
        expect(parseMessageObj(malforedData)).toBeUndefined();
        expect(mockedLoggerError).toHaveBeenCalledWith(expect.anything(), Log.PARSE_MESSAGE_ERROR);
      });
    });

    describe('when message is obviously not a JSON', () => {
      it('should return undefined', () => {
        const initialData = '12';
        const res = parseMessageObj(initialData);
        expect(res).toBeUndefined();
      });
    });
  });

  describe('filterLog', () => {
    it('should be a memoized function', () => {
      expect(filterLog).toBeInstanceOf(Function);
      expect(filterLog.cache).toEqual(expect.any(Object));
    });

    describe('when allowed fields env var is empty', () => {
      it('should return the initial log', () => {
        process.env.ELASTIC_ALLOWED_LOG_FIELDS = '';
        const initialLog = {
          a: 'myValue',
          b: 'myValue',
          c: 'myValue',
        };

        const res = filterLog(initialLog);
        expect(res).toEqual(initialLog);
      });
    });

    describe('when allowed fields env var is not an empty', () => {
      it('should return the filtered log with only allowed fields', () => {
        const initialLog = {
          a: 'myValue',
          b: 'myValue',
          c: 'myValue',
          d: 'myValue',
          e: {
            f: 'myValue',
          },
        };

        const res = filterLog(initialLog);
        expect(res).toEqual({
          a: 'myValue',
          b: 'myValue',
          c: 'myValue',
        });
      });
    });
  });

  describe('parseAndFilterMessageFields', () => {
    it('should return the filtered log with only allowed fields', () => {
      const initialLog = {
        a: 'myValue',
        b: 'myValue',
        c: 'myValue',
        d: 'myValue',
        e: {
          f: 'myValue',
        },
      };
      const stringifiedData = JSON.stringify(initialLog);

      const res = parseAndFilterMessageFields(stringifiedData);
      expect(res).toEqual({
        a: 'myValue',
        b: 'myValue',
        c: 'myValue',
      });
    });

    it('should return the filtered log with allowed fields event if nested', () => {
      process.env.ELASTIC_ALLOWED_LOG_FIELDS = 'd,e.f';
      const initialLog = {
        a: 'unallowedValue',
        b: 'unallowedValue',
        c: 'unallowedValue',
        d: 'firstAllowedValue',
        e: {
          f: 'secondAllowedValue',
        },
        g: {
          h: 'unallowedValue',
        },
      };
      const stringifiedData = JSON.stringify(initialLog);

      const res = parseAndFilterMessageFields(stringifiedData);
      expect(res).toEqual({
        d: 'firstAllowedValue',
        'e.f': 'secondAllowedValue',
      });
    });
  });

  describe('deepFlatObject', () => {
    it('should return a flat object', () => {
      const obj = {
        a: {
          b: { c: { d: { e: 42, f: { g: 'In code we Rust' } } } },
          nullProp: null,
        },
        otherProp: undefined,
      };
      expect(deepFlatObject(obj)).toEqual({
        otherProp: undefined,
        'a.nullProp': null,
        'a.b.c.d.e': 42,
        'a.b.c.d.f.g': 'In code we Rust',
      });
    });
  });

  describe('transform', () => {
    it('should return a valid x-ndjson string', () => {
      const res = transform(fixture.cloudWatchLogsDecodedData);
      const lines = res.split('\n');

      const actionLine = lines[0];
      const logLine = lines[1];
      const shouldEndWithATrailingBreakLine = res.endsWith('\n');

      expect(typeof res).toEqual('string');
      expect(shouldEndWithATrailingBreakLine).toEqual(true);
      expect(() => JSON.parse(actionLine)).not.toThrow();
      expect(() => JSON.parse(logLine)).not.toThrow();
    });

    it('should return a pair of action and log entry for each log message', () => {
      const res = transform(fixture.cloudWatchLogsDecodedData);
      const lines = res.split('\n');
      const filteredLines = lines.filter(Boolean); // remove trailing break line

      expect(filteredLines.length).toEqual(2 * fixture.cloudWatchLogsDecodedData.logEvents.length);

      filteredLines.forEach((line, index) => {
        if (index % 2 == 0) {
          expect(line).toEqual(expect.stringContaining('{"index":{"_index":"'));
        } else {
          expect(line).toEqual(expect.stringContaining('"@timestamp":'));
        }
      });
    });

    describe('action', () => {
      it('should match the action schema', () => {
        const res = transform(fixture.cloudWatchLogsDecodedData);
        const lines = res.split('\n');
        const actionLine = lines[0];
        const action = JSON.parse(actionLine);

        expect(action).toEqual(
          expect.objectContaining({
            index: expect.objectContaining({
              _index: expect.any(String),
              _id: expect.any(String),
              require_alias: expect.any(Boolean),
            }),
          }),
        );
      });

      it('should map all action fields correctly', () => {
        const res = transform(fixture.cloudWatchLogsDecodedData);
        const lines = res.split('\n');
        const actionLine = lines[0];
        const logLine = lines[1];

        const action = JSON.parse(actionLine);
        const log = JSON.parse(logLine);

        expect(action.index._index).toEqual(defaultEnv.ELASTIC_SEARCH_INDEX);
        expect(action.index._id).toEqual(log['@id']);
        expect(action.index.require_alias).toEqual(true);
      });
    });

    describe('log entry', () => {
      it('should match the log entry schema', () => {
        process.env.ELASTIC_ALLOWED_LOG_FIELDS = 'source,time';
        const res = transform(fixture.cloudWatchLogsDecodedData);
        const lines = res.split('\n');

        // Object log line
        const objLogLine = lines[1];
        const objLog = JSON.parse(objLogLine);

        // Text log line
        const textLogLine = lines[3];
        const textLog = JSON.parse(textLogLine);

        expect(objLog).toEqual(
          expect.objectContaining({
            source: expect.anything(),
            time: expect.anything(),
          }),
        );

        expect(textLog).toEqual(
          expect.objectContaining({
            message: expect.any(String),
          }),
        );
      });

      it('should return a log entry with all mandatory fields', () => {
        const res = transform(fixture.cloudWatchLogsDecodedData);
        const lines = res.split('\n');
        const event = fixture.cloudWatchLogsDecodedData.logEvents[0];
        const { logGroup, logStream, messageType, owner } = fixture.cloudWatchLogsDecodedData;
        const logLine = lines[1];
        const log = JSON.parse(logLine);

        expect(log).toMatchObject({
          '@id': event.id,
          '@timestamp': '2023-05-26T10:05:41.347Z',
          '@log_group': logGroup,
          '@log_stream': logStream,
          '@message_type': messageType,
          '@owner': owner,
        });
      });
    });

    describe('with json log message', () => {
      const nginxLog = fixture.cloudWatchLogsDecodedData.logEvents[0];
      const nginxMsg = JSON.parse(nginxLog.message);
      const allowedFields = [
        'host',
        'method',
        'referer',
        'request',
        'requestTime',
        'source',
        'time',
        'upstreamHeaderTime',
      ];
      const sample = {
        ...fixture.cloudWatchLogsDecodedData,
        logEvents: [nginxLog],
      };

      it('should parse and filter a simple nginx message based on allowed fields', () => {
        process.env.ELASTIC_ALLOWED_LOG_FIELDS = allowedFields.join(',');
        const res = transform(sample);
        const [actionRaw, dataRaw] = res.split('\n').filter(Boolean);
        const action = JSON.parse(actionRaw);
        const data = JSON.parse(dataRaw);

        // Assertions :
        expect(typeof res).toEqual('string');
        expect(res.endsWith('\n')).toEqual(true);

        // Actions :
        expect(action).toMatchObject({
          index: {
            _index: defaultEnv.ELASTIC_SEARCH_INDEX,
            _id: nginxLog.id,
            require_alias: true,
          },
        });

        // Data :
        expect(data).toEqual(
          expect.objectContaining({
            '@id': nginxLog.id,
            '@timestamp': '2023-05-26T10:05:41.347Z',
            '@log_group': sample.logGroup,
            '@log_stream': sample.logStream,
            '@message_type': sample.messageType,
            '@owner': sample.owner,
          }),
        );

        allowedFields.forEach((field) => {
          expect(data[field]).toBeDefined();
          expect(data[field]).toEqual(nginxMsg[field]);
        });
      });

      it('should parse and filter complexes and nested log messages', () => {
        const customFields = [...allowedFields, 'a.deep.nested.property.in.the.message'];
        const customSample = sample;
        customSample.logEvents[0].message = JSON.stringify({
          ...nginxMsg,
          a: {
            deep: {
              nested: {
                property: {
                  in: {
                    the: {
                      message: Math.PI,
                    },
                  },
                },
              },
            },
          },
        });

        process.env.ELASTIC_ALLOWED_LOG_FIELDS = customFields.join(',');
        const res = transform(sample);
        const [, dataRaw] = res.split('\n').filter(Boolean);
        const data = JSON.parse(dataRaw);

        expect(data['a.deep.nested.property.in.the.message']).toEqual(Math.PI);
        allowedFields.forEach((field) => {
          expect(data[field]).toBeDefined();
          expect(data[field]).toEqual(nginxMsg[field]);
        });
      });

      it('should parse json even if line break or space are present', () => {
        process.env.ELASTIC_ALLOWED_LOG_FIELDS = allowedFields.join(',');
        const tmpSample = sample;

        // Add a whitespace at the beginning and line break at the end of the message
        tmpSample.logEvents[0].message = ' ' + tmpSample.logEvents[0].message + '\n';

        const res = transform(sample);
        const [actionRaw, dataRaw] = res.split('\n').filter(Boolean);
        const action = JSON.parse(actionRaw);
        const data = JSON.parse(dataRaw);

        // Assertions :
        expect(typeof res).toEqual('string');
        expect(res.endsWith('\n')).toEqual(true);

        // Actions :
        expect(action).toMatchObject({
          index: {
            _index: defaultEnv.ELASTIC_SEARCH_INDEX,
            _id: nginxLog.id,
            require_alias: true,
          },
        });

        // Data :
        expect(data).toEqual(
          expect.objectContaining({
            '@id': nginxLog.id,
            '@timestamp': '2023-05-26T10:05:41.347Z',
            '@log_group': sample.logGroup,
            '@log_stream': sample.logStream,
            '@message_type': sample.messageType,
            '@owner': sample.owner,
          }),
        );

        allowedFields.forEach((field) => {
          expect(data[field]).toBeDefined();
          expect(data[field]).toEqual(nginxMsg[field]);
        });
      });
    });

    describe('with text log message', () => {
      it('should return a log entry with message field equal to the initial message string even if fields are restricted', () => {
        process.env.ELASTIC_ALLOWED_LOG_FIELDS = 'a,b,c';
        const sample = {
          ...fixture.cloudWatchLogsDecodedData,
          logEvents: [fixture.cloudWatchLogsDecodedData.logEvents[0]],
        };
        sample.logEvents[0].message = 'a famous and important message to forward';
        const res = transform(sample);
        const lines = res.split('\n');
        const logLine = lines[1];
        const log = JSON.parse(logLine);

        expect(log.message).toEqual(sample.logEvents[0].message);
      });
    });
  });
});
