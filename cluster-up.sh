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

# Install the Helm charts
# ... Grafana + Prometheus
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
    -n metrics 

# ... Sealed Secrets
helm install sealed-secrets \
    sealed-secrets/sealed-secrets \
    --set-string fullnameOverride=sealed-secrets-controller \
    -n kube-system

# ... Flux
flux install \
    --namespace=flux-system \
    --network-policy=false \
    --components=source-controller,helm-controller

sleep 5
echo ""
echo "Traefik: http://traefik.localhost"
echo "Grafana: http://grafana.localhost credentials: $(kubectl get secret -n metrics kube-prometheus-stack-grafana -oyaml | grep admin-user| cut -d: -f2|tr -d \  | base64 -d):$(kubectl get secret -n metrics kube-prometheus-stack-grafana -oyaml | grep admin-password| cut -d: -f2|tr -d \  | base64 -d)"
