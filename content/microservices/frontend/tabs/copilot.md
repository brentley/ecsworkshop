---
title: "Acceptance and Production"
disableToc: true
hidden: true
---
 
## Deploy our application, service, and environment

Navigate to the frontend service repo.

```bash
cd ~/environment/ecsdemo-frontend
```

To start, we will initialize our application, and create our first service.
In the context of copilot-cli, the application is a group of related services, environments, and pipelines. 
Run the following command to get started:

```bash
copilot init
```

We will be prompted with a series of questions related to the application, and then our service. Answer the questions as follows:

- Application name: ecsworkshop
- Service Type: Load Balanced Web Service
- What do you want to name this Load Balanced Web Service: ecsdemo-frontend
- Dockerfile: ./Dockerfile

After you answer the questions, it will begin the process of creating some baseline resources for your application and service. 
This includes the manifest file for the frontend service, which we will review later.

Next, you will be prompted to deploy a test environment. An environment encompasses all of the resources that are required to support running your containers in ECS.
This includes the networking stack (VPC, Subnets, Security Groups, etc), the ECS Cluster, Load Balancers (if required), and more.

Type "y", and hit enter. This part will take a few minutes because of all of the resources that are being created. This is not an action you run every time you deploy your service, it's just the one time to get your environment up and running.

Below is an example of what the cli interaction will look like:

![deployment](/images/copilot-frontend.gif)

Ok, that's it! With one command and answering a few questions, we have our frontend service deployed to an environment! But how do we interact with our environment and service? Let's dive in and answer those questions.

## Interacting with the application

To interact with our application, run the following in the terminal:

```bash
copilot app
```

This will bring up a help message that looks like the below image.

![app](/images/copilot-app.png)

We can see the available commands, so let's first see what applications we have deployed. 

```bash
copilot app ls
```

The output should show one application, and it should be named "ecsworkshop", which we named when we ran copilot init earler.
When you start managing multiple applications with copilot, this will serve as that single command to get insight into all of them.

![app_ls](/images/copilot-app-ls.png)

Now that we see our application, let's get a more detailed view into what environments and services our application contains.

```bash
copilot app show ecsworkshop
```

The result should look like this:

![app_show](/images/copilot-app-show.png)

Reviewing the output, we can see that all of the environments that are application is deployed to, as well as the services deployed under the application.
In a production scenario, we would want to deploy a production environment that is completely isolated from test. Ideally that would be in another account as well.
With this view, we can get a view into what accounts and regions our application is deployed to.

## Interacting with the environment

Let's now look deeper into our test environment. To interact with our environments, we will use the `copilot env` command.

![env_ls](/images/copilot-env-ls.png)

To list the environments, run:

```bash
copilot env ls
```

The response will come back with test, so let's get more details on the test environment by running:

```bash
copilot env show -n test
```

![env_show](/images/copilot-env-show.png)

With this view, we're able to see all of the services deployed to our applciation's test environment. As we add more services, we will see this grow.
A couple of neat things to point out here: 

- The tags associated with our environment. The default tags have the application name as well as the environment.
- The details about the environment such as account id, region, and if the environment is considered production.

## Interacting with the frontend service

![env_show](/images/copilot-svc.png)

There is a lot of power with the `copilot svc` command. As you can see from the above, we can achieve quite a bit with this command.
Let's look at a couple of the commands:

- package: The copilot-cli uses CloudFormation to manage the state of the environment and services. If you want to get the CloudFormation template for the service deployment, you can simply run `copilit svc package`. This can be especially helpful if you for some reason decide to move to CloudFormation to manage your deployments on your own.
- deploy: To put it simply, this will deploy your service. For local development, this enables one to locally push their service changes up to the desired environment. Of course when it comes time to deploy to production, a proper git workflow integrated with CI/CD would be the best path forward. We will deploy a pipeline later!
- status: This command will give us a detailed view of the the service. This includes health information, task information, as well as active task count with details.
- logs: Lastly, this is an easy way to view your service logs from the command line.

Let's now check the status of the frontend service.

Run:

```bash
copilot svc status -n ecsdemo-frontend
```

![svc_status](/images/copilot-svc-status.png)

We can see that we have one active running task, and the details.

#### Scale our task count

One thing we haven't discussed yet is ways to manage/control our service configurations. This is where the manifest comes in.
The manifest is a declarative yaml template that defines how the service will run. The manifest was created automatically when we ran through the setup wizard (running copilot init).
This file includes details such as docker image, port, load balancer requirements, environment variables/secrets, as well as resource allocation.

Feel free to look at the manifest file here: ./copilot/ecsdemo-frontend/manifest.yml

Open the manifest file, and replace the value of the count key from 1 to 3. This is declaring our state of the service to change from 1 task, to 3.

Once you are done and save the changes, run the following:

```bash
copilot svc deploy
```

Copilot does the following with this command:

- Build your image locally
- Push to your service's ECR repository
- Convert your manifest file to CloudFormation
- Package any additional infrastructure into CloudFormation
- Deploy your updated service and resources to CloudFormation

To confirm the deploy, let's first check our service details via the copilot-cli:

```bash
copilot svc status -n ecsdemo-frontend
```

You should now see three tasks running!
Now go back to the load balancer url, and you should see the diagram alternate between the three frontend tasks.

#### Review the service logs

The services we deploy via copilot are automatically shipping logs to Cloudwatch logs by default. Rather than navigate and review logs via the console, we can use the copilot cli to see those logs locally.
Let's tail the logs for the frontend service.

```bash
copilot svc logs -a ecsworkshop -n ecsdemo-frontend --follow
```

Note that if you are in the same directory of the service you want to review logs for, simply type the below command. Of course, if yuo wanted to review logs for a service in a particular environment, you would pass the -e flag with the environment name.

```bash
copilot svc logs
```

Last thing to bring up is that you aren't limited to live tailing logs, type `copilot svc logs --help` to see the different ways to review logs from the command line.

## Create a CI/CD Pipeline