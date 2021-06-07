---
title: "Dockerize the application"
chapter: false
weight: 50
---

### Why migrate to containers?

There are many benefits to running your applications on containers.
Some of the high level benefits you get when containerizing your workloads are:

- Standardized Packaging: Containers provide a standard way to package your application’s code, configurations, and dependencies into a single object.
- Consistency: Containers share an operating system installed on the server and run as resource-isolated processes, ensuring quick, reliable, and consistent deployments, regardless of environment.
- Security: Isolation between containers as the default.

In order to migrate our application to run on containers, we first need to package our application artifact as a Docker image.
Let's look at two approaches to getting up and running with containers.

### Cloud Native Buildpacks

A Buildpack offer a simplified way to build and manage docker images.
This is accomplished by simply providing your source code with the Buildpacks doing the rest.
For those who aren't familiar with Dockerfiles and want to avoid the boilerplate, Buildpacks can help with the heavy lifting.
Check out the [documentation](https://buildpacks.io/docs/app-journey/) for more information.

Let's test it out and see what the experience looks like.

#### Build the image

First we need to install the [pack](https://buildpacks.io/docs/tools/pack/) cli. This is the tool we will use to build our image.
Follow the instructions for getting it installed [here](https://buildpacks.io/docs/tools/pack/#install)

The first thing we'll do is set a default builder for our images. 
You have the choice of setting the default builder or you can specify the builder at build time.
A [builder](https://buildpacks.io/docs/concepts/) an image that contains all the components necessary to execute a build. A builder image is created by taking a build image and adding a lifecycle, buildpacks, and files that configure aspects of the build including the buildpack detection order and the location(s) of the run image.

```bash
pack config default-builder gcr.io/buildpacks/builder:v1
```

Next, we'll build the image.

```bash
cd app
pack build user-api
```

During this process, pack is doing the work to determine the programming language being used and building a Docker image to enable us to run our code.
If you look in the `app` directory, you'll see a file named `Procfile`. 
This file is all we need to tell pack how to run our application.

Once the build is complete, we will have a docker image that we can run locally. 
The name of the image artifact is `user-api` which is what we passed into the `pack build` command.

#### Run the image as a container locally

Using Docker, we will run the image we just built as a container on our Cloud9 instance.

```bash
docker run \
  --rm \
  --name userapi \
  -e DYNAMO_TABLE=UsersTable-test \
  -p 8080:8080 \
  -d user-api
```

The above command is going to run our image as a container. 
We are defining the port that we want to run on the host as well as our container.
We also rely on an environment variable inside of our application that defines what DynamoDB table the application will talk with.
For the workshop we will point to the test environment's table.

Now let's test that our container is working as we expect.

```bash
curl localhost:8080/health
```

The response should show `{"Status":"Healthy"}`. 
Success! Our application works exactly how it does running on an EC2 instance as well as running locally.

We can also check the logs via the docker service to see how the application logged the request.

```bash
docker logs userapi
```

Stop the docker image

```bash
docker stop userapi
```

This is a great way to get started, but at some point you will likely want to have more control over your Docker images and how they are defined.
In the next section, we'll build our image using a Dockerfile.

### Docker

For this portion of the workshop, we will interact use native Docker tooling.

#### Dockerfile

A [Dockerfile](https://docs.docker.com/engine/reference/builder/) is a text document that contains all the commands a user could call on the command line to assemble an image.
Essentially we use a Dockerfile as a way to define a simple set of instructions for how we want our build our artifacts.
To build our Docker image, we will start with creating our `Dockerfile`.

```bash
cat << EOF >> Dockerfile
FROM public.ecr.aws/bitnami/python:3.7

EXPOSE 8080

HEALTHCHECK --interval=5s --timeout=5s --start-period=5s --retries=2 \
  CMD curl -f http://localhost:8080/health || exit 1

WORKDIR /user-api

COPY main.py \
  dynamo_model.py \
  requirements.txt \
  users.csv \
  /user-api/

RUN pip3 install -r requirements.txt

CMD [ "python3", "main.py"]
EOF
```

Let's quickly walk through each of the commands that are included in the Dockerfile and what they will do.

- [FROM](https://docs.docker.com/engine/reference/builder/#from):
The FROM instruction initializes a new build stage and sets the base image for subsequent instructions.
This is a required command as this includes the operating system and any other binaries based on the upstream image.
You may notice that we are pulling a `python` image, which is another benefit of using Docker as we can use images that are scoped to specific use cases.
In this example, we're using an image that has what we need to run our python code.

- [EXPOSE](https://docs.docker.com/engine/reference/builder/#expose):
The EXPOSE instruction informs Docker that the container listens on the specified network ports at runtime. You can specify whether the port listens on TCP or UDP, and the default is TCP if the protocol is not specified.

- [HEALTHCHECK](https://docs.docker.com/engine/reference/builder/#healthcheck):
The HEALTHCHECK instruction tells Docker how to test a container to check that it is still working. This can detect cases such as a web server that is stuck in an infinite loop and unable to handle new connections, even though the server process is still running.

- [WORKDIR](https://docs.docker.com/engine/reference/builder/#workdir):
The WORKDIR instruction sets the working directory for any RUN, CMD, ENTRYPOINT, COPY and ADD instructions that follow it in the Dockerfile. 
For our application, we want to simplify the operations by running inside the directory where our code and other dependencies exist.
We'll run the application in the working directory as well as install our python packages via the requirements.txt file.

- [COPY](https://docs.docker.com/engine/reference/builder/#copy):
The COPY instruction copies new files or directories from `<src>` and adds them to the filesystem of the container at the path `<dest>`.
Multiple `<src>` resources may be specified but the paths of files and directories will be interpreted as relative to the source of the context of the build.
We're using the COPY command to move all of our code and dependencies into the image.

- [RUN](https://docs.docker.com/engine/reference/builder/#run):
The RUN instruction will execute any commands in a new layer on top of the current image and commit the results. The resulting committed image will be used for the next step in the Dockerfile.
We're using the RUN command to install our application dependencies via `pip`.

- [CMD](https://docs.docker.com/engine/reference/builder/#cmd):
There can only be one CMD instruction in a Dockerfile. If you list more than one CMD then only the last CMD will take effect.
The main purpose of a CMD is to provide defaults for an executing container. These defaults can include an executable, or they can omit the executable, in which case you must specify an ENTRYPOINT instruction as well.
Similar to how defined the `Procfile` with our buildpack image, we are using the CMD command to define the default behavior for running our application when the container runs.

#### Build the Docker image

Ok, so now that we have our instructions on how we expect our application to run as a container, we need to build the image.

Run the command to build our Docker image.

```bash
docker build -t user-api-docker:latest .
```

#### Run the Docker image as a container

Similar to what we did earlier, let's run a container from the image we just built and confirm it works.

```bash
docker run \
  --rm \
  --name userapi \
  -e DYNAMO_TABLE=UsersTable-test \
  -p 8080:8080 \
  -d user-api-docker:latest
```

Now let's test that our container is working as we expect.

```bash
curl localhost:8080/health
```

```bash
curl -s localhost:8080/all_users | jq
```

```bash
curl -s 'localhost:8080/user/?first=Sheldon&last=Cooper' | jq
```

That's it! We packaged our application into a container image using Docker and ran it locally.
This is hugely impactful to our workflow as this image will be no different than the one running in a production environment, with the exception of environment variables determining what database we interact with.

### Next steps

In this section, we packaged our application into a Docker image and tested it locally by running it in Docker.
Now we're ready to productionize this application, but where do we start?
Let's move on to the next section and look at how we can achieve this using the AWS Copilot CLI.
