---
title: "Crystal Backend API"
hidden: false
weight: 4
---

#### Generate local docker compose file

```
cd ~/environment/ecsdemo-crystal/
```

- Using the ecs cli, we can grab the task definition for our frontend service that is running in AWS. We accomplish this by passing in the --task-def-remote parameter the the ecs-cli local command. This will take the ecs task definition and convert it to a docker compose file.

```
ecs-cli local create --task-def-remote $(aws ecs list-task-definitions | jq -r '.taskDefinitionArns[] | select(contains ("crystal"))')
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
curl localhost:3000/health
```

#### View in the UI

- Navigate over to the tab with the frontend UI, and you should now see the Crystal service running!

- That's it! We are locally running in docker our polyglot microservice environment. All services communicating with one another, and perfect for testing locally without having to deploy everything to AWS.
