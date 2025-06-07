import boto3
import os

ec2 = boto3.client('ec2')

def lambda_handler(event, context):
    action = event['ACTION']
    instance_ids = event['INSTANCE_IDS'].split(',')

    if action == 'start':
        ec2.start_instances(InstanceIds=instance_ids)
        print(f'Started instances: {instance_ids}')
    elif action == 'stop':
        ec2.stop_instances(InstanceIds=instance_ids)
        print(f'Stopped instances: {instance_ids}')
