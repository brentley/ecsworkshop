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
This includes the manifest file for the frontend service, which defines the desired state of your service deployment. For more information on the Load Balanced Web Service manifest, see the [copilot documentation](https://github.com/aws/copilot-cli/wiki/Load-Balanced-Web-Service-Manifest).

Next, you will be prompted to deploy a test environment. An environment encompasses all of the resources that are required to support running your containers in ECS.
This includes the networking stack (VPC, Subnets, Security Groups, etc), the ECS Cluster, Load Balancers (if required), service discovery namespace (via CloudMap), and more.

Type "y", and hit enter. This part will take a few minutes because of all of the resources that are being created. This is not an action you run every time you deploy your service, it's just the one time to get your environment up and running.

Below is an example of what the cli interaction will look like:

![deployment](/images/copilot-frontend.gif)

Ok, that's it! With one command and answering a few questions, we have our frontend service deployed to an environment!

Grab the load balancer url and paste it into your browser. 

```bash
copilot svc show -n ecsdemo-frontend --json | jq -r .routes[].url
```

You should see the frontend service up and running.
The app may look strange or like it’s not working properly. This is because our service relies on the ability to talk to AWS services that it presently doesn’t have access to. 
The app should be showing an architectural diagram with the details of what Availability Zones the services are running in. We will address this fix later in the chapter. 
Now that we have the frontend service deployed, how do we interact with our environment and service? Let's dive in and answer those questions.

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

Reviewing the output, we see the environments and services deployed under the application.
In a real world scenario, we would want to deploy a production environment that is completely isolated from test. Ideally that would be in another account as well.
With this view, we see what accounts and regions our application is deployed to.

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

With this view, we're able to see all of the services deployed to our application's test environment. As we add more services, we will see this grow.
A couple of neat things to point out here: 

- The tags associated with our environment. The default tags have the application name as well as the environment.
- The details about the environment such as account id, region, and if the environment is considered production.

## Interacting with the frontend service

![env_show](/images/copilot-svc.png)

There is a lot of power with the `copilot svc` command. As you can see from the above image, there is quite a bit that we can do when interacting with our service.

Let's look at a couple of the commands:

- package: The copilot-cli uses CloudFormation to manage the state of the environment and services. If you want to get the CloudFormation template for the service deployment, you can simply run `copilot svc package`. This can be especially helpful if you decide to move to CloudFormation to manage your deployments on your own.
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

One thing we haven’t discussed yet is ways to manage/control our service configuration. 
This is done via the manifest file.
The manifest is a declarative yaml template that defines the desired state of our service. 
It was created automatically when we ran through the setup wizard (running copilot init), and includes details such as docker image, port, load balancer requirements, environment variables/secrets, as well as resource allocation. 
It dynamically populates this file based off of the Dockerfile as well as opinionated, sane defaults.

Open the manifest file (./copilot/ecsdemo-frontend/manifest.yml), and replace the value of the count key from 1 to 3. This is declaring our state of the service to change from 1 task, to 3.
Feel free to explore the manifest file to familiarize yourself.

```
# Number of tasks that should be running in your service.
count: 3
```

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
Now go back to the load balancer url, and you should see the service showing different IP addresses based on which frontend service responds to the request.
Note, it's still not showing the full diagram, we're going to fix this shortly.

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

{{%expand "Expand here to deploy a pipeline" %}}

In this section, we'll go from a local development workflow, to a fully automated CI/CD pipeline and git workflow. 
We will be using GitHub to host our git repository, and the copilot cli to do the rest.

#### Prepare and setup the repository in GitHub

First thing we will do is create a git repository. There are some prerequisites that need to be met prior to moving forward.

1) You need a GitHub account.

2) You need to create a personal access token in GitHub. For further assistance, please go here: https://git.io/JfDFD. When you are selecting the scope, check "repo".

![repo_scope](/images/copilot-scope-repo.png)

Once you have steps one and two completed, we can move forward. Please copy the personal access token, and store it somewhere safe. You will be referencing it a few times throughout the workshop.

Navigate to the frontend service repo [here](https://github.com/brentley/ecsdemo-frontend). 

We will create a fork of this repository. Click the "Fork" button in the top right, and then select your GitHub username. This will create a copy of the repository under your GitHub namespace.

![fork_1](/images/copilot-fork-click-frontend.png)
![fork_2](/images/copilot-fork-frontend.png)

Next, click "Code" in the upper left, and copy the HTTPS uri for the repository.

![clone](/images/frontend-git-clone.png)

Add the remote:

```bash
git remote add upstream https://github.com/YOURGITHUBUSERNAME/ecsdemo-frontend.git
```

Now that we have a git repository, we can setup a git workflow that will trigger a pipeline on push.

#### Creating the pipeline

Generally, when we create CI/CD pipelines, there is quite a bit of work that goes into it. Copilot does all of the heavy lifting, leaving you to just answer a couple of questions in the cli, and that's it. Let's see it in action!

Run the following:

```bash
copilot pipeline init
```

Once again, you will be prompted with a series of questions. Answer the questions with the following answers:

- Would you like to add an environment to your pipeline? Answer: "y"
- Which environment would you like to add to your pipeline? Answer: Choose "test"
- Which GitHub repository would you like to use for your service? Answer: Choose the repo url with YOUR github username
- Please enter your GitHub Personal Access Token for your repository ecsdemo-frontend. Answer: Paste the copied token that you created in GitHub earlier.

The core pipeline files will be created in the ./copilot directory. Here is what the output should show:

![init](/images/copilot-pipeline-init.png)

Commit and push the new files to your repo. To get more information about the files that were created, check out the [copilot-cli documentation](https://github.com/aws/copilot-cli/wiki/Pipelines#setting-up-a-pipeline-step-by-step).
In short, we are pushing the deployment manifest (for copilot to use as reference to deploy the service), pipeline.yml (which defines the stages in the pipeline), and the buildspec.yml (contains the build instructions for the service).

```bash
git add copilot
git commit -m "Adding copilot pipeline configuration"
git push upstream HEAD
```

You will be prompted to login. The username is your github username, and the password will be the personal access token we created earlier.

Now that our repo has the pipeline configuration, let's build/deploy the pipeline:

```bash
copilot pipeline update
```

![output](/images/copilot-pipeline-output.png)

Our pipeline is now deployed (yes, it's that simple). Let’s interact with it!

Now there are two ways that I can review the status of the pipeline. 

1) Console: Navigate here: https://${YOUR_REGION}.console.aws.amazon.com/codesuite/codepipeline/pipelines, click your pipeline, and you can see the stages.

2) Command line: `copilot pipeline status`. 

![status](/images/copilot-pipeline-status.png)

Whether you’re in the console or checking from the cli, you will see the pipeline is actively running. You can watch as the pipeline executes, and when it is complete, all updates in the Status column will show "Succeeded".

#### Fix the frontend service

We mentioned earlier that the frontend service wasn’t fully functional. The reason for this is that the service interacts with the AWS API’s to determine what availability zone it resides in. To fix this, we need to create an IAM policy that we can attach to our service to enable the proper access.

Copilot enables you to add additional AWS resources via CloudFormation with "addons". To get more information on this, see the [copilot-cli documentation](https://github.com/aws/copilot-cli/wiki/Additional-AWS-Resources#how-to-do-i-add-other-resources)
In this example, the addon for our service will be an IAM policy to allow the access needed, which copilot will automatically recognize and add to the task role for the service.

The following commands are going to create an addons directory for the ecsdemo-frontend service, and the CloudFormation yaml which grants the proper access.
On the next deployment, copilot-cli will recognize the new CloudFormation in the addons directory, and use that to attach the IAM Policy to the task role for the service.

```bash
mkdir -p copilot/ecsdemo-frontend/addons
cat << EOF > copilot/ecsdemo-frontend/addons/task-role.yaml
# You can use any of these parameters to create conditions or mappings in your template.
Parameters:
  App:
    Type: String
    Description: Your application's name.
  Env:
    Type: String
    Description: The environment name your service, job, or workflow is being deployed to.
  Name:
    Type: String
    Description: The name of the service, job, or workflow being deployed.

Resources:
  SubnetsAccessPolicy:
    Type: AWS::IAM::ManagedPolicy
    Properties:
      PolicyDocument:
        Version: 2012-10-17
        Statement:
          - Sid: EC2Actions
            Effect: Allow
            Action:
              - ec2:DescribeSubnets
            Resource: "*"

Outputs:
  # You also need to output the IAM ManagedPolicy so that Copilot can inject it to your ECS task role.
  SubnetsAccessPolicyArn:
    Description: "The ARN of the Policy to attach to the task role."
    Value: !Ref SubnetsAccessPolicy
EOF
cat << EOF >> copilot/ecsdemo-frontend/manifest.yml
variables:
  AWS_DEFAULT_REGION: $(echo $AWS_REGION)
  CRYSTAL_URL: "http://ecsdemo-crystal.ecsworkshop.local:3000/crystal"
  NODEJS_URL: "http://ecsdemo-nodejs.ecsworkshop.local:3000"
EOF

git rev-parse --short=7 HEAD > code_hash.txt

```

Push the new file to the git repo, and let's watch the pipeline build/deploy the changes:

```bash
git add copilot/ecsdemo-frontend/addons
git add code_hash.txt
git commit -m "Adding an IAM policy addon"
git push upstream HEAD
```

You will be prompted to login. The username is your github username, and the password will be the personal access token we created earlier.

Once again, there are two ways that I can review the status of the pipeline. 

1) Console: https://${AWS_REGION}.console.aws.amazon.com/codesuite/codepipeline/pipelines, click your pipeline, and you can see the stages.

2) Command line: `copilot pipeline status`.

When the pipeline is complete, navigate to the load balancer url. You should now see the application working as expected.

{{% /expand %}}

{{%expand "Expand here if you don't want to create the pipeline, but still want to fix the frontend service" %}}

#### Fix the frontend service

We mentioned earlier that the frontend service wasn't fully functional. The reason for this is that the service uses the aws cli to determine what subnet its in and then uses that to determine availability zone.
To fix this, we need to create an IAM policy that we can attach to our service to enable the proper access.

Copilot enables you to add additional AWS resources via CloudFormation with "addons". To get more information on this, see the [copilot-cli documentation](https://github.com/aws/copilot-cli/wiki/Additional-AWS-Resources#how-to-do-i-add-other-resources)
In this example, the addon for our service will be an IAM policy to allow the access needed, which will in turn be attached to the task role.

The following commands are going to create an addons directory for the ecsdemo-frontend service, and the CloudFormation yaml which grants the proper access.
On the next deployment, copilot-cli will recognize the new CloudFormation in the addons directory, and use that to attach the IAM Policy to the task role for the service.

```bash
mkdir -p copilot/ecsdemo-frontend/addons
cat << EOF > copilot/ecsdemo-frontend/addons/TESTtask-role.yaml
# You can use any of these parameters to create conditions or mappings in your template.
Parameters:
  App:
    Type: String
    Description: Your application's name.
  Env:
    Type: String
    Description: The environment name your service, job, or workflow is being deployed to.
  Name:
    Type: String
    Description: The name of the service, job, or workflow being deployed.

Resources:
  SubnetsAccessPolicy:
    Type: AWS::IAM::ManagedPolicy
    Properties:
      PolicyDocument:
        Version: 2012-10-17
        Statement:
          - Sid: EC2Actions
            Effect: Allow
            Action:
              - ec2:DescribeSubnets
            Resource: "*"

Outputs:
  # You also need to output the IAM ManagedPolicy so that Copilot can inject it to your ECS task role.
  SubnetsAccessPolicyArn:
    Description: "The ARN of the Policy to attach to the task role."
    Value: !Ref SubnetsAccessPolicy
EOF
cat << EOF >> copilot/ecsdemo-frontend/manifest.yml
variables:
  REGION: $(echo $AWS_REGION)
  CRYSTAL_URL: "http://ecsdemo-crystal.ecsworkshop.local:3000/crystal"
  NODEJS_URL: "http://ecsdemo-nodejs.ecsworkshop.local:3000"
EOF

git rev-parse --short=7 HEAD > code_hash.txt

```

Now that we've updated the manifest with the required environment variables as well as IAM role in the addons directory, let's deploy the service:

```bash
copilot svc deploy
```

{{% /expand %}}

## Next steps

We have officially completed deploying our frontend. In the next section, we will extend our application by adding two backend services.
