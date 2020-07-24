+++
title = "Update CodeCommit Repository"
chapter = false
weight = 5
+++

#### Push the source code to the CodeCommit repository
The stack created an empty CodeCommit repository - `demo-app`. Now we will populate it with a sample demo application.

#### Clone the demo application
```bash
cd ~/environment
git clone https://github.com/smuralee/nginx-example.git
```

#### Update the remote origin URL
Change the remote origin to the CodeCommit repository. We fetch the repository URL

```bash
cd ~/environment/nginx-example
git remote set-url origin $(aws codecommit get-repository --repository-name demo-app | jq -r '.repositoryMetadata.cloneUrlHttp')
```

#### Verify the remote origin url is pointing to the CodeCommit repository
```bash
git remote -v
```

#### Edit the `index.html`. We change the `background-color` to `green`
```html
<head>
  <title>Demo Application</title>
</head>
<body style="background-color: green;">
  <h1 style="color: white; text-align: center;">
    Demo application - hosted with ECS
  </h1>
</body>
```


#### Push the code to the CodeCommit repository
```bash
git add .
git commit -m "Changed background to green"
git push
``` 

#### Navigate to CodePipeline
* The code push has triggered the pipeline execution
* We have three stages in the pipeline
    * **Source**
        * Package the artifacts for the build stage
    * **Build**
        * Build the code
        * Push to the ECR repository
        * Package the artifacts for the deploy stage 
    * **Deploy**
        * Initiate the blue/green deployment for the ECS service

![Navigate-to-CodePipeline](/images/blue-green-navigate-to-code-pipeline.gif)

* Next we will review the deployment

