#/******************************************************************************
# * docker-elk                                                                 *
# * Dockerfile for Elasticsearch, Logstash, Kibana based on Centos7            *
# * Maintained by Govindaraj Venkatesan                                        * 
# * Email: govindaraj.kct@gmail.com                                            *
# *                                                                            *
# ******************************************************************************/

FROM centos:centos7

MAINTAINER Govindaraj Venkatesan

#upgrading system and install required utilities
RUN yum -y install epel-release; \ 
    yum -y install wget openssh-server supervisor httpd openssh-client openssl  which; \
    mkdir -p /var/run/sshd; \ 
    mkdir -p /var/log/supervisor;

#download and install java
RUN wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u73-b02/jdk-8u73-linux-x64.rpm -O /tmp/jdk-8u73-linux-x64.rpm; \
    yum -y install /tmp/jdk-8u73-linux-x64.rpm; \
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/java; \
    export JAVACMD=`which java;

#download and install elasticsearch_v2.3.1
RUN wget https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/rpm/elasticsearch/2.3.1/elasticsearch-2.3.1.rpm -O /tmp/elasticsearch-2.3.1.rpm; \
    yum -y install /tmp/elasticsearch-2.3.1.rpm;

#download and install logstash_v2.3.1
RUN wget https://download.elastic.co/logstash/logstash/packages/centos/logstash-2.3.1-1.noarch.rpm -O /tmp/logstash-2.3.1-1.noarch.rpm; \
    yum -y install /tmp/logstash-2.3.1-1.noarch.rpm;

#download and install kibana_v4.5.0
RUN wget https://download.elastic.co/kibana/kibana/kibana-4.5.0-1.x86_64.rpm -O /tmp/kibana-4.5.0-1.x86_64.rpm; \
    yum -y install /tmp/kibana-4.5.0-1.x86_64.rpm; 
   
#clean all the temporary files and yum cache
RUN rm -rf /tmp/jdk-8u73-linux-x64.rpm; \
    rm -rf /tmp/elasticsearch-2.3.1.rpm; \
    rm -rf /tmp/logstash-2.3.1-1.noarch.rpm; \
    rm -rf /tmp/kibana-4.5.0-1.x86_64.rpm; \
    yum clean all; 

# includes supervisor config
ADD content/ /

#certs/keys for Filebeats and Logstash (wip)
ADD ssl/logstash-forwarder.key /etc/pki/tls/private/logstash-forwarder.key
ADD ssl/logstash-forwarder.crt /etc/pki/tls/certs/logstash-forwarder.crt

#add logstash config
ADD logstash/ /etc/logstash/conf.d/

#update kibana.yml config
RUN sed -i 's/# server.host: "0.0.0.0"/server.host: "0.0.0.0"/g' /opt/kibana/config/kibana.yml; \
    mkdir -p /var/log/kibana;

ADD start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

#expose ports
EXPOSE 22 80 5601 9200 9300 5000 5044

#expose volume
VOLUME /var/lib/elasticsearch

#start the init
CMD [ "/usr/local/bin/start.sh" ] 

