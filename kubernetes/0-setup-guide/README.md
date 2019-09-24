# Deploying Web Monitoring on a Kubernetes Cluster running on AWS

You need:

* the aws CLI and kubernetes CLI ([install instructions](https://github.com/aws-samples/aws-workshop-for-kubernetes/blob/master/prereqs.adoc#aws-cli-and-kubernetes-cli))
* kops ([install instructions](https://github.com/aws-samples/aws-workshop-for-kubernetes/tree/master/cluster-install#install-kops))
* jq  ([install instructions](https://stedolan.github.io/jq/download/))

If you are trying to deploy changes to EDGI's Kubernetes cluster, you also need:
* to follow our [components guide](components.md)

## Create a new AWS Group and User for managing the cluster.

Log in using AWS using credentials. The account associated with these
credentials must have ``AdministratorAccess``. Choose a region --- in this
example, ``us-west-2``.

```
$ aws configure
AWS Access Key ID [None]: *****
AWS Secret Access Key [None]: *****
Default region name [None]: us-west-2
Default output format [None]:
```

Create a new Group and User that will have sufficient permission to operate the
cluster.

```
aws iam create-group --group-name web-monitoring-kube

aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess --group-name web-monitoring-kube
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonRoute53FullAccess --group-name web-monitoring-kube
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --group-name web-monitoring-kube
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/IAMFullAccess --group-name web-monitoring-kube
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonVPCFullAccess --group-name web-monitoring-kube
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonRDSFullAccess --group-name web-monitoring-kube
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AWSCertificateManagerFullAccess --group-name web-monitoring-kube

aws iam create-user --user-name web-monitoring-kube

aws iam add-user-to-group --user-name web-monitoring-kube --group-name web-monitoring-kube

aws iam create-access-key --user-name web-monitoring-kube
```

The last of these commands will display a new ``AccessKeyId`` and
``SecretAccessKey``. Run ``aws configure`` again using these new credentials.

```
$ aws configure
AWS Access Key ID [****************xxxx]: *****
AWS Secret Access Key [****************xxxx]: *****
Default region name [us-west-2]:
Default output format [None]:
```

Different availability zones for this region can be set in the environment variable AWS_AVAILABILITY_ZONES using the following command:

```
export AWS_AVAILABILITY_ZONES="$(aws ec2 describe-availability-zones --query 'AvailabilityZones[].ZoneName' --output text | awk -v OFS="," '$1=$1')"
```

Echo the value of the environment variable to confirm:

```
$ echo $AWS_AVAILABILITY_ZONES
us-west-1a,us-west-1b,us-west-1c
```

Several command require the region or availability zones to be explicitly
specified as a CLI option. The region is picked based upon the value set in
``aws configure`` command. the environment variable ``$aws_availability_zones``
is used to set the availability zones.

Create an SSH key.

```
$ ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (~/.ssh/id_rsa): ~/.ssh/web-monitoring-kube
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in ~/.ssh/web-monitoring-kube
Your public key has been saved in ~/.ssh/web-monitoring-kube.pub.
The key fingerprint is:
SHA256:bQXH2zAAcFVtpEwcOL5D1QZnXp3zkiC123456789
The key's randomart image is:
+---[RSA 2048]----+
|      ..oo=B**+ +|
|       . o+=B*=+.|
|        +..+*O+E=|
|       . =o=.o=oo|
|        S.*..  o |
|         oo      |
|           .     |
|                 |
|                 |
+----[SHA256]-----+
```

## Create S3 Bucket to store cluster state

Create a bucket an S3 bucket to store cluster state. We include a random string
in the name to ensure uniqueness.

```
export S3_BUCKET=wm-kube-state-store-$(cat /dev/random | LC_ALL=C tr -dc "[:alpha:]" | tr '[:upper:]' '[:lower:]' | head -c 32)
export KOPS_STATE_STORE=s3://${S3_BUCKET}
```

```
# use AWS CLI to create the bucket
$ aws s3 mb $KOPS_STATE_STORE
# enable versioning
$ aws s3api put-bucket-versioning \
  --bucket $S3_BUCKET \
  --versioning-configuration \
  Status=Enabled
```

## Create an AWS Route53 "hosted zone" to manage the cluster's DNS.

Obtain NS records from AWS Route 53.

```
export HOSTED_ZONE=...
```

For example, EDGI's deployment uses ``HOSTED_ZONE=kube.monitoring.envirodatagov.org``.

```
$ ID=$(uuidgen) && aws route53 create-hosted-zone --name $HOSTED_ZONE --caller-reference $ID | jq .DelegationSet.NameServers
[
  "ns-1332.awsdns-38.org",
  "ns-580.awsdns-08.net",
  "ns-217.awsdns-27.com",
  "ns-1542.awsdns-00.co.uk"
]
```

Enter these as NS Records for `kube.monitoring` with the Domain Registrar.
Then, verify that the NS records have propagated.

```
dig ns $HOSTED_ZONE
```

You should see those NS Records in the "ANSWER SECTION" of the output.

## Create a cluster.

This provisions EC2 instances (one master and two workers, by default) and other
cluster resources. Be patient: the command can take awhile to indicate that it is
working.

```
kops create cluster --name $HOSTED_ZONE --zones $AWS_AVAILABILITY_ZONES --yes --ssh-public-key=~/.ssh/web-monitoring-kube.pub --state=$KOPS_STATE_STORE
```

See additional options in kops for controlling the specific zones of the nodes.
``kops update`` can be used to change these options later.

Wait 5-8 minutes and then confirm that the cluster is ready to use:

```
$ kops validate cluster
Using cluster from kubectl context: <HOSTED_ZONE>

Validating cluster <HOSTED_ZONE>

INSTANCE GROUPS
NAME      ROLE  MACHINETYPE MIN MAX SUBNETS
master-us-west-1a Master  m3.medium 1 1 us-west-1a
nodes     Node  t2.medium 2 2 us-west-1a,us-west-1b

NODE STATUS
NAME        ROLE  READY
ip-172-XX-XX-XX.ec2.internal  master  True
ip-172-XX-XX-XX.ec2.internal  node  True
ip-172-XX-XX-XX.ec2.internal  node  True

Your cluster <HOSTED_ZONE> is ready
```

## Enable core metrics.

```
kubectl apply -f kubernetes/kube-system/metrics-server/
```

## Enable logging.

Attach the AWS Managed CloudWatch server policy to the machine roles used by the cluster.

```
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy --role-name nodes.kube.monitoring.envirodatagov.org
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy --role-name masters.kube.monitoring.envirodatagov.org
```

Enable logging.

```
kubectl apply -f kubernetes/kube-system/fluentd/fluentd.configmap.yaml
kubectl apply -f kubernetes/kube-system/fluentd/fluentd.cloudwatch.yaml
```

Events will be logged to a log group called "k8s".

## Set the namespace.

"Namespaces" can be used to run multiple non-interfering deployments using the
same EC2 nodes, such as a production deployment and some number of test
deployments. Here we use the 'default' namespace.

```
export NAMESPACE=default
kubectl set-cluster $HOSTED_ZONE
kubectl config set-context $(kubectl config current-context) --namespace=$NAMESPACE
kubectl config view | grep namespace:
```

## Create services template.

Services provide the network endpoints to access running pods. While most
services contain no sensitive information (and are therefore in version control)
a few web-monitoring services require sensitive information. We provide an
example file with all the necessary keys. The values are to be filled in by
you.

Copy the files and fill values into the copies. (TODO: Provide more guidance
here.)

```
cp examples/services.yaml kubernetes/${NAMESPACE}/services.yaml
```


## RDS

Create a database subnet group and a database instance.

The important options here are:

* Make it publicly accessible.
* Add the security group corresponding to ``nodes.kube.envirodatagov.org``.

```
export DB_INSTANCE_IDENTIFIER=web-monitoring-db-$NAMESPACE
export DB_PASSWORD=$(cat /dev/random | LC_ALL=C tr -dc "[:alpha:]" | tr '[:upper:]' '[:lower:]' | head -c 32)
export NODES_SEC_GROUP=$(aws ec2 describe-security-groups --filters Name=group-name,Values=nodes.$HOSTED_ZONE | jq  -r .SecurityGroups[0].GroupId)
export SUBNETS=$(aws ec2 describe-subnets --filters Name=tag:KubernetesCluster,Values=$HOSTED_ZONE | jq  -r '.Subnets[] | .SubnetId')

# Only need to do this once per cluster (not once per namespace).
aws rds create-db-subnet-group --db-subnet-group-name web-monitoring-db-subnet --db-subnet-group-description "db subnet for all namespaces" --subnet-ids $SUBNETS

aws rds create-db-instance --cli-input-json "$(jq -n -f create-db.jq)"
```

Enter this URI into the ``database_rds`` field in ``kubernetes/${NAMESPACE}/secrets.yaml``:

```
echo -n postgresql://master:$DB_PASSWORD@rds:5432/web_monitoring_db | base64
```

Wait several minutes for the RDS instance to be ready. You may check on its
status like so.

```
aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_IDENTIFIER | jq -r .DBInstances[0].DBInstanceStatus
```

Enter this address into the rds ``externalName`` field in ``kubernetes/${NAMESPACE}/services.yaml``.
(It will be ``null`` until the database is done "creating".)

```
$ aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_IDENTIFIER | jq -r .DBInstances[0].Endpoint.Address
```
## Get SSL certificates.

### Request certificates.

```
export API_ARN=$(aws acm request-certificate --validation-method DNS --domain-name api.$NAMESPACE.$HOSTED_ZONE | jq -r .CertificateArn)
export UI_ARN=$(aws acm request-certificate --validation-method DNS --domain-name ui.$NAMESPACE.$HOSTED_ZONE | jq -r .CertificateArn)
```

### Validate certificates.

Each certifcate requested above provides a CNAME name and value that must be
created to show that we control the domain that we would like to certify.
Obtain this name and value.

```
export API_RES_REC=$(aws acm describe-certificate --certificate-arn $UI_ARN | jq .Certificate.DomainValidationOptions[0].ResourceRecord)
export UI_RES_REC=$(aws acm describe-certificate --certificate-arn $UI_ARN | jq .Certificate.DomainValidationOptions[0].ResourceRecord)
```

Obtain the hosted name ID of our cluster DNS. This is where we will create the
CNAME record.

```
export KUBE_ZONE=$(aws route53 list-hosted-zones-by-name --dns-name "$HOSTED_ZONE." | jq -r '.HostedZones[0].Id')
```

Extract the names and values of the CNAME records we must create.

```
export API_RES_REC=$(aws acm describe-certificate --certificate-arn $API_ARN | jq .Certificate.DomainValidationOptions[0].ResourceRecord)
export UI_RES_REC=$(aws acm describe-certificate --certificate-arn $UI_ARN | jq .Certificate.DomainValidationOptions[0].ResourceRecord)
export API_VALIDATE_NAME=$(echo $API_RES_REC | jq -r .Name)
export API_VALIDATE_VALUE=$(echo $API_RES_REC | jq -r .Value)
export UI_VALIDATE_NAME=$(echo $UI_RES_REC | jq -r .Name)
export UI_VALIDATE_VALUE=$(echo $UI_RES_REC | jq -r .Value)
```

Create the CNAME records.

```
aws route53 change-resource-record-sets --cli-input-json "$(jq -n -f validate-certs.jq)"
```

The record should shortly appear here:

```
aws route53 list-resource-record-sets --hosted-zone-id $KUBE_ZONE | grep $NAMESPACE
```

Validation can take some time after the records have been created, but we may
continue with the rest of the process without waiting for this. Check on the
status like so:

```
aws acm describe-certificate --certificate-arn $API_ARN | jq .Certificate.Status
aws acm describe-certificate --certificate-arn $UI_ARN | jq .Certificate.Status
```

It should at first return ``"PENDING_VALIDATION`` and, when valid, ``ISSUED``.

## Set certificate ARNs in api and ui services.

Enter the values of ``$API_ARN`` and ``$UI_ARN`` into the respective
``service.beta.kubernetes.io/aws-load-balancer-ssl-cert`` fields of
``kubernetes/${NAMESPACE}/services.yaml``.

## Set public api URL in ui configuration.

Update the env var ``WEB_MONITORING_DB_URL`` in ``kubernetes/${NAMESPACE}/ui-deployment.yaml``
to ``api.<NAMESPACE>.<HOSTED_ZONE>``.

## Create secrets.

Secrets are used to store sensitive configuration data such as API keys.
Naturally, the repository does not include these secrets, but it includes
example files with all the necessary keys. The values are to be filled in by
you.

Copy the files and fill values into the copies. (TODO: Provide more guidance
here.)

```
cp examples/secrets.yaml kubernetes/${NAMESPACE}/secrets.yaml
cp examples/ui-secrets.yaml kubernetes/${NAMESPACE}/ui-secrets.yaml
```

## Deploy

First create the namespace.

```
kubectl create namespace $NAMESPACE
```

Next, deploy from the templates.

```
kubectl create -f kubernetes/${NAMESPACE}/secrets.yaml
kubectl create -f kubernetes/${NAMESPACE}/services.yaml
kubectl create -f kubernetes/${NAMESPACE}/api-deployment.yaml
kubectl create -f kubernetes/${NAMESPACE}/redis-master-deployment.yaml
kubectl create -f kubernetes/${NAMESPACE}/redis-slave-deployment.yaml
kubectl create -f kubernetes/${NAMESPACE}/redis-master-service.yaml
kubectl create -f kubernetes/${NAMESPACE}/redis-slave-service.yaml
kubectl create -f kubernetes/${NAMESPACE}/import-worker-deployment.yaml
kubectl create -f kubernetes/${NAMESPACE}/diffing-deployment.yaml
kubectl create -f kubernetes/${NAMESPACE}/diffing-service.yaml
kubectl create -f kubernetes/${NAMESPACE}/ui-secrets.yaml
kubectl create -f kubernetes/${NAMESPACE}/ui-deployment.yaml
```

## Seed database (optional)

```
kubectl get pods --selector=app=api
kubectl exec -it <SOME_API_SERVER_POD_NAME> /bin/bash
bundle exec rake db:migrate
bundle exec rake db:seed
```

## Register subdomains for UI and API.

Which hosted zone are our load balancers in? (This command assumes they are in the same zone.)

```
export ELB_ZONE=$(aws elb describe-load-balancers | jq -r .LoadBalancerDescriptions[0].CanonicalHostedZoneNameID)
```

```
export API_DNS_NAME=api.$NAMESPACE.$HOSTED_ZONE
export UI_DNS_NAME=ui.$NAMESPACE.$HOSTED_ZONE
export API_TARGET=$(kubectl get svc api -o json | jq -r .status.loadBalancer.ingress[0].hostname)
export UI_TARGET=$(kubectl get svc ui -o json | jq -r .status.loadBalancer.ingress[0].hostname)
```

```
aws route53 change-resource-record-sets --cli-input-json "$(jq -n -f create-ingress-alias.jq)"
```

## Success?

You may still need to wait at this point if the certificates have not processed.

Visit ``https://ui.$NAMESPACE.$HOSTED_ZONE``. If you seeded
the database above, you can log in with ``seed-admin@example.com`` /
``PASSWORD``.


## Deploying configuration changes.

If you update the secrets used in a deployment, but haven't changed the deployment itself, kubernetes will not apply the new secrets when you redeploy. Rather than delete and recreating the deployment, you can change the value of the ``INCREMENTAL_UPDATE`` within the affected deployement and then run ``kubectl replace -f kubernetes/${NAMESPACE}/example-deployment.yaml``. Since the deployment is now different, kubernetes will perform the rolling update as desired, with your new secret values.

## Troubleshooting

### Verify that RDS is accessible.

```
$ kubectl get pods
$ kubectl exec -it <ANY_POD> /bin/bash
```

In the pod:

```
root@some_pod$ apt-get install telnet
root@some_pod$ telnet rds 5432
```

If that fails to quickly connect, the RDS security settings may be incorrect.
Check that the RDS is publicly accessible and that the security groups
``masters.kube....`` and ``nodes.kube....`` have been added.

### References

* https://kubernetes.io/docs/reference/kubectl/cheatsheet/
* https://kubernetes.io/docs/tutorials/kubernetes-basics/
* https://github.com/aws-samples/aws-workshop-for-kubernetes/tree/master/developer-concepts
