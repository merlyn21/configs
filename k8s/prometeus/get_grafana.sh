export GRAFANA_IP=$(kubectl get service/grafana -o jsonpath='{.status.loadBalancer.ingress[0].ip}') && \
export GRAFANA_PORT=$(kubectl get service/grafana -o jsonpath='{.spec.ports[0].port}') && \
echo http://$GRAFANA_IP:$GRAFANA_PORT
