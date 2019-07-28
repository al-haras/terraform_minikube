#!/bin/bash
apt-get update && \
    apt-get install docker.io -y
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube
mv minikube /usr/local/bin/
systemctl enable docker.service
su ubuntu -c 'sudo minikube start --vm-driver=none'
chown -R ubuntu /home/ubuntu/.kube/
chown -R ubuntu /home/ubuntu/.minikube/