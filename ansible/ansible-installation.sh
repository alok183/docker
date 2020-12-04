#!bin/bash

apt update -y
apt install software-properties-common -y
apt-add-repository --yes --update ppa:ansible/ansible
apt install ansible -y
mkdir -p /ansible/playbook
cat > /ansible/playbook/playbook.yaml <<EOF
- hosts: localhost
  tasks:
  - name: site | hello world
    shell: echo "Hi! Ansible is working"
EOF
ansible-playbook /ansible/playbook/playbook.yaml
# ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa <<<y 2>&1 >/dev/null
# cd  ~/.ssh
# chmod 400 id_rsa
# chmod 400 id_rsa.pub
# ssh-copy-id -i ~/.ssh/id_rsa.pub "-p 8129" root@ansible-client

tail -f /dev/null