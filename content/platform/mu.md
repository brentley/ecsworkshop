+++
title = "Mu"
chapter = false
weight = 3
+++

### We will use [Mu](https://getmu.io) for this workshop. Why Mu?

#### <i class="fa fa-gavel fa-lg"></i> It's Opinionated<br>
Mu takes all of the best practices learned from operating in many organizations and generates
sensible _boilerplate_ CloudFormation to support running your infrastructure and microservices.

#### <i class="fas fa-smile fa-lg"></i> It focuses on the developer experience<br>
Mu keeps the developer experience simple, giving tools to get your microservice running as quickly
as possible, and tools to support the developer troubleshooting problems with the microservices.

#### <i class="fa fa-cloud fa-lg"></i> It's Cloud Native<br>
Mu knows when to stay out of the way.  Mu only uses AWS resources for deploying your microservices.

#### <i class="fa fa-rocket fa-lg"></i> Continuous Delivery<br>
Mu uses CodePipeline and CodeBuild to continuously test and delivery your microservice to production.

#### <i class="fa fa-cogs fa-lg"></i> Polyglot<br>
Mu doesn't have a favorite language.  If you can get your microservice running with a Dockerfile, then mu can help!</p>

#### <i class="fab fa-codepen fa-lg"></i> Stateless<br>
You are not locked in to using Mu.  Mu doesn't have any servers or databases running anywhere.  Mu leverages CloudFormation to manage state for all AWS resources.</p>

#### <i class="fa fa-code fa-lg"></i> Declarative<br>
Mu makes sure you get what you want.  You declare your configuration in a YAML file and commit with your source code.  Mu takes care of setting up your AWS resources to meet your needs.</p>

#### <i class="fab fa-github fa-lg"></i> Open Source<br>
Mu is MIT licensed, so you can use it commercially.  Mu is always looking to improve, so please consider contributing!</p>

{{% notice note %}}
Mu **only writes** CloudFormation. To enhance developer experience, Mu also **reads** from the apis of CloudWatch,
ECS, ECR and CloudTrail, using the local developer's credentials.
{{% /notice %}}
