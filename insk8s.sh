#!/bin/bash

# install Docker

install_ubuntu() {
    ## Remove any pre installed docker packages:
    which docker
    if [ $? -eq 0 ];then
       sudo systemctl stop docker
       sudo apt-get remove -y docker-ce docker-engine docker.io containerd runc
       sudo apt-get purge -y docker-ce docker-ce-cli containerd.io
       sudo apt -y autoremove
       cd /var/lib
       rm -rf docker
    else
       echo "docker is not installed.. continue to install"
    fi

    ## Install using the repository:
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg software-properties-common lsb-release
    ## Add Dockers official GPG key & stable repo
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
    #curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    #sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    ## Install Docker latest
    sudo apt-get update ; clear
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    if [ $? -eq 0 ];then
       if [ -f /etc/docker/daemon.json ];then
         echo "cgroup config is already configured skipping.."
       else
          echo "docker-ce is successfully installed"
          yum install -y wget
          sudo wget https://raw.githubusercontent.com/lerndevops/labs/master/kubernetes/0-install/daemon.json -P /etc/docker
          sudo service docker restart ; clear
       fi
    else
      echo "issue with docker-ce installation - process abort"
      exit 1
    fi
    exit 0
}

install_centos() {

    which docker
    if [ $? -eq 0 ];then
       sudo yum remove docker-client-latest docker-latest docker-latest-logrotate docker-logrotate docker-engine
       cd /var/lib
       rm -rf docker
       yum clean
    else
       echo "docker is not installed... continue to install"
    fi

    sudo yum install -y yum-utils   ## device-mapper-persistent-data lvm2
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install docker-ce docker-ce-cli containerd.io docker-compose-plugin
    if [ $? -eq 0 ];then
       if [ -f /etc/docker/daemon.json ];then
         echo "cgroup config is already configured skipping.."
       else
          echo "docker-ce is successfully installed"
          yum install -y wget
          sudo wget https://raw.githubusercontent.com/lerndevops/labs/master/kubernetes/0-install/daemon.json -P /etc/docker
          sudo service docker restart ; clear
       fi
    else
      echo "issue with docker-ce installation - process abort"
      exit 1
    fi
}
################ MAIN ###################

if [ -f /etc/os-release ];then
   osname=`grep ID /etc/os-release | egrep -v 'VERSION|LIKE|VARIANT|PLATFORM' | cut -d'=' -f2 | sed -e 's/"//' -e 's/"//'`
   echo $osname
   if [ $osname == "ubuntu" ];then
       install_ubuntu
   elif [ $osname == "amzn" ];then
       install_centos
   elif [ $osname == "centos" ];then
       install_centos
  fi
else
   echo "can not locate /etc/os-release - unable find the osname"
   exit 8
fi
exit 0
## 





# install K8s
install_ubuntu() {

   #### Install Kubernetes latest components
   sudo apt-get update
   sudo apt-get install -y apt-transport-https ca-certificates curl
   echo "starting the installation of k8s components (kubeadm,kubelet,kubectl) ...."
   sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
   echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
   sudo apt-get update
   sudo apt-get install -y kubelet kubeadm kubectl

   if [ $? -eq 0 ];then
      echo "kubelet, kubeadm & kubectl are successfully installed"
      sudo apt-mark hold kubelet kubeadm kubectl
   else
      echo "issue in installing kubelet, kubeadm & kubectl - process abort"
      exit 2
   fi
}

install_centos() {

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF
  
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

}

install_amzn() {

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF
  
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

}
################ MAIN ###################

if [ -f /etc/os-release ];then
   osname=`grep ID /etc/os-release | egrep -v 'VERSION|LIKE|VARIANT|PLATFORM' | cut -d'=' -f2 | sed -e 's/"//' -e 's/"//'`
   echo $osname
   if [ $osname == "ubuntu" ];then
       install_ubuntu
   elif [ $osname == "amzn" ];then
       install_amzn
   elif [ $osname == "centos" ];then
       install_centos
  fi
else
   echo "can not locate /etc/os-release - unable find the osname"
   exit 8
fi
exit 0

## CRI

#!/bin/bash

VER="v0.2.0"
#ARCH=`dpkg --print-architecture`

install_linux() {
   ARCH=$1
   if [ -f /usr/bin/cri-dockerd ];then
      echo "cri-dockerd is Already intalled"
      cri-dockerd --version
   else
      echo "Installing cri-dockerd..."
      wget https://github.com/Mirantis/cri-dockerd/releases/download/${VER}/cri-dockerd-${VER}-linux-${ARCH}.tar.gz -P /tmp
      tar -xzvf /tmp/cri-dockerd-${VER}-linux-${ARCH}.tar.gz -C /tmp
      mv /tmp/cri-dockerd /usr/bin/
      chmod 755 /usr/bin/cri-dockerd
   fi

   if [ -f /etc/systemd/system/cri-docker.service ] && [ -f /etc/systemd/system/cri-docker.socket ];then
      echo "system services are already configured skipping...."
   else
      wget https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.service -P /tmp
      wget https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.socket -P /tmp
      mv /tmp/cri-docker.socket /tmp/cri-docker.service /etc/systemd/system/
      systemctl enable cri-docker.service
      systemctl enable cri-docker.socket
      systemctl start cri-docker.service
   fi
}
################ MAIN ###################

if [ -f /etc/os-release ];then
   osname=`grep ID /etc/os-release | egrep -v 'VERSION|LIKE|VARIANT' | cut -d'=' -f2 | sed -e 's/"//' -e 's/"//'`
   echo $osname
   if [ $osname == "ubuntu" ];then
      arch=`dpkg --print-architecture`
      install_linux "$arch"
   elif [ $osname == "amzn" ];then
        echo "the script works only for ubuntu OS as of now..."
        exit 1
        install_linux
   elif [ $osname == "centos" ];then
        echo "the script works only for ubuntu OS as of now..."
        exit 1
        install_linux
   fi
else
   echo "can not locate /etc/os-release - unable find the osname"
   exit 8
fi
exit 0
