# Contributing

When contributing to this repository, please first discuss the change you wish to make via issue, email, or any other method with the owners of this repository before making a change.


## Development environment setup

To set up a development environment, please follow these steps:

1. Fork the repository on GitHub:

2. Clone your fork of the repository:

   ```sh
   git clone https://github.com/YOUR_USERNAME/terraform-aws-elastic-forwarder.git
   ```

3. Install dependencies:
    - Bases :
      - Install [Terraform](https://www.terraform.io/downloads.html) (v0.12.0+)
      - Install [Node & npm](https://nodejs.org/en/download) (v14.15.0+)
      - Install [pre-commit](https://pre-commit.com/#install) (v3.3.2+)

    - Pre-commit hooks :
      - Install [TFLint](https://github.com/terraform-linters/tflint) (v0.46.1+)
      - Install [Terraform-docs](https://terraform-docs.io/user-guide/installation/) (v0.16.0+)
      - Install [Checkov](https://github.com/bridgecrewio/checkov#installation) (v2.3.273+)

    - For testing lambda :
      - Install [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html#install-sam-cli-instructions)

    - (Optional) To run Github actions locally :
      - Install [Docker](https://docs.docker.com/get-docker/) (v20.10.0+)
      - Install [Act](https://github.com/nektos/act#installation-through-package-managers) (v0.2.46+)


4. AWS Lambda function development

  - Install dependencies :
    ```sh
    cd ./lambda/src
    npm i
    ```

  - Common scripts :
    ```sh
    cd ./lambda/src
    npm run compile     // Compile typescript to javascript
    npm run unit        // Run unit tests
    npm run functional  // Run functional tests
    npm run lint        // check code style
    npm run lint-fix    // fix code style
    ```

  - Build lambda function :
    ```sh
    cd ./lambda
    sam build
    ```

  - Compress lambda function :
    ```sh
    cd ./lambda/src
    npm i
    npm run compile
    cd ../.aws-sam/build/LogForwarderFunction
    zip -r ../../../LogForwarderFunction.zip .
    ```

5. Run pre-commit by hand :

  - All hooks :
    ```sh
    pre-commit run --all-files
    ```

  - Specific hook :
    ```sh
    pre-commit run terraform_fmt
    pre-commit run terraform_tflint
    pre-commit run terraform_validate
    pre-commit run terraform_tfsec
    pre-commit run terraform_docs
    pre-commit run terraform_checkov
    ```

6. Run CI/CD pipeline locally :

You can test Github actions locally with Act. To do so, you need to have Docker installed on your machine and Act.

  - Most common commands :
    ```sh
    act -l
    act -P ubuntu-latest=nektos/act-environments-ubuntu:18.04
    act pull_request
    ```

  - Run all jobs :
    ```sh
    act
    ```

  - Run specific workflow :
    ```sh
    # act -W <workflow_name>
    act -W .github/workflows/test-tf.yml
    ```

  - Run specific job :
    ```sh
    # act -j <job_name>
    act -j bump-and-build
    ```

  - Run specific job with specific event :
    ```sh
    act -j <job_name> -e <event_name>
    ```

## Issues and feature requests

You've found a bug in the source code, a mistake in the documentation or maybe you'd like a new feature? You can help us by [submitting an issue on GitHub](https://github.com/Krossnine/terraform-aws-elastic-forwarder/issues). Before you create an issue, make sure to search the issue archive -- your issue may have already been addressed!

Please try to create bug reports that are:

- _Reproducible._ Include steps to reproduce the problem.
- _Specific._ Include as much detail as possible: which version, what environment, etc.
- _Unique._ Do not duplicate existing opened issues.
- _Scoped to a Single Bug._ One bug per report.

**Even better: Submit a pull request with a fix or new feature!**

### How to submit a Pull Request

1. Search our repository for open or closed
   [Pull Requests](https://github.com/Krossnine/terraform-aws-elastic-forwarder/pulls)
   that relate to your submission. You don't want to duplicate effort.
2. Fork the project
3. Create your feature branch (`git checkout -b feat/amazing_feature`)
4. Commit your changes (`git commit -m 'feat: add amazing_feature'`)
   Krossnine/terraform-aws-elastic-forwarder uses [conventional commits](https://www.conventionalcommits.org), so please follow the specification in your commit messages. This will allow us to automatically generate a changelog from your pull request.
5. Push to the branch (`git push origin feat/amazing_feature`)
6. [Open a Pull Request](https://github.com/Krossnine/terraform-aws-elastic-forwarder/compare?expand=1)
