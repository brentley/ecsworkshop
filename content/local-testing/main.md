+++
title = "Testing all the services"
chapter = false
weight = 1
+++

Awesome, we've deployed the applications to ECS, but now we want to iterate locally as we make changes in realtime!

## Install docker-compose (if you haven't already)

```
# Install docker compose: https://docs.docker.com/compose/install/
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

{{< tabs name="Test services locally">}}
{{< tab name="Frontend Service" include="tabs/frontend.md" />}}
{{< tab name="Node.js Service" include="tabs/nodejs.md" />}}
{{< tab name="Crystal Service" include="tabs/crystal.md" />}}
{{< /tabs >}}

That's it! As you can see, you were able to re-create the environment running in the cloud on ECS to your local workstation for quick testing.

