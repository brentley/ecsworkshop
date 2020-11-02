---
title: "Acceptance and Production"
disableToc: true
hidden: true
---
 
## Deploy the Crystal backend service

Navigate to the crystal service repo.

```bash
cd ~/environment/ecsdemo-crystal
```

In the previous section, we deployed our application, test environment, frontend service, and the nodejs service. 

Like we've done in previous sections, we will first need to create our crystal service in the ecsworkshop application.

The following command will open a prompt for us to add our service to the application.

```bash
copilot init
```

We will be prompted with a series of questions related to the application, environment, and the service we want to deploy. Answer the questions as follows:

- Would you like to use one of your existing applications? "Y"
- Which existing application do you want to add a new service to? Select "ecsworkshop", hit enter
- Which service type best represents yur service's architecture? Select "Backend Service", hit enter
- What do you want to name this Backend Service: ecsdemo-crystal
- Dockerfile: ./Dockerfile

After you answer the questions, it will begin the process of creating some baseline resources for your service. 
This also includes the manifest file which defines the desired state of this service. For more information on the manifest file, see the [copilot-cli documentation](https://github.com/aws/copilot-cli/wiki/Backend-Service-Manifest).

Next, you will be prompted to deploy a test environment. An environment encompasses all of the resources that are required to support running your containers in ECS.
This includes the networking stack (VPC, Subnets, Security Groups, etc), the ECS Cluster, Load Balancers (if required), and more.

Type "y", and hit enter. Given that a test environment already exists, copilot will continue on and build the docker image, push it to ECR, and deploy the backend service.

Below is an example of what the cli interaction will look like:

![deployment](/images/copilot-init-crystal.gif)

The crystal service is now deployed! Navigate back to the frontend load balancer url, and you should now see the crystal service. You may notice that it is not working as we fully expect with the diagram. 
Like we've experienced with the previous services, this is because the service needs an environment variable as well as an IAM role addon to fully function as expected. Run the commands below to add an environment variable, and create the IAM role in the addons path.

```bash
mkdir -p copilot/ecsdemo-crystal/addons
cat << EOF > copilot/ecsdemo-crystal/addons/task-role.yaml
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

cat << EOF >> copilot/ecsdemo-crystal/manifest.yml

variables:
  AWS_DEFAULT_REGION: $(echo $AWS_REGION)
EOF

git rev-parse --short=7 HEAD > code_hash.txt

```

Now, let's redeploy the service:

```bash
copilot svc deploy
```

## Interacting with the application

Let's check out the ecsworkshop application details.

```bash
copilot app show ecsworkshop
```

The result should look like this:

![app_show](/images/copilot-app-crystal.png)

We can see that our recently deployed crystal service is shown as a Backend Service in the ecsworkshop application.

## Interacting with the environment

Given that we deployed the test environment when creating our frontend service, let's show the details of the test environment:

```bash
copilot env show -n test
```

![env_show](/images/copilot-env-crystal.png)

We now can see our newly deployed service in the test environment!

## Interacting with the crystal service

Let's now check the status of the frontend service.

Run:

```bash
copilot svc status -n ecsdemo-crystal
```

![svc_status](/images/copilot-svc-status-crystal.png)

We can see that we have one active running task, along with some additional details.

#### Scale our task count

Let's scale our task count up! To do this, we are going to update the manifest file that was created when we initialized our service earlier.
Open the manifest file (./copilot/ecsdemo-crystal/manifest.yml), and replace the value of the count key from 1 to 3. This is declaring our state of the service to change from 1 task, to 3.
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
copilot svc status -n ecsdemo-crystal
```

You should now see three tasks running!

Now go back to the load balancer url, and you should see the diagram alternate between the three frontend tasks.

#### Review the service logs

The services we deploy via copilot are automatically shipping logs to Cloudwatch logs by default. Rather than navigate and review logs via the console, we can use the copilot cli to see those logs locally.
Let's tail the logs for the crystal service.

```bash
copilot svc logs -a ecsworkshop -n ecsdemo-crystal --follow
```

Note that if you are in the same directory of the service you want to review logs for, simply type the below command. Of course, if yuo wanted to review logs for a service in a particular environment, you would pass the -e flag with the environment name.

```bash
copilot svc logs
```
Last thing to bring up is that you aren't limited to live tailing logs, type `copilot svc logs --help` to see the different ways to review logs from the command line.

## Next steps

We did it! We have successfully deployed a three tier, polyglot, microservice application to ECS! 