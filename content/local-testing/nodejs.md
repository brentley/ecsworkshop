---
title: "Node.js Backend API"
hidden: false
weight: 3
---

#### Generate local docker compose file

```
cd ~/environment/ecsdemo-nodejs/
```

- Using the ecs cli, we can grab the task definition for our frontend service that is running in AWS. We accomplish this by passing in the --task-def-remote parameter the the ecs-cli local command. This will take the ecs task definition and convert it to a docker compose file.

```
ecs-cli local create --task-def-remote $(aws ecs list-task-definitions | jq -r '.taskDefinitionArns[] | select(contains ("nodejs"))')
```

#### Modify ports

- As mentioned previously, all the services run on the same port. We're simply going to change the port this service runs on to avoid collision.

```
sed -i 's/published: 3000/published: 4000/g' docker-compose.ecs-local.yml
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
curl localhost:4000
curl localhost:4000/health
```

#### View in the UI

- Navigate over to the tab with the frontend UI, and you should now see the Node.js service running!

- Let's move on to the next service!
