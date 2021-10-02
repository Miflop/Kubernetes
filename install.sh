#!/bin/bash

for ARGUMENT in "$@"
do

  KEY=$(echo $ARGUMENT | cut -f1 -d=)
  VALUE=$(echo $ARGUMENT | cut -f2 -d=)

case "$KEY" in
            ServerName)              ServerName=${VALUE} ;;
            Role)    Role=${VALUE} ;;
            *)
    esac
done

echo "SERVER_NAME = $ServerName"
echo "Role = $Role"

if ! [ "$ServerName" ]; then
   echo -e "\033[1;33mServer Name\033[0m"
   read ServerName
fi

if ! [ "$Role" ]; then
   echo -e "\033[1;33mRole (values case sensitive Master/Node)\033[0m"
   read Role
fi

echo -e "\033[1;33mDisabling swap\033[0m"
swapoff -a
sed -i 's|/swap|# /swap|g' /etc/fstab

apt install -y net-tools
echo -e "\033[1;33mGetting default interface name\033[0m"
Interface=$(route | grep '^default' | grep -o '[^ ]*$')
PrivateIp=$(/sbin/ifconfig $Interface | grep -i mask | awk '{print $2}'| cut -f2 -d:)
OldHostname = hostname
sed -i 's|$OldHostname|$ServerName|g' /etc/hosts
hostnamectl set-hostname $ServerName
echo "${PrivateIp} ${ServerName}" >> /etc/hosts


apt install -y docker.io docker-compose
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl

sed -i 's|Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"|Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/k>etes/kubelet.conf --cgroup-driver=cgroupfs"|g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

sudo kubeadm init --apiserver-advertise-address=$PrivateIp --pod-network-cidr=192.168.0.0/16

mkdir addons
cd addons
curl https://docs.projectcalico.org/manifests/calico.yaml -O
cd ..
kubectl apply -f addons/calico.yaml

echo -e "\033[1;33m-------------------- NON ROOT USER ---------------------\033[0m"
echo -e "\033[1;33msudo rmdir \$HOME/.kube --ignore-fail-on-non-empty\033[0m"
echo -e "\033[1;33msudo mkdir \$HOME/.kube\033[0m"
echo -e "\033[1;33msudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config\033[0m"
echo -e "\033[1;33msudo chown \$(id -u):\$(id -g) \$HOME/.kube/config\033[0m"
echo -e "\033[1;33mchown -R \$USER \$HOME/.kube\033[0m"
echo ""
echo -e "\033[1;33m------------------ ROOT USER ---------------\033[0m"
echo -e "\033[1;33mexport KUBECONFIG=/etc/kubernetes/admin.conf\033[0m"
echo -e "\033[1;33m--------------------------------------------\033[0m"
echo ""
echo -e "\033[1;33m---------- GET JOIN TOKEN WITH ----------\033[0m"
echo -e "\033[1;33mkubeadm token create --print-join-command\033[0m"
echo -e "\033[1;33m-----------------------------------------\033[0m"
