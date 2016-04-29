#elk docker:

Dockerize Elasticsearch, Logstash, and Kibana (ELK Stack) on CentOS 7.


#Our Goal:

The goal of the project is to set up a dockerized version of Logstash to gather syslogs of multiple servers, and set up Kibana to visualize the gathered logs.

 ELK stack docker setup has four main components:

* Logstash: The server component of Logstash that processes incoming logs
* Elasticsearch: Stores all of the logs
* Kibana: Web interface for searching and visualizing logs, which will be proxied through haproxy.
* Filebeat: Installed on client servers that will send their logs to Logstash.



#Versions:

* Java: jdk-8u45-linux-x64.rpm
* Elastic Search: elasticsearch-2.3.1.rpm
* Logstash: logstash-2.3.1-1.noarch.rpm
* Kibana: kibana-4.5.0-1.x86_64.rpm

#Usage:

1) Clone the elk-docker repo
   
```
 git clone https://github.com/gvenka008c/elk-docker.git
```

2) To build the docker image from Dockerfile, follow the below steps

```
 #cd gvenka008c/elk-docker
 # docker build -t elk-docker .
```

3) To view the images, use the docker images command as show below

```
  # docker images
    REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
    elk-docker          latest              178b87aa072e        21 hours ago        1.368 GB
```

4) To start the elk docker container, use the below steps

```
   #docker run -d -ti --name elk-docker -p 5601:5601 -p 9200:9200 -p 5044:5044 -p 5000:5000 elk-docker
```

5) To view the running containers, run the docker ps command

``` 
  # docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                                                                                                                      NAMES
08acb439ba43        elk-docker          "/usr/local/bin/start"   21 hours ago        Up 21 hours         22/tcp, 0.0.0.0:5000->5000/tcp, 0.0.0.0:5044->5044/tcp, 0.0.0.0:5601->5601/tcp, 80/tcp, 9300/tcp, 0.0.0.0:9200->9200/tcp   elk-docker
```

6) To connect to the running container, use docker exec command as below

```
  # docker exec -it <container> /bin/bash
```

7) To stop the container and remove the container, use the below commands

```
 # docker stop <container>
 # docker rm -v <container>
```

#kibana:

Kibana GUI can be accessed using the URL http://elk_server_hostname:5601 or http://elk_server_ip_address:5601 based on the setup.

#Ports

Ports that are exposed are

```
  Port     Service
  5601     Kibana web interface
  5044     Logstash Beats interface, receives logs from Beats such as Filebeat
  5000     Logstash Lumberjack interface, receives logs from Logstash forwarders
  9200     Elasticsearch JSON interface
```


#Generate SSL Certificates

As we are using Filebeat to ship logs from our Client Servers to our ELK Server, we need to create an SSL certificate and key pair. The certificate is used by Filebeat to verify the identity of ELK Server. 

 We will use ELK Server's private IP address to the subjectAltName (SAN) field of the SSL certificate that we are about to generate. To do so, open the OpenSSL configuration file and ensure v3_ca has the below updated

```

#vi /etc/pki/tls/openssl.cnf

[ v3_ca ]
subjectAltName = IP: elk_server_ip_address

```

Now generate the SSL certificate and private key in the appropriate locations (/etc/pki/tls/)

```
#cd /etc/pki/tls
#sudo openssl req -config /etc/pki/tls/openssl.cnf -x509 -days 3650 -batch -nodes -newkey rsa:2048 -keyout private/logstash-forwarder.key -out certs/logstash-forwarder.crt

```

Below keys will be generated after running the openssl command

```
#/etc/pki/tls/private/logstash-forwarder.key
#/etc/pki/tls/certs/logstash-forwarder.crt  => The logstash-forwarder.crt file will be copied to all of the servers that will send logs to Logstash.

```

#SSL Certificate based on FQDN(DNS):

Assuming that our hosts are reachable from your log producers under the names host1.some.domain, host2.some.domain (i.e. with a common .some.domain suffix) etc., the easiest would be to generate certificates with CN=*.some.domain as the suffix beforehand, i.e.:

```
#cd /etc/pki/tls
#sudo openssl req -x509 -batch -nodes -subj "/CN=*.some.domain/" \
    -days 3650 -newkey rsa:2048 \
    -keyout private/logstash-forwarder.key -out certs/logstash-forwarder.crt
```

#Set Up Filebeat on client servers:

1) Copy the logstash-forwarder.crt file created before to all of the client servers that will send logs to Logstash.

2) Install filbeat package.

```

#sudo rpm --import http://packages.elastic.co/GPG-KEY-elasticsearch
#sudo yum -y install filebeat
```

3) Configure filebeat.yml as per the project needs

```
sudo vi /etc/filebeat/filebeat.yml

```



4) Now start and enable Filebeat to put our changes into place

```
#sudo systemctl start filebeat
#sudo systemctl enable filebeat

```

5) On your ELK Server, verify that Elasticsearch is indeed receiving the data by querying for the Filebeat index with this command:

```
#curl -XGET 'http://localhost:9200/filebeat-*/_search?pretty'

```
