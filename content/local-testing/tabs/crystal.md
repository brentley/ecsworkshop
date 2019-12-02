---
title: "Crystal Backend"
disableToc: true
hidden: true
---

## Generate local docker compose file

```
cd ~/environment/ecsdemo-crystal/
ecs-cli local create --task-def-remote $(aws ecs list-task-definitions | jq -r '.taskDefinitionArns[] | select(contains ("ecsdemo-crystal"))')
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

