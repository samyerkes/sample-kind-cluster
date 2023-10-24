# Sample Kind cluster

This repo aims at showcasing how to create a basic viable
[Kind](https://kind.sigs.k8s.io/) cluster with a dynamic volumes provisioner as
well as a pre-configured [traefik v2](https://doc.traefik.io/traefik/v2.3/)
ingress controller. The Traefik ingress controller is necessary to provision an
environment that more closely matches K3S which uses Traefik as a default
ingress.

## Create the cluster

To start, run:

```console
./cluster-up.sh
```

After a successful installation, the applications will be accessible at:

* [traefik.localhost](http://traefik.localhost/dashboard/#/)
* [grafana.localhost](http://grafana.localhost)
