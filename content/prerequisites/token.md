+++
title = "Create a GitHub token"
chapter = false
weight = 4
+++

- Go to https://github.com/settings/tokens/new
  - Type **workshop** in the token description
  - Check **repo**
  - Check **admin:repo_hook**
  - Select **generate token**

  Let's add your GitHub token to the environment:
  {{% notice tip %}}
  replace **your_github_token** with your GitHub token
  {{% /notice%}}

  ```
  export GITHUB_TOKEN=your_github_token
  ```

  Once that is set correctly, we will persist it for future terminals:
  ```
  echo "export GITHUB_TOKEN=${GITHUB_TOKEN}" >> ~/.bashrc
  ```
