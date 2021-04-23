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
export TASK_FILE=ecs-networking-demo-none-mode.json
envsubst < ${TASK_FILE}.template > ${TASK_FILE}
export TASK_DEF=$(aws ecs register-task-definition --cli-input-json file://${TASK_FILE} --query 'taskDefinition.taskDefinitionArn' --output text)
export TASK_ARN=$(aws ecs run-task --cluster ${ClusterName} --task-definition ${TASK_DEF} --enable-execute-command --launch-type EC2 --query 'tasks[0].taskArn' --output text)
aws ecs describe-tasks --cluster ${ClusterName} --task ${TASK_ARN}
# sleep to let the container start
sleep 30
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
docker inspect -f '{{json .NetworkSettings.Networks}}' $CONT_ID
# to leave the interactive session type exit twice
```

Sample output shows that only a loopback interface is available and no "IPAddress" assigned.
```
sh-4.2$ sudo -i
[root@ip-xxx ~]# docker ps
CONTAINER ID        IMAGE                            COMMAND                CREATED             STATUS                   PORTS               NAMES
be33000990a4        busybox                          "sh -c 'sleep 3600'"   45 seconds ago      Up 43 seconds                                ecs-ecs-networking-demo-none-8-sleep-80fa8a9ba3c89df3ad01
a6dfe40493ce        amazon/amazon-ecs-agent:latest   "/agent"               9 minutes ago       Up 9 minutes (healthy)                       ecs-agent

[root@ip-xxx ~]# CONT_ID=$(docker ps --format "{{.ID}} {{.Image}}" | grep busybox | awk '{print $1}') 

[root@ip-xxx ~]# PID=$(docker inspect -f '{{.State.Pid}}' $CONT_ID)

[root@ip-xxx ~]# nsenter -t $PID -n ip a show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever

[root@ip-xxx ~]# docker inspect -f '{{json .NetworkSettings.Networks}}' $CONT_ID                                                                                                                                                                                     
{"none":{"IPAMConfig":null,"Links":null,"Aliases":null,"NetworkID":"c2512c49db341053a472cde122e2e0f49f46f03c2bf512398d6f5b09e2ede8c9","EndpointID":"9ac96de075669772d23bf13c32c5878606b038e248c55f346e95b5b96e15cd28","Gateway":"","IPAddress":"","IPPrefixLen":0,"IPv6Gateway":"","GlobalIPv6Address":"","GlobalIPv6PrefixLen":0,"MacAddress":"","DriverOpts":null}}
```

Cleanup the task:

```
aws ecs stop-task --cluster ${ClusterName} --task ${TASK_ARN}
```