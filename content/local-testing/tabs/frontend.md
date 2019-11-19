---
title: "Frontend"
disableToc: true
hidden: true
---

## Generate local docker compose file

```
ecs-cli local create --task-def-remote $(aws ecs list-task-definitions | jq -r '.taskDefinitionArns[] | select(contains ("ecsdemo-frontend"))')
```

## Modify the port in the generated file to avoid collision when testing with backend services running

```
sed -i 's/published: 3000/published: 8080/g' docker-compose.ecs-local.yml
sed -i 's/ecsdemo-nodejs.service:3000/ecsdemo-nodejs.service:4000/g' docker-compose.ecs-local.yml
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
curl localhost:8080/health
```

