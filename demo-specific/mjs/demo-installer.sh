#!/bin/bash
# TODO: externalize dcos package install/config to demo-installers
# TODO: check for task running: dcos task --json jupyter|jq -r '.[].state'
SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

eval `ssh-agent -s` > /dev/null 2>&1
ssh-add /home/ec2-user/SE-UI-Toolkit/resources/ssh_private_key.pem > /dev/null 2>&1
masterip=($(terraform output masters-ips | head -n1 | cut -d ',' -f1))
export extlb=$(terraform output public-agents-loadbalancer)

# cp -r /home/ec2-user/demo-installers/mjs .
# cd mjs
export PATH=$(pwd):$PATH
curl https://downloads.dcos.io/binaries/cli/linux/x86-64/dcos-1.13/dcos -o dcos
chmod 755 dcos
dcos cluster setup --no-check https://$(terraform output cluster-address) --username=bootstrapuser --password=deleteme

${SCRIPTPATH}/mjs-setup.sh

echo -e "\nYour cluster details are here:\n" > outputemail
echo $(terraform output) >> outputemail
echo -e "\nYour initial JupyterLab workspace is at https://${extlb}/jupyter\n\n" >> outputemail
# echo -e "\n*******************   Resources   *******************\n" >> outputemail
# echo -e "Repo and demo script" >> outputemail
# echo -e "https://github.com/mesosphere/se-demo/tree/master/mjs" >> outputemail
