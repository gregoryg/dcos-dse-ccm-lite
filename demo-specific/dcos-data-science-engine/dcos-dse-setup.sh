#!/bin/bash

set -u

## This script assumes dcos command in path, and cluster to install is default
SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
echo $SCRIPTPATH

# Set extlb to hostname or IP of the public agent load balancer
# extlb=$(terraform output public-agents-loadbalancer)
echo "Public agent loadbalancer is ${extlb}"
PATH=.:$PATH

wait_package_ready () {
    pkg=$1
    status=-99
    for i in {0..10}
    do
        dcos task list ${pkg}
        status=$?
        if [ $status -ne 0 ] ; then
            echo -n .
            sleep 2
        else
            break
        fi
    done
    echo
    if [ $status -ne 0 ] ; then
        echo "Error: Package ${pkg} not installed correctly - exiting"
        exit 1
    fi

    # Wait for task to reach "running" state
    status="-99"
    for i in {0..40}
    do
        status=$(dcos task list --json ${pkg} | jq -r '.[].state' | sort -u)
        if [ "$status" != "TASK_RUNNING" ] ; then
            echo -n .
            sleep 10
        else
            break
        fi
    done
    echo
    if [ "$status" != "TASK_RUNNING" ] ; then
        echo "Error: task ${pkg} has not entered 'running' state - exiting"
        exit 1
    fi
    status=0
} # wait_package_ready()

dcos package install marathon-lb --yes
wait_package_ready "marathon-lb"

dcos package install hdfs --yes
wait_package_ready "hdfs"

# Populate loadbalancer in DC/OS Data Science Engine options - write to current directory
jq -r '.networking.ingress.hostname="'${extlb}'"' ${SCRIPTPATH}/dcos-dse-options.json-template > dcos-dse-options.json
# If AWS S3 credentials are set, update config for use of S3
if [[ -n ${AWS_ACCESS_KEY_ID+x} && -n ${AWS_SECRET_ACCESS_KEY+x} ]] ; then
    jq -r '.storage.s3.aws_access_key_id="aws_access_key_id"' | \
        '.storage.s3.aws_secret_access_key="aws_secret_access_key"' | \
        '.spark.spark_hadoop_fs_s3a_aws_credentials_provider="com.amazonaws.auth.EnvironmentVariableCredentialsProvider"' | \
        '.service.service_account="dsengine_sa"' | \
        '.service.service_account_secret="dsengine_sa"' ${SCRIPTPATH}/dcos-dse-options.json > /tmp/dcos-tmp.json
    mv -v /tmp/dcos-tmp.json ${SCRIPTPATH}/dcos-dse-options.json
fi
dcos package install data-science-engine --options=dcos-dse-options.json --yes
echo 'Wait for data-science-engine task to become ready'
wait_package_ready "data-science-engine"

echo "Now installing initial Jupyter notebook in local storage area"
cat ${SCRIPTPATH}/install-notebooks.sh | dcos task exec -i data-science-engine -- bash
