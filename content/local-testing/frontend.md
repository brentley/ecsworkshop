---
title: "Frontend Rails App"
hidden: false
weight: 2
---

#### Generate local docker compose file

```
cd ~/environment/ecsdemo-frontend/
```
- Using the ecs cli, we can grab the task definition for our frontend service that is running in AWS. We accomplish this by passing in the --task-def-remote parameter the the ecs-cli local command. This will take the ecs task definition and convert it to a docker compose file.

```
ecs-cli local create --task-def-remote $(aws ecs list-task-definitions | jq -r '.taskDefinitionArns[] | select(contains ("frontend"))')
```

- Take a look at the docker compose file that was generated. The file dictates how the container is to run on the local machine. One item to note is regarding the local bridge network.

```
cat docker-compose.ecs-local.yml
```

- Under networks, a bridge network has been created called ecs-local-network. This simulates some of the endpoints available to the task at runtime such as [IAM Roles endpoint](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html) and [Task Metadata endpoints](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-metadata-endpoint.html), as well as service discovery between the containers.


#### Modify ports 

- Because cloud9 can only preview on port 8080, and we run every service on the same port, we need to modify the port assignments to avoid a port collision while running locally.

```
sed -i 's/published: 3000/published: 8080/g' docker-compose.ecs-local.yml
```

- We also use a different service discovery name convention when running locally, so we will modify the environment
values used to reach the backend services.

```

 # this command downloads the existing task definition and extracts the containerdefinition name to be used for service discovery

nodeservicename=$(aws ecs describe-task-definition --task-definition $(aws ecs list-task-definitions | jq -r '.taskDefinitionArns[] | select(contains ("nodejs"))') | jq -r .taskDefinition.containerDefinitions[0].name)
crystalservicename=$(aws ecs describe-task-definition --task-definition $(aws ecs list-task-definitions | jq -r '.taskDefinitionArns[] | select(contains ("crystal"))') | jq -r .taskDefinition.containerDefinitions[0].name)

 # now that we know our service discovery names, we can substitute them into the docker-compose file
 
sed -i "s/ecsdemo-nodejs.service:3000/${nodeservicename}:3000/g" docker-compose.ecs-local.yml
sed -i "s/ecsdemo-crystal.service:3000/${crystalservicename}:3000/g" docker-compose.ecs-local.yml

```

#### Run the service

```
ecs-cli local up
```

#### Confirm container is running

```
ecs-cli local ps --all
```

#### You should see your container running on the expected port. Now go ahead and give it a curl!

```
curl localhost:8080/health
```

#### View it in the UI

- Using Cloud9, select `Preview` --> `Preview Running Application` at the top

- A new tab will open, remove the '/' at the end and append `:8080` to the url in the Cloud9 browser and hit enter.

- Finally, select the box next in the Cloud9 browser that will open the url in another tab in your local browser. It looks like this:

![c9-browser](/images/c9-local-2.png)

- You should see the frontend service UI with one service running in one availability zone.

#### Frontend local testing complete

- That's it! Time to move on to deploying the other microservices locally to get a full end to end test.
