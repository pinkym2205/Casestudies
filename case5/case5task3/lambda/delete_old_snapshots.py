import boto3
from datetime import datetime, timezone, timedelta

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    today = datetime.now(timezone.utc)
    retention_days = 14
    deleted = 0

    snapshots = ec2.describe_snapshots(OwnerIds=['self'])['Snapshots']
    print(f"Found {len(snapshots)} snapshots")

    for snapshot in snapshots:
        snapshot_id = snapshot['SnapshotId']
        start_time = snapshot['StartTime']
        age = (today - start_time).days

        print(f"Checking snapshot {snapshot_id}, Age: {age} days")

        if age >retention_days:
            print(f"Deleting snapshot: {snapshot_id} (Age: {age} days)")
            ec2.delete_snapshot(SnapshotId=snapshot_id)
            deleted += 1

    print(f"Deleted {deleted} snapshots older than {retention_days} days.")

    return {
        'statusCode': 200,
        'body': f"Deleted {deleted} snapshots older than {retention_days} days."
    }
