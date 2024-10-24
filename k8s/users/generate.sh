#!/bin/bash

USERNAME=""
NAMESPACE=""
SERVER=""
CLUSTERNAME=""

cat << EOF > create_user.yml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $USERNAME
  namespace: default

---
apiVersion: v1
kind: Secret
metadata:
  name: $USERNAME-token
  annotations:
    kubernetes.io/service-account.name: $USERNAME
type: kubernetes.io/service-account-token
EOF

cat << EOL > create_role.yml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: $NAMESPACE
  name: $USERNAME-pod-reader
rules:
  - verbs:
      - '*'
    apiGroups:
      - ''
    resources:
      - pods
      - pods/log
      - pods/exec
  - verbs:
      - get
      - list
    apiGroups:
      - ''
    resources:
      - configmaps
  - verbs:
      - get
      - list
      - watch
    apiGroups:
      - ''
      - networking.k8s.io
      - networking
      - extensions
    resources:
      - ingresses

---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: $USERNAME-pod-reader
  namespace: $NAMESPACE
subjects:
- kind: ServiceAccount
  name: $USERNAME
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: $USERNAME-pod-reader

EOL

cat << EOJ > create_cluster_role.yml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: crb-$USERNAME
subjects:
  - kind: ServiceAccount
    name: $USERNAME
    namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cr
EOJ

echo "USERNAME=\"$USERNAME\"" > get_creds.sh

cat << 'EON' >> get_creds.sh

CERT=`kubectl describe secret $(kubectl get secret | (grep $USERNAME || echo "$_") | awk '{print $1}') | grep token: | awk '{print $2}'`
echo "--------------"
TOKEN=`kubectl get secret \`kubectl get secret | (grep $USERNAME || echo "$_") | awk '{print $1}'\` -o "jsonpath={.data['ca\.crt']}"`

sed -i "s/CERT/$CERT/g" config-$USERNAME
sed -i "s/TOKEN/$TOKEN/g" config-$USERNAME

EON

cat << EOP > config-$USERNAME
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: CERT
    server: "$SERVER"
  name: $CLUSTERNAME

contexts:
- context:
    cluster: $CLUSTERNAME
    user: $USERNAME
  name: $CLUSTERNAME
current-context: $CLUSTERNAME

kind: Config
preferences: {}

users:
- name: $USERNAME
  user:
    client-key-data: CERT
    token: TOKEN

EOP

cat << EOM > all.sh

kubectl apply -f create_user.yml
kubectl apply -f create_role.yml
kubectl apply -f create_cluster_role.yml
bash get_creds.sh

echo "config ready"
EOM
