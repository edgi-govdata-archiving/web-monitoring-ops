{
    "HostedZoneId": env.KUBE_ZONE,
    "ChangeBatch": {
        "Comment": "validate certificates for rails server and ui",
        "Changes": [
            {
                "Action": "CREATE",
                "ResourceRecordSet": {
                    "Name": env.API_VALIDATE_NAME,
                    "Type": "CNAME",
                    "TTL": 300,
                    "ResourceRecords": [
                        {
                            "Value": env.API_VALIDATE_VALUE
                        }
                    ],
                }
            },
            {
                "Action": "CREATE",
                "ResourceRecordSet": {
                    "Name": env.UI_VALIDATE_NAME,
                    "Type": "CNAME",
                    "TTL": 300,
                    "ResourceRecords": [
                        {
                            "Value": env.UI_VALIDATE_VALUE
                        }
                    ],
                }
            }
        ]
    }
}
