---
title: "Crystal Backend API"
hidden: false
weight: 4
---

## Generate local docker compose file

```
cd ~/environment/ecsdemo-crystal/
```
```
ecs-cli local create --task-def-remote $(aws ecs list-task-definitions | jq -r '.taskDefinitionArns[] | select(contains ("ecsdemo-crystal"))')
```

## To follow our service discovery namespace for consistency, let's change the name of the service to use the .
service domain as we do in ecs itself

```
sed -i 's/ecsdemo-crystal:/ecsdemo-crystal.service:/g' docker-compose.ecs-local.*
```

## Run the service locally

```
ecs-cli local up
```

## Confirm container is running locally

```
ecs-cli local ps --all
```

## You should see your container running on the expected port. Now go ahead and give it a curl!

```
curl localhost:3000/health
```

