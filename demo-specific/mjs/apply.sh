if [ -z "$1" ]; then
        AWS_ACCOUNT=110465657741_Mesosphere-PowerUser
else
        AWS_ACCOUNT=$1
fi

ssh-add /home/ec2-user/SE-UI-Toolkit/resources/ssh_private_key.pem > /dev/null 2>&1
eval $(maws login 110465657741_Mesosphere-PowerUser)
terraform init
terraform plan -out=plan.out
terraform apply plan.out
