#!/bin/bash
# TODO: externalize dcos package install/config to demo-installers
SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

eval `ssh-agent -s` > /dev/null 2>&1
ssh-add /home/ec2-user/SE-UI-Toolkit/resources/ssh_private_key.pem > /dev/null 2>&1
masterip=($(terraform output masters-ips | head -n1 | cut -d ',' -f1))
export extlb=$(terraform output public-agents-loadbalancer)
jupyter_password=$(jq -r '.service.jupyter_password' ${SCRIPTPATH}/dcos-dse-options.json-template)

export PATH=$(pwd):$PATH
curl https://downloads.dcos.io/binaries/cli/linux/x86-64/dcos-1.13/dcos -o dcos
chmod 755 dcos
dcos cluster setup --no-check --insecure https://$(terraform output cluster-address) --username=bootstrapuser --password=deleteme

${SCRIPTPATH}/dcos-dse-setup.sh

echo -e "Your cluster details are here:\n" > outputemail
echo $(terraform output) >> outputemail
echo -e "\nYour initial JupyterLab workspace is at https://${extlb}/service/data-science-engine/" >> outputemail
echo -e "Initial workspace password is '"${jupyter_password}"'" >> outputemail
echo -e "   Customer churn analysis notebook is in the jupyter_lab/ds-for-telco directory in Jupyter" >> outputemail
echo -e "   Look at github.com/gregoryg and github.com/mesosphere/jupyter-service for additional notebooks\n" >> outputemail
echo -e "SE Demo setup video (unlisted YouTube link): https://youtu.be/mjuUMpAcTnQ\n"

echo 'DC/OS Data Science Engine Demo installation complete!'
