+++
title = "Delete IAM Common"
chapter = false
weight = 35
draft = true
+++

{{% notice warning %}}
Ensure all "mu" stacks, excluding "iam-common" are completely gone before continuing
{{% /notice %}}

We want to make sure we don't delete the "iam-common" role before the other cloudformation
stacks have been completely deleted. This little script should tell us if it's safe
to continue deleting the "iam-common" stack.

Use the copy button to copy this to your clipboard, then paste into your workspace:
```bash
STACK_COUNT=$(aws cloudformation list-stacks --stack-status-filter \
  CREATE_IN_PROGRESS CREATE_COMPLETE ROLLBACK_IN_PROGRESS ROLLBACK_FAILED ROLLBACK_COMPLETE \
  DELETE_IN_PROGRESS DELETE_FAILED UPDATE_IN_PROGRESS \
  UPDATE_COMPLETE_CLEANUP_IN_PROGRESS UPDATE_COMPLETE UPDATE_ROLLBACK_IN_PROGRESS \
  UPDATE_ROLLBACK_FAILED UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS \
  UPDATE_ROLLBACK_COMPLETE REVIEW_IN_PROGRESS \
  --query "StackSummaries[*].StackName" |grep -c $MU_NAMESPACE)

if [ $STACK_COUNT -gt 1 ]; then
  echo "========================================================================="
  echo "You still have $MU_NAMESPACE stacks, and shouldn't delete iam-common yet."
  echo "========================================================================="
else
  echo "Disabling termination protection on $MU_NAMESPACE-iam-common"
  aws cloudformation update-termination-protection --no-enable-termination-protection --stack-name $MU_NAMESPACE-iam-common
  echo "Your $MU_NAMESPACE stacks have been deleted. Go ahead and delete $MU_NAMESPACE-iam-common."
fi
```
Lastly, we can delete the IAM role that CloudFormation used to build and manage the other CloudFormation stacks:
```
aws cloudformation delete-stack --stack-name ${MU_NAMESPACE}-iam-common
```
