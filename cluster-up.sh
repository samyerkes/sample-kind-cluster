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

# give some crds time to register
sleep 10
# and try again
kubectl --context kind-kind apply -f bundle

# Installs the metrics server
kubectl --context kind-kind apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
sleep 10

# Helm repo update
# ... Grafana + Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack \
    -n metrics 

# ... Sealed Secrets
helm install sealed-secrets \
    -n kube-system \
    --set-string fullnameOverride=sealed-secrets-controller \
    sealed-secrets/sealed-secrets

# ... Flux
flux install \
    --namespace=flux-system \
    --network-policy=false \
    --components=source-controller,helm-controller

sleep 5
echo ""
echo "Traefik: http://traefik.localhost"
echo "Grafana: http://grafana.localhost credentials: $(kubectl get secret -n metrics prometheus-grafana -oyaml | grep admin-user| cut -d: -f2|tr -d \  | base64 -d):$(kubectl get secret -n metrics prometheus-grafana -oyaml | grep admin-password| cut -d: -f2|tr -d \  | base64 -d)"
