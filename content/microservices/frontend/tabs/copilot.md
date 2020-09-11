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
This will come in handy when you are working with multiple applications using copilot.

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