{
    DBName: "web_monitoring_db",
    AllocatedStorage: 20,
    DBInstanceClass: "db.t2.medium",
    Engine: "postgres",
    MasterUserPassword: env.DB_PASSWORD,
    DBInstanceIdentifier: env.DB_INSTANCE_IDENTIFIER,
    MasterUsername: "master",
    PubliclyAccessible: true,
    VpcSecurityGroupIds: [env.NODES_SEC_GROUP],
    DBSubnetGroupName: "web-monitoring-db-subnet"
}
