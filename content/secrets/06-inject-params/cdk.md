---
title: "Embedded tab content"
disableToc: true
hidden: true
---

Within a CDK application, you can pull both plaintext and secure secret parameters via the `aws-cdk/aws-ssm` library.

First, add the `aws-ssm` library to the CDK project.

```bash
npm install @aws-cdk/aws-ssm
```

Then, create a secure SSM parameter
```bash
aws ssm put-parameter --name GH_WEBHOOK_SECRET --value secretvalue1234 --type SecureString
```

Then, in the stack of your choosing, add the code to access the newly created SSM Parameter:

```typescript
import { SecretValue } from '@aws-cdk/core';
import { StringParameter, ParameterTier } from "@aws-cdk/aws-ssm";

//Get value from SSM
const ghValue = SecretValue.ssmSecure('GH_WEBHOOK_SECRET', '1');

//Set a new value into a SSM parameter
const myNewSsmValue = new StringParameter(this, 'MyValue', {
    allowedPattern: '.*',
    description: 'Parameter Description',
    parameterName: 'MyNewParam',
    stringValue:  <SOME STRING VALUE>
    tier: ParameterTier.STANDARD
});

```
