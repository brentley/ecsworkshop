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

# Lab exercise

In this lab we will be executing below commands to inspect container running with none as network mode.

```
docker ps
docker inspect <container ID>
docker exec -it <container ID>
```

listing out containers:
```
# docker ps
CONTAINER ID        IMAGE                            COMMAND             CREATED             STATUS                 PORTS               NAMES
c0bb64ff6dcb        alpine                           "/bin/sh"           5 seconds ago       Up 4 seconds                               ecs-alpine-2-eab2b5f680eca9b55c00
```

We can inspect that network is specified as none and rest of the setting are empty/null
```
...
            "Networks": {
                "none": {
                    "IPAMConfig": null,
                    "Links": null,
                    "Aliases": null,
                    "NetworkID": "786ad1a16b029377a6d60aaedcc7b52af8efbc3d403455b5a1666f6e54ec82cd",
                    "EndpointID": "feff4f7698b339acb3a68c645b7b77386dcd318e1c088a7db133ae90bb2d67b4",
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
...
```

Lets inspect into network interfaces and as expected there are no interfaces and routes
```
# docker exec -it c0bb64ff6dcb ash
/ # 
/ # 
/ # ip a sh
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever

/ # ip link sh
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
/ # 

/ # ip r sh
/ # 

```
