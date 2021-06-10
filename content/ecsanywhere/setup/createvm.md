+++
title = "Create VM"
description = "Pre-requiste steps for setting up and running workloads in ECS-A"
weight = 4
+++

We will use Vagrant in order to create a virtual machine and install all the required artifacts before running the workloads.

### Vagrant

Vagrant is an open-source software product for building and maintaining portable virtual software development environments; e.g., for VirtualBox, KVM, Hyper-V, Docker containers, VMware, and AWS. It tries to simplify the software configuration management of virtualization in order to increase development productivity, read more about it [here](https://www.vagrantup.com/).

A `Vagrant` file is used to orchestrate what goes inside these VMs. Part of this workshop a sample `Vagrant` file is available part of the root directory which creates a virtual machine with the below configurations:

* OS -  ubuntu-20.0
* Memory - 2048 MB
* CPU - 2
* Port forwarding - Host Port 80 and Target port 80

Here is how the Vagrant file looks like:

```ruby
Vagrant.configure("2") do |config|
    config.vm.box = "bento/ubuntu-20.04"
    config.vm.network "forwarded_port", guest: 8080, host: 8080
    config.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.cpus = 2
    end
end
```

### Create VM

1. Create a Vagrant VM, by running the following command from root directory (where `Vagrant` file is placed):

    ```bash
    #Launch Vagrant 
    vagrant up
    ```

    **Output**

    ```bash
    Bringing machine 'default' up with 'virtualbox' provider...
    ==> default: Importing base box 'bento/ubuntu-20.04'...
    ==> default: Matching MAC address for NAT networking...
    ==> default: Checking if box 'bento/ubuntu-20.04' version '202012.23.0' is up to date...
    ==> default: Setting the name of the VM: ecs-a_default_1620457707052_37629
    ==> default: Clearing any previously set network interfaces...
    ==> default: Preparing network interfaces based on configuration...
        default: Adapter 1: nat
    ==> default: Forwarding ports...
        default: 8080 (guest) => 8080 (host) (adapter 1)
        default: 22 (guest) => 2222 (host) (adapter 1)
    ==> default: Running 'pre-boot' VM customizations...
    ==> default: Booting VM...
    ==> default: Waiting for machine to boot. This may take a few minutes...
        default: SSH address: 127.0.0.1:2222
        default: SSH username: vagrant
        default: SSH auth method: private key
        default:
        default: Vagrant insecure key detected. Vagrant will automatically replace
        default: this with a newly generated keypair for better security.
        default:
        default: Inserting generated public key within guest...
        default: Removing insecure key from the guest if it's present...
        default: Key inserted! Disconnecting and reconnecting using new SSH key...
    ==> default: Machine booted and ready!
    ==> default: Checking for guest additions in VM...
    ==> default: Mounting shared folders...
        default: /vagrant => /Users/harrajag/CodeBase/ecs-a
    ```

2. Run the following command to ssh into the newly created virtual machine

    ```bash
    # ssh to vagrant box
    vagrant ssh
    ```

    **Output**

    ```bash
    Welcome to Ubuntu 20.04.1 LTS (GNU/Linux 5.4.0-58-generic x86_64)

    * Documentation:  https://help.ubuntu.com
    * Management:     https://landscape.canonical.com
    * Support:        https://ubuntu.com/advantage

    System information as of Sat 08 May 2021 07:12:06 AM UTC

    System load:  0.03              Processes:             121
    Usage of /:   2.2% of 61.31GB   Users logged in:       0
    Memory usage: 7%                IPv4 address for eth0: 10.0.2.15
    Swap usage:   0%


    This system is built by the Bento project by Chef Software
    More information can be found at https://github.com/chef/bento
    ```

### Install required software on Vagrant vm

1. Run the following command to setup the ECS-anywhere activation ID and code thats required for running the install

    ```bash
    # Run all commands on the vagrant machine
    export ACTIVATION_ID=<<ACTIVATION_ID>>
    export ACTIVATION_CODE=<<ACTIVATION_CODE>>
    ```

    > Note: Replace `ACTIVATION_ID` and `ACTIVATION_CODE` with the actual values available inside `ssm-activation.json` file of the host machine

2. Download ECS-anywhere install shell script, update permissions and check the integrity of the file before proceeding to next step

    ```bash
    # Download the ecs-anywhere install Script 
    curl -o "ecs-anywhere-install.sh" "https://amazon-ecs-agent-packages-preview.s3.us-east-1.amazonaws.com/ecs-anywhere-install.sh" && sudo chmod +x ecs-anywhere-install.sh

    # (Optional) Check integrity of the shell script
    curl -o "ecs-anywhere-install.sh.sha256" "https://amazon-ecs-agent-packages-preview.s3.us-east-1.amazonaws.com/ecs-anywhere-install.sh.sha256" && sha256sum -c ecs-anywhere-install.sh.sha256
    ```

3. Run the following command to install `ECS agent` and `SSM agent` which will allow ECS control plane to manage and run workloads on this virtual machine

    ```bash
    # Run the install script
    sudo ./ecs-anywhere-install.sh \
        --cluster test-ecs-anywhere \
        --activation-id $ACTIVATION_ID \
        --activation-code $ACTIVATION_CODE \
        --region us-east-1 
    ```

    > Note: Make sure to update `--region` parameter to reflect the AWS region in which ECS cluster has been created

    **Output**

    ```bash
    .......
    Created symlink /etc/systemd/system/multi-user.target.wants/ecs.service → /lib/systemd/system/ecs.service.

    # ok
    ##########################
    ```

4. Verify whether the virtual box is connected to ECS control plane and its up and running by executing the following commands.

{{% notice note %}}
First run exit command to exit the virtual machine and run the below commands in the host machine
{{% /notice %}}

```bash
aws ssm describe-instance-information
aws ecs list-container-instances --cluster $CLUSTER_NAME
```

**Output for #1**

```json
{
    "InstanceInformationList": [
        {
            "InstanceId": "mi-0196d7ad4ec28e311",
            "PingStatus": "Online",
            "LastPingDateTime": "2021-05-08T00:38:46.740000-07:00",
            "AgentVersion": "3.0.1124.0",
            "IsLatestVersion": true,
            "PlatformType": "Linux",
            "PlatformName": "Ubuntu",
            "PlatformVersion": "20.04",
            "ActivationId": "7524075d-6ac9-40a2-bf9b-b0835616ed5e",
            "IamRole": "ecsMithrilRole",
            "RegistrationDate": "2021-05-08T00:32:07.882000-07:00",
            "ResourceType": "ManagedInstance",
            "IPAddress": "10.0.2.15",
            "ComputerName": "vagrant.vm"
        }
    ]
}
```

**Output for #2**

```json
{
    "containerInstanceArns": [
        "arn:aws:ecs:us-east-1:775492342640:container-instance/test-ecs-anywhere/532c117d0b3247a690d0e8b415ad2566"
    ]
}
```
