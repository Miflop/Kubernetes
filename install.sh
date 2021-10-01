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
   echo "\033[1;33mServer Name:\033[0m"
   read ServerName
fi

if ! [ "$Role" ]; then
   echo "\033[1;33mRole (values-case-sensitive: Master/Node)\033[0m"
   read Role
fi

echo -e "\033[1;33mDisabling swap\033[0m"
swapoff -a
sed -i 's|/swap|# /swap|g' /etc/fstab

echo -e "\033[1;33mGetting default interface name\033[0m"

INTERFACE=$(route | grep '^default' | grep -o '[^ ]*$')
PRIVATEIP=$(/sbin/ifconfig $INTERFACE | grep -i mask | awk '{print $2}'| cut -f2 -d:)
OLDHOSTNAME = hostname
sed -i 's|$OLDHOSTNAME|$ServerName|g' /etc/hosts
hostnamectl set-hostname $ServerName
echo "${PRIVATEIP} ${ServerName}" >> /etc/hosts


apt install -y docker.io docker-compose
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl

sed -i 's|Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"|Env>

sudo kubeadm init --apiserver-advertise-address=$PRIVATEIP --pod-network-cidr=192.168.0.0/16

mkdir addons
cd addons
sudo curl https://docs.projectcalico.org/manifests/calico.yaml -O
cd ..

#mv  $HOME/.kube $HOME/.kube.bak
#sudo mkdir $HOME/.kube
#sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
#sudo chown $(id -u):$(id -g) $HOME/.kube/config
echo "--------------------------------------"
echo "ALLOW YOUR USER TO USE KUBECTL NO SUDO"
echo "chown -R USER HOME/.kube"
#export KUBECONFIG=/etc/kubernetes/admin.conf
echo "kubeadm token create --print-join-command  ## TO JOIN TOKEN"
echo "-----------------------------------------------------------"

kubectl apply -f addons/calico.yaml
