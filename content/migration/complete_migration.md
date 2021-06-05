---
title: "Finish migration"
chapter: false
weight: 55
---

### What do we do now?

Now we need to get our application up and running in an orchestrated environment. 
Talk a bit about orchestrators and why they are so helpful.
This is a lot of work to do on our own, so let's choose a tool that will deploy my application artifact using recommended practices.
I also need to make sure that it can scale automatically, provide logs/metrics, run in my VPC, as well as talk to my existing database.

### AWS Copilot

What is AWS Copilot CLI

Let's walk through the documentation and see how it can help us

### Define our application

Copilot starts with defining our application. Look at this as in terms of a Service Oriented Architecture (SOA).
One application may be comprised of one, tens, hundreds, or thousands of services.

We'll start by issuing a command to create the structure of our application.

```bash
copilot app init
```

The CLI will ask some questions, and then it will begin to create the skeleton framework for our application.
It's not going to create our environments, we'll get into that in just a moment.
At a high level, copilot is going to provision an S3 Bucket, KMS Key, as well as ECR Repository to store our Docker images.
For more information, please refer to the [documentation](https://aws.github.io/copilot-cli/docs/concepts/applications/)


### Define our environment

When migrating applications from one environment to the next, we need to understand the requirements of the existing application.
Some simple things we need to look at are:

- Network/Communication
- Data
- DNS

Having a clear understanding of the current picture will help us as we migrate.
We mentioned earlier that we want to keep the same VPC to enable other services to communicate to the user api service.
It's recommended that you build a fresh new environment when possible as this will provide a clean slate.
Since we are keeping the VPC, we will create our environment but ensure that it connects to the existing VPC and doesn't create a new one.

```bash
copilot env init --import-vpc-id vpc-0defc00f1982a2399 --name test --app migration-demo
```

We will be prompted with a series of questions. 

- Choose the default profile for our credentials.
- Choose all of the subnets for public and private

Next, copilot is going to define and then build out our environment.
An environment includes the resources and "infrastructure" in which your services will be deployed to.
This includes the VPC, ECS Cluster, IAM roles, Security Groups, and so on.
For more information on what copilot does when creating environments, see the [documentation](https://aws.github.io/copilot-cli/docs/concepts/environments/)

### Define our service

Now we have our application and test environment ready to go.
We are ready to deploy our user-api service.
First, we will initialize our service as copilot will generate the manifest for us to define how the service is deployed and managed.

```bash
copilot svc init
```

Once again we are prompted with a series of questions that will guide us through the experience.

- Choose the Backend Service as this particular service is internal and not internet facing requiring a load balancer.
- Name the service userapi
- We are prompted to choose a Dockerfile, upstream image, or custom field. We will choose Dockerfile as we created this earlier.

Once done we are presented with the manifest file, let's take a look.

```bash
cat copilot/userapi/manifest.yml
```

Note that copilot was able to figure out that we want our app to run on port 8080, based on the EXPOSE parameter in our Dockerfile.
The manifest looks good, but we need to add some more information to ensure that the new container is ready to go.