---
title: "Deepdive: Multistage Builds"
date: 2018-02-27T20:29:24Z
pre: "<i class='fa fa-search'></i> "
draft: true
---
With version ${VERSION} docker instroduced a new feature for building docker images: Multistage Builds.

A Docker multistage build is simply building a container, as usual, but then chaining the build of a second container
and copying one or more artifacts from the first container to the second.

Why?

If you're building a language that produces a single artifact (go, c, crystal, java, etc...), then you can use a
rich environment during the build phase, but a small environment for the actual container that gets deployed and
executed.

Let's look at multistage builds in action when we build our Crystal container:

```
FROM crystallang/crystal:latest
WORKDIR /src/
COPY . .
RUN shards install
RUN crystal build --release --link-flags="-static" src/server.cr

FROM alpine:latest
RUN apk -U add curl
COPY --from=0 /src/server /server
COPY --from=0 /src/code_hash.txt /code_hash.txt
HEALTHCHECK --interval=10s --timeout=3s \
  CMD curl -f -s http://localhost:3000/health || exit 1
EXPOSE 3000
CMD ["/server"]
```

In this Dockerfile, we start our build using the official crystallang docker image:
`FROM crystallang/crystal:latest`.
This image is ${SIZE} in size.

Before multistage builds, our docker image that we deploy would be ${SIZE} at minimum.
However, with multistage builds, we can build our artifact in this large docker image,
and then copy the artifact to a new smaller container. We don't need the build environment, or
build components to run our artifact, only to build it.

We create a second container starting with the line: `FROM alpine:latest`. This container is ~4MB in size,
drastically smaller than our build container.

We copy in the compiled executable `server` and the build file `code_hash.txt`. That's all we need to execute
our application. The end result is a container that we deploy that is ~5MB in size.

Consider using Docker Multistage builds with your existing compiled projects.
