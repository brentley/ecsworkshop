+++
title = "Opinionated Tooling"
chapter = false
weight = 2
+++

Several universities make the claim that, when deciding where to put sidewalks, they first let students
wear paths through the grass. This told them where to pave and ensured the best use of their walkways.

![paths](/images/osu.jpg)

You can think of these _well worn paths_ in cloud architecture as a procedure, or design, that gets repeated
over and over again, to the point that it should just become _boilerplate_. Rather than everyone composing
the same 99% of code, we can generate that code, and focus on the 1% that is unique.

Opinionated tooling is designed to guide you down a path that is considered a _best practice_.
Additionally, since _best practice_ is the default, the amount of unique code we maintain is
dramatically reduced.

Opinionated tooling doesn't eliminate options, however, it simply assumes some sensible defaults and relies
on the user to understand when it makes sense to deviate from those defaults.

Rather than writing thousands of lines of CloudFormation to build and orchestrate ECS, ECR,
EC2, ELB, VPC, and IAM resources ourselves, we can start with a smart set of defaults, and just
fill in a few blanks, customizing only the parts that we want changed, and let our opinionated tool generate
the _boilerplate_.

![opinionated](/images/opinionated.gif)
