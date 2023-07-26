RES_SA_ID=$(yc iam service-account get --name adminkub --format json | jq .id -r)
NODE_SA_ID=$(yc iam service-account get --name user-registry --format json | jq .id -r)

yc managed-kubernetes cluster create \
  --name name_cluster --network-name vpc-kub \
  --zone ru-central1-c --subnet-name vpc-kub-ru-central1-c \
  --public-ip \
  --service-account-id $RES_SA_ID \
  --node-service-account-id $NODE_SA_ID
