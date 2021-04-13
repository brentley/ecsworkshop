---
title: "AWSVPC mode"
chapter: false
weight: 20
---

Tasks running on Amazon EC2 Container Service (Amazon ECS) can take advantage of awsvpc mode for container networking.
This mode allocates an [elastic networking interface](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html) to each running task, providing a dynamic private IP address and internal DNS name.
This simplifies container networking management and operations, allowing tasks to run with full networking features on AWS.

Amazon ECS recommends using the awsvpc network mode unless you have a specific need to use a different network mode. 

Below is a diagram of the AWSVPC mode for EC2 launch type:

![AWSVPC mode](/images/ECS_awsvpc_mode.png)

In the **task definition** enter the following parameter for [network mode](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#network_mode)

```
{
  ...
  "containerDefinitions": [
  ...
  ],
  ...
  "networkMode": "awsvpc",
  ...
}

```

To **run a task** in AWSVPC networking mode provide a network configuration structure as follows:

```
{
  "awsvpcConfiguration": {
    "subnets": ["string", ...],
    "securityGroups": ["string", ...],
    "assignPublicIp": "ENABLED"|"DISABLED"
  }
}
```

## Advantages

- Addressable by IP addresses and the DNS name of the elastic network interface
- Attachable as ‘IP’ targets to Application Load Balancers and Network Load Balancers
- Observable from VPC flow logs
- Integration into CloudWatch logging and Container Insights
- Access controlled by security groups
- Enables running multiple copies of the same task definition on the same instance, without needing to worry about port conflicts
- Higher performance because there is no need to perform any port translations or contend for bandwidth on the shared docker0 bridge, as you do with the bridge networking mode

## Considerations

- bin packing of tasks using EC2 launch type

There is a default limit to the number of network interfaces that can be attached to an Amazon EC2 instance. 
Amazon ECS supports launching container instances with increased ENI density using supported Amazon EC2 instance types.
When you use these instance types and opt in to the 'awsvpcTrunking' account setting, additional ENIs are available on newly launched container instances.
For details see [here](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container-instance-eni.html)

For comprehensive considerations see [here](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-networking.html#task-networking-awsvpc).

## Lab exercise

One can leverage the new "ECS exec" feature to access containers and check the network configuration. For details including prerequisites for using this feature see [blog post](https://aws.amazon.com/blogs/containers/new-using-amazon-ecs-exec-access-your-containers-fargate-ec2/)

Note: The executables you want to run in the interactive shell session must be available in the container image!

```
source ~/.bashrc
cd ~/environment/ecsworkshop/content/ecs_networking/setup
export TASK_FILE=ecs-networking-demo-awsvpc-mode.json
envsubst < ${TASK_FILE}.template > ${TASK_FILE}
export TASK_DEF=$(aws ecs register-task-definition --cli-input-json file://${TASK_FILE} --query 'taskDefinition.taskDefinitionArn' --output text)
export TASK_ARN=$(aws ecs run-task --cluster ${ClusterName} --task-definition ${TASK_DEF} \
  --network-configuration "awsvpcConfiguration={subnets=[${PrivateSubnetOne},${PrivateSubnetTwo}],securityGroups=[${ContainerSecurityGroup}],assignPublicIp=DISABLED}"  \
   --enable-execute-command --launch-type EC2 --query 'tasks[0].taskArn' --output text)
aws ecs describe-tasks --cluster ${ClusterName} --task ${TASK_ARN}
# sleep to let the container start
sleep 30
aws ecs execute-command --cluster ${ClusterName} --task ${TASK_ARN} --container nginx --command "/bin/sh" --interactive
```

Sample outputs for awsvpc network mode of a task running a nginx:alpine container which contains the required net-tools package required for running "ip" commands using ECS exec:

```
$ aws ecs execute-command --cluster staging --task 374eb66626904a238001bc6301e3cbea --container nginx --command "/bin/sh" --interactive

The Session Manager plugin was installed successfully. Use the AWS CLI to start a session.

Starting session with SessionId: ecs-execute-command-09a0ac6bc7bdf6020
/ # ip a sh
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
...
4: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc mq state UP qlen 1000
    link/ether 06:d0:20:80:ed:6a brd ff:ff:ff:ff:ff:ff
    inet 10.0.1.121/24 scope global eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::4d0:20ff:fe80:ed6a/64 scope link
       valid_lft forever preferred_lft forever

/ # ip l sh
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
...
4: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc mq state UP qlen 1000
    link/ether 06:d0:20:80:ed:6a brd ff:ff:ff:ff:ff:ff

/ # ip r sh
default via 10.0.1.1 dev eth1
10.0.1.0/24 dev eth1 scope link  src 10.0.1.121
...

/ # curl localhost
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
…

```

Another approach is to access the ECS EC2 instance running your task as a priviledged Linux user to observe some details:

```
CONT_INST_ID=$(aws ecs list-container-instances --cluster ${ClusterName} --query 'containerInstanceArns[]' --output text)
EC2_INST_ID=$(aws ecs describe-container-instances --cluster ${ClusterName} --container-instances ${CONT_INST_ID} --query 'containerInstances[0].ec2InstanceId' --output text)
aws ssm start-session --target ${EC2_INST_ID}
```

and to run the following commands inside the instance:

```
sudo -i
docker ps
CONT_ID=$(docker ps --format "{{.ID}} {{.Image}}" | grep nginx:alpine | awk '{print $1}') 
PID=$(docker inspect -f '{{.State.Pid}}' $CONT_ID)
ip a sh eth0
nsenter -t $PID -n ip a show
CONT_IP=$(nsenter -t $PID -n ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
curl ${CONT_IP}:80
# to leave the interactive session type exit twice
```

Sample outputs for awsvpc network mode of a task running a nginx container. Note that eth0 of the EC2 instance and eth0 of the container belong to the same VPC/network CIDR:

```
[root@ip-xxx ~]# docker ps
CONTAINER ID        IMAGE                            COMMAND                  CREATED             STATUS                PORTS               NAMES
8dce1c4c8611        nginx                            "/docker-entrypoint.…"   7 days ago          Up 7 days                                 ecs-web-1-web-e0ddf8998e99d4dc0300

[root@ip-xxx ~]# PID=$(docker inspect -f '{{.State.Pid}}' 8dce1c4c8611)

[root@ip-10-0-100-21 ~]# ip a sh eth0
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc mq state UP group default qlen 1000
    link/ether 02:3c:af:b8:6d:52 brd ff:ff:ff:ff:ff:ff
    inet 10.0.100.21/24 brd 10.0.100.255 scope global dynamic eth0
       valid_lft 2333sec preferred_lft 2333sec
    inet6 fe80::3c:afff:feb8:6d52/64 scope link
       valid_lft forever preferred_lft forever
       
[root@ip-xxx ~]# nsenter -t $PID -n ip a show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
3: ecs-eth0@if6: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 0a:58:a9:fe:ac:02 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 169.254.172.2/22 scope global ecs-eth0
       valid_lft forever preferred_lft forever
4: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 02:15:66:37:08:ee brd ff:ff:ff:ff:ff:ff
    inet 10.0.100.154/24 scope global eth0
       valid_lft forever preferred_lft forever
       

[root@ip-xxx ~]# curl 10.0.100.154:80
<!DOCTYPE html>
<html>
...
<h1>Welcome to nginx!</h1>
...
</html>
```

Cleanup the task:

```
aws ecs stop-task --cluster ${ClusterName} --task ${TASK_ARN}
```