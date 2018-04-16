FROM centos:7

MAINTAINER Portworx

USER root

RUN yum install -y curl tar sudo which openssh-server openssh-clients rsync 

#  TEMP stuff
#RUN yum install -y net-tools telnet

# SSH and user equivalence
RUN rm -f /etc/ssh/ssh_host_ecdsa_key /etc/ssh/ssh_host_rsa_key && \
    ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_ecdsa_key && \
    ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key && \
    ssh-keygen -q -N "" -t ed25519 -f /etc/ssh/ssh_host_ed25519_key && \ 
    sed -i "s/#UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config

RUN mkdir -p /root/.ssh
COPY id_rsa /root/.ssh/id_rsa
COPY id_rsa.pub /root/.ssh/id_rsa.pub
COPY id_rsa.pub /root/.ssh/authorized_keys
COPY ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config && chown root:root /root/.ssh/config

# java
RUN curl -LO 'https://mirror.its.sfu.ca/mirror/CentOS-Third-Party/NSG/common/x86_64/jdk-8u144-linux-x64.rpm' && rpm -i jdk-8u144-linux-x64.rpm && rm jdk-8u144-linux-x64.rpm

ENV JAVA_HOME /usr/java/default

RUN curl -s http://www.us.apache.org/dist/hadoop/common/hadoop-2.7.5/hadoop-2.7.5.tar.gz | tar -xz -C /usr/local/ && \
	cd /usr/local && \
	ln -s ./hadoop-2.7.5 hadoop

ENV HADOOP_PREFIX /usr/local/hadoop
ENV HADOOP_COMMON_HOME /usr/local/hadoop
ENV HADOOP_HDFS_HOME /usr/local/hadoop
ENV HADOOP_MAPRED_HOME /usr/local/hadoop
ENV HADOOP_YARN_HOME /usr/local/hadoop
ENV HADOOP_CONF_DIR /usr/local/hadoop/etc/hadoop
ENV YARN_CONF_DIR $HADOOP_PREFIX/etc/hadoop

ENV HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop
ENV JAVA_HOME=/usr/java/default

# commented out for now..
RUN mkdir $HADOOP_PREFIX/input $HADOOP_PREFIX/logs && cp $HADOOP_PREFIX/etc/hadoop/*.xml $HADOOP_PREFIX/input && chmod +x $HADOOP_PREFIX/etc/hadoop/*.sh

# remove these - we need to set the hostname of the instance in this file
RUN rm -f $HADOOP_PREFIX/etc/hadoop/yarn-site.xml $HADOOP_PREFIX/etc/hadoop/core-site.xml $HADOOP_PREFIX/etc/hadoop/mapred-site.xml

# Copy modified XML and other config files to /etc/hadoop
ADD hdfs-site.xml $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml
ADD core-site.xml.template $HADOOP_PREFIX/etc/hadoop/core-site.xml.template
ADD yarn-site.xml.template $HADOOP_PREFIX/etc/hadoop/yarn-site.xml.template
ADD mapred-site.xml.template $HADOOP_PREFIX/etc/hadoop/mapred-site.xml.template

#MORE TEMP STUFF
#COPY log4j.properties.temp $HADOOP_PREFIX/etc/hadoop/log4j.properties

########## 

# create data
RUN mkdir -p /hdfs/volume1

VOLUME /hdfs/volume1

# Expose Ports
# SSHD
EXPOSE 22
# dfs.datanode.*
EXPOSE 50010 50020 50075
# node manager ports
EXPOSE 8040 8042

COPY datanode-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
