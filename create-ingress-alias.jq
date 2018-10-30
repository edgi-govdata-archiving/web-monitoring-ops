{
HostedZoneId: env.KUBE_ZONE,
ChangeBatch:
    {
    Comment: "create subdomains for rails server and ui",
    Changes: [
            {
            Action: "UPSERT",
            ResourceRecordSet: {
                Name: env.API_DNS_NAME,
                Type: "A",
                AliasTarget: {
                    DNSName: env.API_TARGET,
                    EvaluateTargetHealth: false,
                    HostedZoneId: env.ELB_ZONE
                    }
                }
            },
            {
            Action: "UPSERT",
            ResourceRecordSet: {
                Name: env.UI_DNS_NAME,
                Type: "A",
                AliasTarget: {
                    DNSName: env.UI_TARGET,
                    EvaluateTargetHealth: false,
                    HostedZoneId: env.ELB_ZONE
                    }
                }
            }
        ]
    }
}
