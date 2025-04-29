#!/bin/bash

read -s -p "Enter username: " SSH_USERNAME
echo ""
read -s -p "Enter password: " SSH_PASSWORD

while read -r line
do
    echo "running $line"
    sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no "$SSH_USERNAME@$line" "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys" < ~/.ssh/id_rsa.pub
done < "ssh_hosts.txt"

