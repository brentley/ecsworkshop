+++
title = "Clean up"
chapter = false
weight = 12
+++

#### Delete the sample Prometheus application and platform

```bash
cd ~/environment/ecsdemo-amp/cdk
cdk destroy -f
```

#### Delete the AMP workspace

```bash
aws amp delete-workspace $AMP_WORKSPACE_ID
```

#### Delete the AMG workspace


To delete an AMG workspace:

- Open the AMG console at https://console.aws.amazon.com/grafana/

- In the navigation pane, choose the menu icon.

- Choose All workspaces.

- Choose ecs-workshop workspace.

- Choose Delete.

- To confirm the deletion, enter the name of the workspace and choose Delete.
