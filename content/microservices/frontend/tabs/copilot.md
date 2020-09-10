---
title: "Acceptance and Production"
disableToc: true
hidden: true
---
 
## Configure our application

Navigate to the frontend service repo.

```bash
cd ~/environment/ecsdemo-frontend
```

To start, we first need to initialize our application. 
In the context of copilot-cli, the application is a group of related services, environments, and pipelines. 

```bash
copilot init
```

We will be prompted with a series of questions related to the application, and then our service. Answer the questions as follows:

- Application name: ecsworkshop
- Service Type: Load Balanced Web Service
- Dockerfile: ./Dockerfile


After you answer the questions, it will begin the process of creating some baseline resources for your Application.

Below is an example of what the input will look like:


![feoutput](/images/copilot-init.png)

##### add a section on adding a ci/cd pipeline. modify the part of the code where we reference the git hash. start with no hash, then create pipeline, update hash, and commit the code. this will require us creating a codecommit repo to use as our example.

