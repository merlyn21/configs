helm repo add bitnami https://charts.bitnami.com/bitnami

#helm repo list
#helm search repo rabbitmq
#helm pull bitnami/rabbitmq

kubectl create namespace rabbit
helm install -f values.yaml ukids-rabbitmq bitnami/rabbitmq -n rabbit
