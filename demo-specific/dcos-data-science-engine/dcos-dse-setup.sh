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
        dcos task ${pkg}
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
        status=$(dcos task --json ${pkg} | jq -r '.[].state' | sort -u)
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

dcos package install beta-mesosphere-jupyter-service --options=dcos-dse-options.json --yes
echo 'Wait for jupyter task to become ready'
wait_package_ready "jupyter"

echo "Now installing initial Jupyter notebook in local storage area"
cat ${SCRIPTPATH}/install-notebooks.sh | dcos task exec -i jupyter -- bash