#! /usr/bin/env bash

# Create the cluster
if ! kind create cluster --config cluster.yaml; then
    exit 1
fi;

# Untaint the master
kubectl --context kind-kind taint nodes --all node-role.kubernetes.io/master- || true

# Applies the manifests
kubectl --context kind-kind apply -f bundle
# yeah some CRDs are not available right away
sleep 10
kubectl --context kind-kind apply -f bundle

# Give some CRDs time to register
sleep 10
# ... and try again
kubectl --context kind-kind apply -f bundle
sleep 10

# Install Flux
flux install \
    --namespace=flux-system \
    --network-policy=false \
    --components=source-controller,helm-controller

# Install the Helm charts
kubectl apply -f helm/ --recursive

echo ""
echo "Letting the cluster settle..."
sleep 45
echo ""
echo "Traefik: http://traefik.localhost"
echo "Grafana: http://grafana.localhost credentials: $(kubectl get secret -n metrics kube-prometheus-stack-grafana -oyaml | grep admin-user | cut -d: -f2 | tr -d \  | base64 -d):$(kubectl get secret -n metrics kube-prometheus-stack-grafana -oyaml | grep admin-password | cut -d: -f2 | tr -d \ | base64 -d)"
