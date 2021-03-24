---
title: "NAT mode (Windows)"
chapter: false
weight: 50
---

Docker for Windows uses a different network mode (known as NAT) than Docker for Linux.

When you register a task definition with Windows containers, you must not specify a network mode.
If you use the AWS Management Console to register a task definition with Windows containers, you must choose the \<default\> network mode. 

To read more about docker 'NAT' networking mode [visit](https://docs.microsoft.com/en-us/virtualization/windowscontainers/container-networking/network-drivers-topologies)

A sample ECS Task Definition for windows would look like:
```
{
  "family": "windows-simple-iis",
  "containerDefinitions": [
    {
      "name": "windows_sample_app",
      "image": "microsoft/iis",
      "cpu": 512,
      "entryPoint":["powershell", "-Command"],
      "command":["New-Item -Path C:\\inetpub\\wwwroot\\index.html -Type file -Value '<html> <head> <title>Amazon ECS Sample App</title> <style>body {margin-top: 40px; background-color: #333;} </style> </head><body> <div style=color:white;text-align:center> <h1>Amazon ECS Sample App</h1> <h2>Congratulations!</h2> <p>Your application is now running on a container in Amazon ECS.</p>'; C:\\ServiceMonitor.exe w3svc"],
      "portMappings": [
        {
          "protocol": "tcp",
          "containerPort": 80,
          "hostPort": 8080
        }
      ],
      "memory": 1024,
      "essential": true
    }
  ]
}
```

More details around ECS Task Definitions for windows based workloads [visit](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/windows_task_definitions.html)

# Lab exercise

In this lab we will be executing below commands to inspect container running in windows using NAT network mode.

```
docker ps
docker inspect <container ID>
docker network ls
docker network inspect <Network ID>
curl -UseBasicParsing <container ip>
```

listing all running containers:
```
PS C:\Windows\system32> docker ps
CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
26cec63ef6ed microsoft/iis "powershell -Command…" 7 hours ago Up 7 hours 0.0.0.0:8080→80/tcp ecs-windows-simple-iis-1-windowssampleapp-aac6f7affe90a4d3a601
```

Inspecting network related setting for a container
```
PS C:\Windows\system32> docker inspect 26cec63ef6ed
...
"Networks":{
   "nat":{
      "IPAMConfig":null,
      "Links":null,
      "Aliases":null,
      "NetworkID":"644d30a399616f260b363ad12fb4da1d48bef0e79b03adde5472aa4293e7f2b1",
      "EndpointID":"83ba7b906f799d0221939941a09b0c1489b5cacb3e245ce23e7497a146f8a686",
      "Gateway":"172.18.128.1",
      "IPAddress":"172.18.142.217",
      "IPPrefixLen":16,
      "IPv6Gateway":"",
      "GlobalIPv6Address":"",
      "GlobalIPv6PrefixLen":0,
      "MacAddress":"00:15:5d:f2:1b:a5",
      "DriverOpts":null
   }
}
...
```

Listing Docker Network:
```
PS C:\Windows\system32> docker network ls
NETWORK ID NAME DRIVER SCOPE
644d30a39961 nat nat local
76ad6ec4c8d8 none null local
```

Inspecting Docker Network
```
PS C:\Windows\system32> docker network inspect 644d30a39961
[
   {
      "Name":"nat",
      "Id":"644d30a399616f260b363ad12fb4da1d48bef0e79b03adde5472aa4293e7f2b1",
      "Created":"2021-03-23T21:22:59.0032121Z",
      "Scope":"local",
      "Driver":"nat",
      "EnableIPv6":false,
      "IPAM":{
         "Driver":"windows",
         "Options":null,
         "Config":[
            {
               "Subnet":"172.18.128.0/20",
               "Gateway":"172.18.128.1"
            }
         ]
      },
      "Internal":false,
      "Attachable":false,
      "Ingress":false,
      "ConfigFrom":{
         "Network":""
      },
      "ConfigOnly":false,
      "Containers":{
         "26cec63ef6ed6ab814410d08c84841cdd87083dd77482ff7fb0644ac7490ae8c":{
            "Name":"ecs-windows-simple-iis-1-windowssampleapp-aac6f7affe90a4d3a601",
            "EndpointID":"83ba7b906f799d0221939941a09b0c1489b5cacb3e245ce23e7497a146f8a686",
            "MacAddress":"00:15:5d:f2:1b:a5",
            "IPv4Address":"172.18.142.217/16",
            "IPv6Address":""
         }
      },
      "Options":{
         "com.docker.network.windowsshim.hnsid":"E76A7D9E-1E35-4BA1-AC8E-C7B742D3019A",
         "com.docker.network.windowsshim.networkname":"nat"
      },
      "Labels":{
         
      }
   }
]
```

Finally output from a running IIS server:
```
PS C:\Windows\system32> curl -UseBasicParsing 172.18.142.217


StatusCode        : 200
StatusDescription : OK
Content           : <html> <head> <title>Amazon ECS Sample App</title> <style>body {margin-top: 40px; background-color: #333;} </style> </head><body> <div style=color:white;text-align:center> <h1>Amazon ECS Sample App</h...
RawContent        : HTTP/1.1 200 OK
                    Accept-Ranges: bytes
                    Content-Length: 297
                    Content-Type: text/html
                    Date: Wed, 24 Mar 2021 05:11:01 GMT
                    ETag: "67f5ae52b20d71:0"
                    Last-Modified: Tue, 23 Mar 2021 21:31:33 GMT
                    Server...
Forms             :
Headers           : {[Accept-Ranges, bytes], [Content-Length, 297], [Content-Type, text/html], [Date, Wed, 24 Mar 2021 05:11:01 GMT]...}
Images            : {}
InputFields       : {}
Links             : {}
ParsedHtml        :
RawContentLength  : 297
```


