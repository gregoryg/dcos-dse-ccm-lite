#!/bin/bash
cd ~
mkdir -p projects
cd projects
git clone https://github.com/gregoryg/ds-for-telco.git
# export JAVA_HOME=/opt/jdk
# export HADOOP_CONF_DIR=/mnt/mesos/sandbox
# export PATH=$PATH:/opt/conda/bin:/opt/jdk/bin:/opt/spark/bin:/opt/hadoop/bin:/opt/mesosphere/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
# hdfs dfsadmin -safemode wait

# hdfs dfs -mkdir -p /user/nobody/data
# hdfs dfs -put ds-for-telco/data/churn.all /user/nobody/data/
# Bring in notebooks included for internal testing
# TODO get permission to host these notebooks on a public repo
# wget 'https://github.com/mesosphere/jupyter-service/blob/master/notebooks/BeakerX-DCOS-Spark.ipynb'
# wget 'https://github.com/mesosphere/jupyter-service/blob/master/notebooks/Ray-WebUI.ipynb'
# wget 'https://github.com/mesosphere/jupyter-service/blob/master/notebooks/TFoS.ipynb'
