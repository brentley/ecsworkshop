---
title: "Acceptance and Production"
disableToc: true
hidden: true
---

### Overview

The beauty of the copilot-cli is that you don't have to think about building the platform, and how to connect all of the resources together.
Because of the opinionated nature of the tool, you simply start by defining your [Application](https://github.com/aws/copilot-cli/wiki/Applications), and copilot takes care of the rest (with the ability to tweak/modify your config as needed).
So what does the rest mean exactly? This means that it will deploy all of the underlying resources needed for your [Services](https://github.com/aws/copilot-cli/wiki/Services) to run on/with.
These resources that are deployed include: VPC, Subnets, Security Groups, Application Load Balancer (if needed), a service discovery namespace (if needed), and many more.
 
To read more about the copilot-cli concepts, check out the [documentation](https://github.com/aws/copilot-cli/wiki/Concepts).

That's it for the platform section! Let's move on to creating our Application, and deploying our frontend service.