import boto3
import os

def lambda_handler(event, context):
    region = 'us-east-1'
    asg_client = boto3.client('autoscaling', region_name=region)
    asg_name = os.getenv('ASG_NAME')

    try:
        asg_client.update_auto_scaling_group(
            AutoScalingGroupName=asg_name,
            MinSize=0,
            DesiredCapacity=0
        )

        print(f"ASG '{asg_name}' reset: MinSize and DesiredCapacity set to 1.")
        return {
            'status': 'success',
            'message': 'ASG reset successfully.'
        }
    except Exception as error:
        print(f"Error resetting ASG: {error}")
        return {
            'status': 'error',
            'message': str(error)
        }
