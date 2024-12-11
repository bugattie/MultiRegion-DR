#!/bin/bash

# Set region variables
PRIMARY_REGION="us-east-1"
SECONDARY_REGION="us-east-2"

# CloudFormation templates
PRIMARY_TEMPLATE="primary_region_template.yaml"
SECONDARY_TEMPLATE="secondary_region_template.yaml"
SIMULATE_DISASTER_TEMPLATE="simulate_disaster_stack.yaml"

# Stack names
PRIMARY_STACK_NAME="PrimaryRegionStack"
SECONDARY_STACK_NAME="SecondaryRegionStack"
SIMULATE_DISASTER_STACK_NAME="SimulateDisasterStack"

# Deploy secondary region (standby bucket)
echo "Deploying secondary region infrastructure..."
aws cloudformation deploy \
  --region $SECONDARY_REGION \
  --stack-name $SECONDARY_STACK_NAME \
  --template-file $SECONDARY_TEMPLATE \
  --parameter-overrides \
      PrimaryDBArn="" \
  --capabilities CAPABILITY_NAMED_IAM

  # Fetch secondary bucket name
SECONDARY_BUCKET_NAME=$(aws cloudformation describe-stacks \
  --region $SECONDARY_REGION \
  --stack-name $SECONDARY_STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='SecondaryS3Bucket'].OutputValue" \
  --output text)

echo "Secondary S3 bucket: $SECONDARY_BUCKET_NAME"

# Deploy primary region (full infrastructure)
echo "Deploying primary region infrastructure..."
aws cloudformation deploy \
  --region $PRIMARY_REGION \
  --stack-name $PRIMARY_STACK_NAME \
  --template-file $PRIMARY_TEMPLATE \
  --parameter-overrides \
      SecondaryS3Bucket=$SECONDARY_BUCKET_NAME \
  --capabilities CAPABILITY_NAMED_IAM

# Fetch primary DB ARN
PRIMARY_DB_ARN=$(aws cloudformation describe-stacks \
  --region $PRIMARY_REGION \
  --stack-name $PRIMARY_STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='PrimaryDBARN'].OutputValue" \
  --output text)
echo "Primary DB ARN: $PRIMARY_DB_ARN"

# Update secondary region with read replica
echo "Updating secondary region with RDS read replica..."
aws cloudformation deploy \
  --region $SECONDARY_REGION \
  --stack-name $SECONDARY_STACK_NAME \
  --template-file $SECONDARY_TEMPLATE \
  --parameter-overrides \
      PrimaryDBArn=$PRIMARY_DB_ARN \
  --capabilities CAPABILITY_NAMED_IAM

echo "Deployment completed successfully!"