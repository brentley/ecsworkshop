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
ecs-cli local create --task-def-remote $(aws ecs list-task-definitions | jq -r '.taskDefinitionArns[] | select(contains ("ecsdemo-frontend"))')
```

- Take a look at the docker compose file that was generated, a couple of items to note:

    - Note here
    - Note here

```
cat docker-compose.ecs-local.yml
```

#### Modify ports

- Because we run every service on the same port, we need to modify them to avoid collision locally.

```
sed -i 's/published: 3000/published: 8080/g' docker-compose.ecs-local.yml
sed -i 's/ecsdemo-nodejs.service:3000/ecsdemo-nodejs.service:4000/g' docker-compose.ecs-local.yml
```

#### Run the service locally

```
ecs-cli local up
```

#### Confirm container is running locally

```
ecs-cli local ps --all
```

#### You should see your container running on the expected port. Now go ahead and give it a curl!

```
curl localhost:8080/health
```

#### View it in the UI

- Using Cloud9, select `Preview` --> `Preview Running Application` at the top

- A new tab will open, prepend `:8080` to the url in the Cloud9 browser and hit enter.

- Finally, select the box next to browser that will open the url in another tab in your browser. It looks like this:

![c9-browser](/images/c9-local-2.png)

- You should see the frontend service UI with one service running in one availability zone.

#### Frontend local testing complete

- That's it! Time to move on to deploying the other microservices locally to get a full end to end test.
