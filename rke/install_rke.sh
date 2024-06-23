#!/bin/bash

rke up --ignore-docker-version

if [ ! -f "kube_config_cluster.yml" ]; then
   exit 1
fi


cp kube_config_cluster.yml /root/.kube/config

kubectl get ns

kubectl apply -f ingress-service.yml

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml
sleep 10
kubectl apply -f cert-prod.yml

bash rules4-m

curl -skSL https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/v4.6.0/deploy/install-driver.sh | bash -s v4.6.0 --
kubectl apply -f nfs-csi.yml
kubectl patch storageclass nfs-csi -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

