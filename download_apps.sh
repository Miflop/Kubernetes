#/bin/bash
mkdir apps
cd apps
curl https://raw.githubusercontent.com/portainer/k8s/master/deploy/manifests/portainer/portainer.yaml -O
curl https://raw.githubusercontent.com/portainer/k8s/master/deploy/manifests/portainer/portainer-lb.yaml -O
curl https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml -O
