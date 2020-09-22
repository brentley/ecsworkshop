---
title: "Create a Workspace"
chapter: false
weight: 15
---

{{% notice warning %}}
The Cloud9 workspace should be built by an IAM user with Administrator privileges,
not the root account user. Please ensure you are logged in as an IAM user, not the root
account user.
{{% /notice %}}

{{% notice tip %}}
Ad blockers, javascript disablers, and tracking blockers should be disabled for
the cloud9 domain, or connecting to the workspace might be impacted.
Cloud9 requires third-party-cookies. You can whitelist the [specific domains]( https://docs.aws.amazon.com/cloud9/latest/user-guide/troubleshooting.html#troubleshooting-env-loading).
{{% /notice %}}

### Launch Cloud9 in your closest region:
{{< tabs name="Region" >}}
{{{< tab name="Oregon" include="us-west-2.md" />}}
{{{< tab name="Ireland" include="eu-west-1.md" />}}
{{{< tab name="Frankfurt" include="eu-central-1.md" />}}
{{{< tab name="Ohio" include="us-east-2.md" />}}
{{{< tab name="Singapore" include="ap-southeast-1.md" />}}
{{{< tab name="Tokyo" include="ap-northeast-1.md" />}}
{{< /tabs >}}

- Select **Create environment**
- Name it **ecsworkshop**, and select **Next Step**
- Stick with the default settings, and select **Next Step** 
- Lastly, select **Create Environment**
- When it comes up, customize the environment by closing the **welcome tab**
and **lower work area**, and opening a new **terminal** tab in the main work area:
![c9before](/images/c9before.png)

- Your workspace should now look like this:
![c9after](/images/c9after.png)

- If you like this theme, you can choose it yourself by selecting **View / Themes / Solarized / Solarized Dark**
in the Cloud9 workspace menu.

### Create the IAM Role and attach it to the Cloud9 instance

- Follow [this deep link to create an IAM role with Administrator access.](https://console.aws.amazon.com/iam/home#/roles$new?step=review&commonUseCase=EC2%2BEC2&selectedUseCase=EC2&policies=arn:aws:iam::aws:policy%2FAdministratorAccess)
- Confirm that **AWS service** and **EC2** are selected, then click **Next** to view permissions.
- Confirm that **AdministratorAccess** is checked, then click **Next: Tags** to assign tags.
- Take the defaults, and click **Next: Review** to review.
- Enter **ecsworkshop-admin** for the Name, and click **Create role**.
![createrole](/images/createrole.png)

- Follow [this deep link to find your Cloud9 EC2 instance](https://console.aws.amazon.com/ec2/v2/home?#Instances:tag:Name=aws-cloud9-ecsworkshop;sort=desc:launchTime)
- Select the instance, then choose **Actions / Instance Settings / Attach/Replace IAM Role**
![c9instancerole](/images/c9instancerole.png)
- Choose **ecsworkshop-admin** from the **IAM Role** drop down, and select **Apply**
![c9attachrole](/images/c9attachrole.png)
- Now head back to the Cloud9 IDE

### Increase the disk size on the Cloud9 instance

```bash
sudo pip install boto3
export instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
python -c "import boto3
import os
from botocore.exceptions import ClientError 
ec2 = boto3.client('ec2')
volume_info = ec2.describe_volumes(
    Filters=[
        {
            'Name': 'attachment.instance-id',
            'Values': [
                os.getenv('instance_id')
            ]
        }
    ]
)
volume_id = volume_info['Volumes'][0]['VolumeId']
try:
    resize = ec2.modify_volume(    
            VolumeId=volume_id,    
            Size=30
    )
    print(resize)
except ClientError as e:
    if e.response['Error']['Code'] == 'InvalidParameterValue':
        print('ERROR MESSAGE: {}'.format(e))"
if [ $? -eq 0 ]; then
    sudo reboot
fi

```

- *Note*: The above command is adding more disk space to the root volume of the EC2 instance that Cloud9 runs on. Once the command completes, we reboot the instance which could take a minute or two for the IDE to come back online.
