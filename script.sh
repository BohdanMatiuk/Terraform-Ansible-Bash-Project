#!/bin/bash

function prepare_bastion() {
    sudo apt update
    sudo apt install ansible -y
    if [ ! -f /usr/share/keyrings/hashicorp-archive-keyring.gpg ]
    then
        wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    fi
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install terraform
}
prepare_bastion

function create_instance() {
    cd terraform
    terraform init
    terraform apply --auto-approve
}
create_instance

function terraform_output() {
    terraform output -json > output.json
    sudo apt-get install jq -y
    ec2_ip=$(jq -r '.ec2.value' output.json)
    cat <<EOF > ../ansible/hosts.yml
vm ansible_host=${ec2_ip}
EOF
}
terraform_output
sleep 20

# function terraform_output() {
#     IP=$(terraform output -raw ec2)
#     sed -i "s/ansible_host=[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}/ansible_host=$IP/" ../ansible/hosts
# }
# terraform_output

function ansible() {
    cd ../ansible
    ansible-playbook main.yml
}
ansible
