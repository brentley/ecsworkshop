---
title: "Build the original environment"
chapter: false
weight: 40
---

The first step in the workshop is to deploy our application running on Amazon EC2.
Run the commands below and while the build is happening, proceed to the code review section to gain an understanding of what we're building and deploying.

```bash
cd ~/environment/ec2_to_ecs_migration_workshop/build_ec2_environment
cdk deploy --require-approval never
```
 
#### Code Review

We are using the [AWS Cloud Development Kit (CDK)](https://aws.amazon.com/cdk/) to provision our resources for our environment, which we plan to migrate from.
The build command is going to provision a VPC, a DynamoDB table, as well as an EC2 instance residing within an Autoscaling group.
The application is running as a systemd unit via systemctl, which is configured via a script stored in the [user data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html).
This ensures the service is started and enabled every time a new EC2 instance launches.

{{%expand "Let's Dive in" %}}

The code can be reviewed in full under `./build_ec2_environment/build_ec2_environment_stack.py`.

First, we're creating our VPC and DynamoDB table. 
Note that the VPC construct is going to build a VPC in an opinionated way taking advantage of recommended practices.

```python
# Will create VPC, spanning two AZ's, private and public with NAT Gateways
_vpc = ec2.Vpc(self, "DemoVPC")

dynamo_table = dynamodb.Table(
    self, "UsersTable",
    table_name=f"UsersTable-{self.deploy_env}",
    partition_key=dynamodb.Attribute(name="first_name", type=dynamodb.AttributeType.STRING),
    sort_key=dynamodb.Attribute(name="last_name", type=dynamodb.AttributeType.STRING),
)
```

The last thing to point out is how we are building our EC2 instance and deploying our application.
We are pulling down a script that drops the code into the `/usr/lib` path and handles some other pre-requisites.
In the same user data script we are creating a systemd unit to ensure our application runs as expected.
Lastly, we are managing instance count and scaling through an Autoscaling group.

```python
user_data = ec2.UserData.custom(f"""#!/usr/bin/env bash
        
# Pulling down the code and creating necessary folders/user
wget https://gist.githubusercontent.com/adamjkeller/cb2dfcd2ad6c6dc74d02c83759f2a1c5/raw/93b65f6b11d07574667d636678e7716b805a8097/setup.sh
bash -x ./setup.sh

# Create systemd unit
cat << EOF >> /etc/systemd/system/user-api.service
[Unit]
Description=User API
After=network.target
[Service]
Type=simple
Restart=always
RestartSec=5
User=root
Environment=DYNAMO_TABLE={dynamo_table.table_name}
WorkingDirectory=/usr/local/user_api
ExecStart=/usr/bin/python3 main.py
EOF

systemctl enable user-api.service
systemctl start user-api.service
""")
        
asg = autoscaling.AutoScalingGroup(
    self, "ApplicationASG",
    instance_type=ec2.InstanceType('t3.small'),
    machine_image=ec2.MachineImage.latest_amazon_linux(
        generation=ec2.AmazonLinuxGeneration.AMAZON_LINUX_2,
        user_data=user_data
    ),
    vpc=_vpc
)
```

{{% /expand %}}

- Once the deployment is complete, let's access the EC2 instance and test our application.
