---
title: "Validate our \"existing\" environment works"
chapter: false
weight: 45
---

Let's confirm that our application is working as we would expect in the original environment.
To accomplish this, we will grab the EC2 Instance ID and then enter into a shell on that host using SSM Session Manager.

```bash
# Grab the instance ID for us to access
instance_id=$(aws ec2 describe-instances --filters Name=instance-state-name,Values=running Name=tag:Name,Values=BuildEc2EnvironmentStack/ApplicationASG --query Reservations[].Instances[0].InstanceId --output text)
# Start a shell via SSM session manager
aws ssm start-session --target $instance_id
```

Once we're in the host we can look around and run some curl commands against localhost to confirm our app works as expected.

First, check the health of the app:

```bash
curl localhost:8080/health
```

The response should be `{"Status":"Healthy"}`

Next, load the database with the users:

```bash
curl XPOST localhost:8080/load_db
```

The response should be `{"Status":"Success"}`

Now that the data is loaded we can run a couple of queries to confirm the data exists:

```bash
# Query specific user
curl -s 'localhost:8080/user/?first=Sheldon&last=Cooper' | jq
```

```bash
# Query all users
curl -s localhost:8080/all_users | jq
```

Perfect. At this point we have a fully functioning application running on EC2. 
Now let's move to the next section where we talk about how to migrate.