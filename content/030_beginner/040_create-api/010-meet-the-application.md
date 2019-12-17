---
title: "Meet the application"
chapter: false
weight: 1
---

Let's deploy something a little more complicated. Most applications require more than just a
static website. They need to run code on the server side. Sometimes this code generates
website content dynamically. Or it functions as an API which is responsible for storing and
retrieving dynamic content for the static website.

We are going to build a simple Node.js application that stores and retrieves messages. It will
be a stateless API, meaning it doesn't persist the messages by itself. Instead it stores the
messages externally, in a database table. The database used for this application is DynamoDB.

We will create a serverless DynamoDB table with on demand usage so we don't have to worry about
scaling, then deploy a Node.js API that uses the table.

![diagram.png](/images/basic-node-api-diagram.png)