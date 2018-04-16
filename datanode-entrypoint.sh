#!/bin/bash

: ${HADOOP_PREFIX:=/usr/local/hadoop}

$HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

/bin/rm -rf /tmp/*.pid

# Get the namenode hostname & configure 
if [ -z $HADOOP_HOST_NAMENODE ]; then 
   HADOOP_HOST_NAMENODE=namenode;
 echo "No namenode passed, setting short hostname to namenode. Set env variable for HADOOP_HOST_NAMENODE to change namenode hostname.";
fi

if [ ! -e  $HADOOP_PREFIX/etc/hadoop/core-site.xml ]
then
        echo "Changing Hostname in core-site.xml"
        sed s/HOSTNAME/$HADOOP_HOST_NAMENODE/ $HADOOP_PREFIX/etc/hadoop/core-site.xml.template > $HADOOP_PREFIX/etc/hadoop/core-site.xml
else
        echo "core-site.xml exists: "
        cat $HADOOP_PREFIX/etc/hadoop/core-site.xml
fi

# Checks for first boots & hostname configs

# Configure Resource Manager - YARN
if [ -z $HADOOP_HOST_YARN ]; then
     HADOOP_HOST_YARN=yarn;
     echo "No Resource Manager passed, setting short hostname to yarn. Set env variable for HADOOP_HOST_YARN to change yarn hostname.";
fi

echo "CHECKING HADOOP/YARN-SITE.XML"
if [ ! -e  $HADOOP_PREFIX/etc/hadoop/yarn-site.xml ]
then
  	echo "Changing Hostname in yarn-site.xml"
	sed s/HOSTNAME/$HADOOP_HOST_YARN/ $HADOOP_PREFIX/etc/hadoop/yarn-site.xml.template > $HADOOP_PREFIX/etc/hadoop/yarn-site.xml
else
	# we resumed the container and config data is presistence
	echo "Found an existing yarn-site.xml file."
	echo "yarn-site.xml: "
	cat $HADOOP_PREFIX/etc/hadoop/yarn-site.xml
fi

# Change Yarn & history server hostname in mapred-site.xml
if [ ! -e  $HADOOP_PREFIX/etc/hadoop/mapred-site.xml ]
then
    echo "Changing Hostname in mapred-site.xml"
    sed s/HOSTNAME/$HADOOP_HOST_YARN/ $HADOOP_PREFIX/etc/hadoop/mapred-site.xml.template > $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
else
    echo "mapred-site.xml: "
    cat $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
fi

# Start the datanode daemon
$HADOOP_PREFIX/sbin/hadoop-daemon.sh start datanode
# Start nodemanager
$HADOOP_PREFIX/sbin/yarn-daemon.sh start nodemanager

# Start SSHD 
echo "Starting sshd"
exec /usr/sbin/sshd -D

if [[ $1 == "-d" ]]; then
  while true; do sleep 1000; done
fi

