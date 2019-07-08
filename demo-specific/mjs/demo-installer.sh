#!/bin/bash
# TODO: externalize dcos package install/config to demo-installers
# TODO: check for task running: dcos task --json jupyter|jq -r '.[].state'
currentdir=$(pwd)
dcosdir=$currentdir/dcosconfig
export DCOS_DIR=$dcosdir
eval `ssh-agent -s` > /dev/null 2>&1
ssh-add /home/ec2-user/SE-UI-Toolkit/resources/ssh_private_key.pem > /dev/null 2>&1
masterip=($(terraform output masters-ips | head -n1 | cut -d ',' -f1))
extlb=$(terraform output public-agents-loadbalancer)

# cp -r /home/ec2-user/demo-installers/mjs .
# cd mjs
export PATH=$(pwd):$PATH
curl https://downloads.dcos.io/binaries/cli/linux/x86-64/dcos-1.13/dcos -o dcos
chmod 755 dcos
dcos cluster setup --no-check https://$(terraform output cluster-address) --username=bootstrapuser --password=deleteme

dcos package install marathon-lb --yes
dcos package install hdfs --yes

# Populate loadbalancer in MJS options
jq -r '.networking.ingress.hostname="'${extlb}'"' ./mjs-options.json-template > mjs-options.json
dcos package install beta-mesosphere-jupyter-service --options=mjs-options.json --yes

for i in {0..10}
do
    dcos task jupyter
    if [ $? -ne 0 ] ; then
        echo -n .
        sleep 2
    else
        break
    fi
done
echo

echo 'Waiting for Jupyter task to become available'
for i in {0..20}
do
    status=$(dcos task --json jupyter | jq -r '.[].state')
    if [ "$status" != "TASK_RUNNING" ] ; then
       echo -n .
       sleep 20
    else
        break
    fi
done
echo
if [ "$status" != "TASK_RUNNING" ] ; then
    echo "Jupyter task is not running - cannot install notebookes (last status: ${status})"
    exit 1
fi

cat install-notebooks.sh | dcos task exec -i jupyter -- bash

# . ./install-ccmlite.sh https://$masterip
cd $currentdir

echo -e "\nYour cluster details are here:\n" > outputemail
echo $(terraform output) >> outputemail
echo -e "\nYour initial JupyterLab workspace is at https://${extlb}/jupyter\n\n" >> outputemail
# echo -e "\n*******************   Resources   *******************\n" >> outputemail
# echo -e "Repo and demo script" >> outputemail
# echo -e "https://github.com/mesosphere/se-demo/tree/master/mjs" >> outputemail
