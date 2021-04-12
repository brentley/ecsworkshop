---
title: "None mode"
chapter: false
weight: 60
---

If you want to completely disable the networking stack on a container, you can use `none` as network mode when starting the container or in ECS Task Definition. Within the container, only the loopback device is created. 

In the task definition set the "networkMode" to "none".  Port mappings are not valid with this network mode.

```
{
  ...
  "containerDefinitions": [
    ...
  ],
  ...
  "networkMode": "none",
  ...
}

```

## Lab exercise

One cannot leverage the new "ECS exec" feature to access the container in "none" networking mode!

Note: The executables you want to run in the interactive shell session must be available in the container image!

```
source ~/.bashrc
cd ~/environment/ecsworkshop/content/ecs_networking/setup
TASK_FILE=ecs-networking-demo-none-mode.json
envsubst < ${TASK_FILE}.template > ${TASK_FILE}
TASF_DEF=$(aws ecs register-task-definition --cli-input-json file://${TASK_FILE} --query 'taskDefinition.taskDefinitionArn' --output text)
TASK_ARN=$(aws ecs run-task --cluster ${ClusterName} --task-definition ${TASK_DEF} --enable-execute-command --launch-type EC2 --query 'tasks[0].taskArn' --output text)
aws ecs describe-tasks --cluster ${ClusterName} --task ${TASK_ARN}
# sleep to let the container start
sleep 60
```

Access the ECS EC2 instance running your task as a priviledged Linux user to observe some details:

```
CONT_INST_ID=$(aws ecs list-container-instances --cluster ${ClusterName} --query 'containerInstanceArns[]' --output text)
EC2_INST_ID=$(aws ecs describe-container-instances --cluster ${ClusterName} --container-instances ${CONT_INST_ID} --query 'containerInstances[0].ec2InstanceId' --output text)
aws ssm start-session --target ${EC2_INST_ID}
```

and to run the following commands inside the instance:

```
sudo -i
docker ps
CONT_ID=$(docker ps --format "{{.ID}} {{.Image}}" | grep busybox | awk '{print $1}') 
PID=$(docker inspect -f '{{.State.Pid}}' $CONT_ID)
nsenter -t $PID -n ip a show
docker inspect -f '{{json .NetworkSettings}}' $CONT_ID
# to leave the interactive session type exit twice
```

Sample output.
```
TBD
```

