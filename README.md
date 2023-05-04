# Sample Kind cluster

This repo aims at showcasing how to create a basic viable
[Kind](https://kind.sigs.k8s.io/) cluster with a dynamic volumes provisioner as
well as a pre-configured [traefik v2](https://doc.traefik.io/traefik/v2.3/)
ingress controller. The Traefik ingress controller is necessary to provision an
environment that more closely matches K3S which uses Traefik as a default
ingress.

## Create the cluster

Just run:

```bash
./cluster-up.sh
```

Wait a bit then you should have your traefik dashboard available at
[localhost:8080](http://localhost:8080)

The script will install the traefik dashboard at
[traefik.localhost](http://traefik.localhost/dashboard/#/).
