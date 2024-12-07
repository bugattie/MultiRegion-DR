aws cloudformation deploy --template-file ./standby.yaml --region ap-southeast-1 --stack-name standby-region-stack --capabilities CAPABILITY_NAMED_IAM

export SecondaryBucket=$(aws cloudformation describe-stacks \
    --stack-name standby-region-stack \
    --query "Stacks[0].Outputs[?OutputKey=='SecondaryBucketName'].OutputValue" \
    --output text \
    --region ap-southeast-1)
echo $SecondaryBucket

aws cloudformation deploy --template-file ./primary.yaml --stack-name active-region-stack --capabilities CAPABILITY_NAMED_IAM --parameter-overrides SecondaryBucketName=$SecondaryBucket

export PrimaryRegionReplicationRoleArn=$(aws cloudformation describe-stacks \
    --stack-name active-region-stack \
    --query "Stacks[0].Outputs[?OutputKey=='ReplicationRoleArn'].OutputValue" \
    --output text \
    --region us-east-1)
echo $PrimaryRegionReplicationRoleArn

export PrimaryDBIdentifier=$(aws cloudformation describe-stacks \
    --stack-name active-region-stack \
    --query "Stacks[0].Outputs[?OutputKey=='PrimaryDBIdentifier'].OutputValue" \
    --output text \
    --region us-east-1)
echo $PrimaryDBIdentifier

aws cloudformation deploy --template-file ./standby.yaml --region ap-southeast-1 --stack-name standby-region-stack --capabilities CAPABILITY_NAMED_IAM --parameter-overrides PrimaryDBIdentifier=$PrimaryDBIdentifier
