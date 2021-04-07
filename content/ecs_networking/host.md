---
title: "Host mode"
chapter: false
weight: 40
---

If you use the host network mode for a ECS task on EC2 launch type, the network stack of the task is not isolated from the underlying EC2 host.
The  containers do not get its own IP-addresses allocated.

Host mode networking can be useful to optimize performance, and in situations where a container needs to handle a large range of ports, as it does not require network address translation (NAT), and no “userland-proxy” is created for each port.

For example, if you run a container which binds to port 3000 and you use host networking, the container’s application is available on port 3000 on the host’s primary IP address

Below is a diagram of the host mode for EC2 launch type:

![Host mode](/images/ECS_host_mode.png)

In the **task definition** enter the following parameter for [network mode](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#network_mode)

```
{
  ...
  "containerDefinitions": [
  ...
  "portMappings": [
    {
        "containerPort": "3000",
        "protocol": "tcp"
    }
  ],
  ...
  "networkMode": "host",
  ...
}

```

## Considerations

Very simple approach  but with significant disadvantages:

- Not possible to run more than a single instantiation of a particular task per host, as only the first task will be able to bind to its required port on the EC2 instance.
- No way to remap a container port when using host networking mode, any port collisions or conflicts must be managed by changing the configuration of the application inside the container.

## Lab exercise

One can leverage the new "ECS exec" feature to access containers and check the network configuration.

Note: The executables you want to run in the interactive shell session must be available in the container image!

```
source ~/.bashrc
cd ~/environment/ecsworkshop/content/ecs_networking/setup
TASK_FILE=ecs-networking-demo-host-mode.json
envsubst < ${TASK_FILE}.template > ${TASK_FILE}
TASK_ARN=$(aws ecs run-task --cluster ${ClusterName} --task-definition ${TASK_FILE} --enable-execute-command --launch-type EC2 --query 'tasks[0].taskArn' --output text)
aws ecs describe-tasks --cluster ${ClusterName} --task ${TASK_ARN}
# sleep to let the container start
sleep 60
aws ecs execute-command --cluster ${ClusterName} --task ${TASK_ARN} --container nginx --command "/bin/sh" --interactive
```

Inside the container run the following commands:

```
ip a sh
ip link sh
ip r sh
curl localhost:80
# to leave the interactive session type exit
```

Sample outputs for host network mode of a task running a nginx:alpine container using ECS exec.

Note that all EC2 host interfaces and routes are visible within the container because it shares the network namespace of the underlying ECS Ec2 host!

```
$ aws ecs execute-command--cluster staging --task a1e924295a744c878f237133f58803ed --container nginx --command "/bin/sh" --interactive

The Session Manager plugin was installed successfully. Use the AWS CLI to start a session.


Starting session with SessionId: ecs-execute-command-00f95f492d720713f
/ # ip a sh
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc mq state UP qlen 1000
    link/ether 02:2e:5d:33:eb:ce brd ff:ff:ff:ff:ff:ff
    inet 10.0.100.120/24 brd 10.0.100.255 scope global dynamic eth0
       valid_lft 3046sec preferred_lft 3046sec
    inet6 fe80::2e:5dff:fe33:ebce/64 scope link
       valid_lft forever preferred_lft forever
3: docker0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP
    link/ether 02:42:ad:eb:00:35 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:adff:feeb:35/64 scope link
       valid_lft forever preferred_lft forever
5: veth92275a3@if4: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue master docker0 state UP
    link/ether 82:a4:97:04:7d:a5 brd ff:ff:ff:ff:ff:ff
    inet6 fe80::80a4:97ff:fe04:7da5/64 scope link
       valid_lft forever preferred_lft forever
...
/ # ip link sh
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc mq state UP qlen 1000
    link/ether 02:2e:5d:33:eb:ce brd ff:ff:ff:ff:ff:ff
3: docker0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP
    link/ether 02:42:ad:eb:00:35 brd ff:ff:ff:ff:ff:ff
5: veth92275a3@if4: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue master docker0 state UP
    link/ether 82:a4:97:04:7d:a5 brd ff:ff:ff:ff:ff:ff
...
/ # ip r sh
default via 10.0.100.1 dev eth0
10.0.100.0/24 dev eth0 scope link  src 10.0.100.120
169.254.169.254 dev eth0
172.17.0.0/16 dev docker0 scope link  src 172.17.0.1
/ # curl 10.0.100.120:80
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
docker ps
docker inspect <containerId>
netstat -tulpn
curl localhost:80
# to leave the interactive session type exit
```

Sample outputs for host network mode of a task running a nginx container:

```
[root@ip-xxx ~]# docker ps
CONTAINER ID        IMAGE       COMMAND                  CREATED             STATUS         PORTS       NAMES
1a6f88d328c2        nginx       "/docker-entrypoint.…"   28 seconds ago      Up 26 seconds              ecs-web-host-2-web-host-faac92eda1bdc9f01c00

[root@ip-xxx ~]# docker inspect 1a6f88d328c2 | jq -r '.[0].NetworkSettings'
{
  ...
  "IPAddress": "",
  "IPPrefixLen": 0,
  "IPv6Gateway": "",
  "MacAddress": "",
  "Networks": {
    "host": {
      ...
      "Gateway": "",
      "IPAddress": "",
      "IPPrefixLen": 0,
      "IPv6Gateway": "",
      "GlobalIPv6Address": "",
      "GlobalIPv6PrefixLen": 0,
      "MacAddress": "",
      "DriverOpts": null
    }
  }
}

[root@ip-xxx ~]# netstat -tulpn
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
...
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      26732/nginx: master
...
tcp6       0      0 :::80                   :::*                    LISTEN      26732/nginx: master
...

[root@ip-10-0-100-21 ~]# curl localhost:80
<!DOCTYPE html>
<html>
...
<h1>Welcome to nginx!</h1>
...
</html>

```