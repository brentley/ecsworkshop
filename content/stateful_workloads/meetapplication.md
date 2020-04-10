+++
title = "Meet the application"
chapter = false
weight = 2
+++

For this part of the workshop, we will be deploying a cloud file manager to Fargate. [Cloud Commander](https://cloudcmd.io/) is a file manager built for the web, and is a perfect fit to showcase persistent storage functionality.

Prior to the release of EFS integration with Fargate (and EC2), one would have to deploy this container to run on EC2 as well as take additional steps to mount the volume to the host, and then the container.

With the EFS integration, that extra work is gone, and all it takes is to simply point to the EFS volume in the task definition.

Below is a diagram of the environment we will be building:

<DIAGRAM HERE>