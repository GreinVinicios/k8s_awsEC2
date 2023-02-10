
# k8s_awsEC2
This repo contain an example of how to implement Kubernetes on EC2 instances.
>All the steps consider that you already have an AWS account and user access configured with access and a secret key.

## Infrastructure

### Prerequisite
First of all, you need to create one AWS S3 bucket. For that:
- On the AWS Console > S3 > Create bucket > follow the instructions there

The second step is to change the file [backend.tf](./backend.tf) changing for your custom information.
Open a new terminal in this folder.

Afterward, you need to generate a key pair to access the instances via SSH. To do that, run the command:
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/aws_key
```
> Note that the key name is aws_key, once you change it here, remember to change it on the terraform files where is used this reference.

Run the Terraform commands to create the infrastructure.

### Variables
| Variable | Description | Default |
| - | - | - |
| region | The AWS region | us-west-1 |
| access_key | The access key of the AWS account | | 
| secret_key | The secret key of the AWS account | |
| instance_type | [Instances](https://aws.amazon.com/pt/ec2/instance-types/) | "t3.micro" |
| ami | The instance type | "ami-0d50e5e845c552faf" which means Ubuntu, 22.04 LTS |

Create a file (e.g. myvariables.auto.tfvars) and add the variables.
```bash
region        = "us-west-1"
access_key    = "AWSACCESSKEY"
secret_key    = "AWSSECRETKEY"
instance_type = "t3.micro"
ami           = "ami-0c0a5e8c5a44ef515"
```

### Creating the infra resources
```bash
terraform init
terraform plan
terraform apply
```

> Terraform will create 3 EC2 instances, 1 key pair, and security groups allowing SSH, HTTP, HTTPS, and port 6443

### Acceccing the instances
Once all infrastructure was deployed, access the instances to install the required tools.
To access the EC2 instances:  
- On the AWS Console > EC2 > Click on the instance > Connect > SSH Client > follow the example there.
e.g.: 
```bash
ssh -i ~/.ssh/aws_key root@ec2-54-666-252-8.us-west-1.compute.amazonaws.com
```

### Installing the tools
The tools listed here (docker and kubeadm) will be necessary to configure each instance. 

- [**Docker**](https://docs.docker.com/engine/install/ubuntu/) 
```bash
sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt-get update
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
VERSION_STRING=5:20.10.23~3-0~ubuntu-jammy
sudo apt-get install docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
```
- **Kubeadm**
```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet=1.23.2-00 kubeadm=1.23.3-00 kubectl=1.23.3-00
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl daemon-reload
sudo systemctl restart kubelet
sudo systemctl status kubelet
```

Case kubeadm doesn't start, run the command below to see the logs `sudo journalctl -u kubelet -b` 
```
kubelet cgroup driver: "systemd" is different from docker cgroup driver: "cgroupfs" 
```
Follow the steps:
```
sudo vi /etc/systemd/system/multi-user.target.wants/docker.service

# Modify this line 
# ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock 

#To 
#ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --exec-opt native.cgroupdriver=systemd 

sudo systemctl daemon-reload
sudo systemctl restart docker

#Restart the instances
sudo shutdown -rZ
```

### Configuring the master node
Do this step on the instance that you want to be configured as a master node
```bash
# Initializing master node
kubeadm config images pull
sudo kubeadm init 

# Configuring kubeconfig
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Installing the network solution (weave)
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

# Printing join command
kubeadm token create --print-join-command
```
> Probably you will run into some errors trying to init master due to the memory being too low. To skip that, add **--ignore-preflight-errors=Mem**

### Configuring worker nodes
Access the EC2 instances. Copy the printed join command from last step above and run it.
Will be able to see all nodes running `kubectl get nodes`.