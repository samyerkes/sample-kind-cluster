#! /usr/bin/env bash

# Create the cluster
for CLUSTER in {staging,production}; do
# CLUSTER=staging

    if ! kind create cluster --name $CLUSTER --config cluster-$CLUSTER.yaml; then
        exit 1
    fi;

    # Untaint the master
    kubectl --context kind-$CLUSTER taint nodes --all node-role.kubernetes.io/master- || true

    # Loop three times
    for i in {1..3}; do
        # Applies the manifests
        # Yeah some CRDs are not available right away
        kubectl --context kind-$CLUSTER apply -f infrastructure/ --recursive
        # ... and try again
        sleep 10
    done

    # Install Flux
    flux install \
        --namespace=flux-system \
        --network-policy=false \
        --components=source-controller,helm-controller,kustomize-controller

    # Install kustomize on clusters
    kubectl apply -f clusters/ --recursive

    # Apply the app kustomizations to each cluster
    kubectl apply -k apps/$CLUSTER/.

    echo ""
    echo "Letting the cluster settle..."
    sleep 120
    echo ""

    GRAFANA_URL=$(kubectl get IngressRoute grafana-prometheus -o=json -n metrics | jq -r '.spec.routes[0].match' | sed "s/Host(\`\(.*\)\`)/\1/")
    GRAFANA_CREDS_USER=$(kubectl get secret -n metrics kube-prometheus-stack-grafana -oyaml | grep admin-user | cut -d: -f2 | tr -d \  | base64 -d)
    GRAFANA_CREDS_PASSWORD=$(kubectl get secret -n metrics kube-prometheus-stack-grafana -oyaml | grep admin-password | cut -d: -f2 | tr -d \ | base64 -d)

    echo "Traefik: http://traefik.localhost"
    echo "Grafana: http://$GRAFANA_URL credentials: $GRAFANA_CREDS_USER:$GRAFANA_CREDS_PASSWORD"

done
