+++
title = "Pre-requistes software"
description = "Pre-requistes software"
weight = 3
+++

Here are the list of softwares that needs to get installed in the laptop, before starting the workshop:

* [Docker Desktop](https://www.docker.com/products/docker-desktop) - The fastest way to containerize applications on your desktop. Make sure to enable **Hyper-V features** part of the software installation
* [Virtual Box](https://www.virtualbox.org/wiki/Downloads) - VirtualBox is a general-purpose full virtualizer for x86 hardware, targeted at server, desktop and embedded use.
* [Vagrant VM](https://www.vagrantup.com/downloads) - HashiCorp Vagrant provides the same, easy workflow regardless of your role as a developer, operator, or designer. It leverages a declarative configuration file which describes all your software requirements, packages, operating system configuration, users, and more
* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) - The AWS Command Line Interface (AWS CLI) is an open source tool that enables you to interact with AWS services using commands in your command-line shell
* JQ command line utility - jq is like sed for JSON data - you can use it to slice and filter and map and transform structured data with the same ease that sed, awk, grep and friends let you play with text

    #### Windows
    ```bash
    curl -L -o /usr/bin/jq.exe https://github.com/stedolan/jq/releases/latest/download/jq-win64.exe
    ```

    #### Mac
    ```bash
    brew install jq
    ```

    #### Linux
    ```bash
    apt-get install jq
    ```
* [Git client & Git Bash](https://git-scm.com/downloads) - In case of windows make sure `Git Bash` gets installed along with the command line tool
* [SAM (Serverless application model) CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html) - The AWS Serverless Application Model (SAM) is an open-source framework for building serverless applications. It provides shorthand syntax to express functions, APIs, databases, and event source mappings.

{{% notice info %}}
**Windows users only:** Use `Git Bash` as the default shell for running all the commands mentioned in this workshop. Make sure to start the `Git Bash` shell using "Run as adminstrator" option
{{% /notice %}}

* Configure the AWS account in AWS CLI by running the following command to enter in the AWS credentials used for this workshop

```bash
aws configure
```

> Note: Make sure the valid credentials with the right default region is entered here

* Run the following command to test your AWS access. This command should return all the AWS S3 buckets available in the configured AWS account

```bash
aws s3 ls
```
