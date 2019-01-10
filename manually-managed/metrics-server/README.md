# Provisioning and Configuring the Metrics Server

## Overview

* One VM running elasticsearch, kibana, and nginx --- all installed via Debian
  packages and managed with systemd.
* One externally-facing ELB serving Kibana.
* One interal ELB ingesting data into elasticserach. 

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
   echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list
   apt-get install elasticsearch kibana nginx
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

12. Create soft-links from ``sites-enabled`` to ``sites-available``. Reload nginx
   configuration.


   ```
   ln -s -T /etc/nginx/sites-available/kibana /etc/nginx/sites-enabled/kibana
   ln -s -T /etc/nginx/sites-available/elasticsearch /etc/nginx/sites-enabled/elasticsearch
   nginx -s reload
   ```

## ELBs

13. Create an external-facing ELB pointed at this VM with a  listener ("target
   group") named ``elasticsearch`` and add the VM as a target.

14. Create an internal ELB with a listener ("target group") named
   ``elasticsearch-internal`` and add the VM as a target.

## DNS

15. Add a A ALIAS record for ``kibana.kube.monitoring.envirodatagov.org`` aimed
   at the external-facing ELB.

## Verify

Once DNS propagates, http://kibana.kube.monitoring.envirodatagov.org should load
a public Kibana dashboard.

The URL of the internal VM should be accessible from inside the kube VPC, and it
should accept a request such as

```
curl -X "POST" http://<PRIVATE_DNS>/test/_doc/1 -d '{"hello": "world"}' -H "Content-Type: application/json" 
```

## TO DO

* Separate storage volume for elastic indexes, with backups
* Put all services onto one VPC so they can send metrics to elasticserach
