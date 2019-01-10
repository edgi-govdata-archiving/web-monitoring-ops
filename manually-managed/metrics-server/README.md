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

2. Log in.
   ```
   ssh-add /keybase/team/edgi_wm_kube/web-monitoring-services-keys
   ssh ubuntu@<PUBLIC_IP>
   sudo su
   ```
3. Install Debian packages.

   ```
   apt-get update
   apt-get install openjdk-8-jdk
   apt-get install apt-transport-https
   wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
   echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list
   apt-get install elasticsearch kibana nginx
   ```

4. Start elasticsearch, check that the logs look happy and that you can get a
   response.

   ```
   systemctl daemon-reload
   systemctl enable elasticsearch.service
   systemctl start elasticsearch.service

   tail -f  /var/log/elasticsearch/elasticsearch.log 
   curl http://localhost:9200
   ```

5. Start Kibana, and curl a response.

   ```
   systemctl daemon-reload
   systemctl enable kibana.service
   systemctl start kibana.service
   curl -v http://localhost:5601/app/kibana
   ```

4. Start nginx.

   ```
   systemctl daemon-reload
   systemctl enable nginx.service
   systemctl start nginx.service
   ```

5. Upload ``kibana`` and ``elasticsearch`` nginx config, stored under ``nginx/``
   beside this ``README`` file into ``/etc/nginx/sites-available``.

6. Create soft-links from ``sites-enabled`` to ``sites-available``. Reload nginx
   configuration.


   ```
   ln -s -T /etc/nginx/sites-available/kibana /etc/nginx/sites-enabled/kibana
   ln -s -T /etc/nginx/sites-available/elasticsearch /etc/nginx/sites-enabled/elasticsearch
   nginx -s reload
   ```

## ELBs

7. Create an external-facing ELB pointed at this VM with a  listener ("target
   group") named ``elasticsearch`` and add the VM as a target.

8. Create an internal ELB with a listener ("target group") named
   ``elasticsearch-internal`` and add the VM as a target.

## DNS

9. Add a A ALIAS record for ``kibana.kube.monitoring.envirodatagov.org`` aimed
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
