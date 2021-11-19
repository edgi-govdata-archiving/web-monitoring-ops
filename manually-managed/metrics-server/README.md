# Provisioning and Configuring the Metrics Server

## Overview

* One VM runs elasticsearch, kibana, and nginx --- all installed via Debian
  packages and managed with systemd.
* One externally-facing ELB serves kibana and elasticsearch
* Kibana is fully public. No sensitive data will be stored there.
* Elasticsearch requires authentication, so only authorized services can submit
  data. (Kibana can access elasticsearch locally without authentication because
  they run on the same host.) required to submit data.
* The indexes from elasticsearch are stored on an EBS volume with regular
  backups.

## VM

1. Provision at t2 medium with Ubuntu. Add to the kube VPC and the
   ``elasticsearch`` security group, allowing HTTP traffic. Use the
   ``web-monitoring-services-keys``.

2. Create a 128GiB EBS volume and attach it to the instance.

3. Log in.

   ```
   ssh-add /keybase/team/edgi_wm_kube/web-monitoring-services-keys
   ssh ubuntu@<PUBLIC_IP>
   sudo su
   ```

4. Make the second volume avaialble for use and verify.
   ```
   mkfs -t ext4 /dev/xvdf
   mkdir /var/data
   echo "UUID=$(ls -l /dev/disk/by-uuid/ | grep xvdf | cut -d ' ' -f 9)   /var/data        ext4   defaults,discard        0">>/etc/fstab
   mount -a
   df -h
   ```

5. Install Debian packages.

   ```
   apt-get update
   apt-get install openjdk-8-jdk
   apt-get install apt-transport-https
   wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
   echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-6.x.list
   apt-get update
   apt-get install apache2-utils elasticsearch kibana nginx
   ```

6. Create elasticsearch data directory and set permissions.

   ```
   mkdir /var/data/elasticsearch
   chown -R elasticsearch:elasticsearch /var/data/elasticsearch
   chmod 755 /var/data/elasticsearch
   ```

7. Configure elasticsearch to use the new directory.

   ```
   sed -i 's#/var/lib/elasticsearch#/var/data/elasticsearch#g' /etc/elasticsearch/elasticsearch.yml
   ```


8. Start elasticsearch, check that the logs look happy and that you can get a
   response.

   ```
   systemctl daemon-reload
   systemctl enable elasticsearch.service
   systemctl start elasticsearch.service

   tail -f  /var/log/elasticsearch/elasticsearch.log 
   curl http://localhost:9200
   ```

9. Start Kibana, and curl a response.

   ```
   systemctl daemon-reload
   systemctl enable kibana.service
   systemctl start kibana.service
   curl -v http://localhost:5601/app/kibana
   ```

10. Start nginx.

   ```
   systemctl daemon-reload
   systemctl enable nginx.service
   systemctl start nginx.service
   ```

11. Upload ``kibana`` and ``elasticsearch`` nginx config, stored under ``nginx/``
   beside this ``README`` file into ``/etc/nginx/sites-available``.

12. Create a basic auth user for elasticsearch authentication

   ```
   htpasswd -c /etc/nginx/.htpasswd <someusername>
   ```

13. Create soft-links from ``sites-enabled`` to ``sites-available``. Reload nginx
   configuration.


   ```
   ln -s -T /etc/nginx/sites-available/kibana /etc/nginx/sites-enabled/kibana
   ln -s -T /etc/nginx/sites-available/elasticsearch /etc/nginx/sites-enabled/elasticsearch
   nginx -s reload
   ```

14. Enable backups for the EBS volume storing the elasticache indexes as described in the [Schedule Automated Amazon EBS Snapshots Tutorial](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/TakeScheduledSnapshot.html)

## ELBs

15. Create an external-facing ELB pointed at this VM with a  listener ("target
   group") named ``elasticsearch`` and add the VM as a target.

## DNS

17. Create two A ALIAS records, for ``kibana.kube.monitoring.envirodatagov.org``
    and ``elasticsearch.kube.monitoring.envirodatagov.org`` respectively, both
    aimed at the ELB.

## Verify

Once DNS propagates, http://kibana.kube.monitoring.envirodatagov.org should load
a public Kibana dashboard, and

```
curl -u <USER>:<PASSWORD> elasticsearch.kube.monitoring.envirodatagov.org
```

should return JSON from elasticserach. And it should be possible to submit data
like so:

```
curl -u <USER>:<PASSWORD> -X "POST" http://elasticsearch.kube.monitoring.envirodatagov.org/test/_doc/1 -d '{"hello": "world"}' -H "Content-Type: application/json"
```
