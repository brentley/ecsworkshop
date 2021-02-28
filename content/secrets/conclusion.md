---
title: "Conclusion"
chapter: false
weight: 40
---

In this module we went over how to store and work with secrets in ECS.   

The most common question customers ask is when to use Secrets Manager versus Parameter Store.  The answer depends on your business case and sensitivity of the data being stored.  

As a best practice, use Secrets Manager unless there is a compelling reason not to use it.   Secrets Manager handles the security transit of sensitive data as well as credential rotation.   Secrets manager is tightly integrated with AWS services and is the best choice for handling sensitive data between AWS services.    
