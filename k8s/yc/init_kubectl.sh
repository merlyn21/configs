name_k="name_cluster"

yc managed-kubernetes cluster \
  get-credentials $name_k \
  --external  --force
