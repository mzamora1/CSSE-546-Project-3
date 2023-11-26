# source '/mnt/hgfs/Project 3/setup_openfaas.sh'
sudo apt -y install curl
mkdir -p ~/openfaas
cd ~/openfaas

if [[ "$(which minikube)" -eq '' ]] 
then
#Install minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
fi

if [[ "$(which kubectl)" -eq '' ]] 
then
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
fi

if [[ "$(which docker)" -eq '' ]]
then
# Install docker (for minikube)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh ./get-docker.sh
echo Rerun this file to finish openfaas setup after reboot
echo press enter to continue with reboot...
read DUMMYAR
# echo Rerun this file after commenting out the beginning to the line AFTER this "'echo'" command
# echo Example: Line 1 to 18
sudo usermod -aG docker $USER && newgrp docker <<EOF
sudo reboot
EOF
exit 0
fi
# END COMMENT HERE

# Start kubernetes cluster
minikube start
kubectl get pods -A
echo minikube start | sudo tee -a /etc/profile.d/mine.sh

# Install faas-cli 
curl -sL cli.openfaas.com | sudo sh

# Install helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash


# Setup OpenFaaS
# 1. Create namespaces for OpenFaaS core components and OpenFaaS Functions
kubectl apply -f https://raw.githubusercontent.com/openfaas/faas-netes/master/namespaces.yml

# 2. Add the OpenFaaS helm repository: 
helm repo add openfaas https://openfaas.github.io/faas-netes/

# 3. Update all the charts for helm: 
helm repo update

# 4. Generate a random password: 
export PASSWORD=$(head -c 12 /dev/urandom | shasum| cut -d' ' -f1)
# echo $PASSWORD

# 5. Create a secret for the password 
kubectl -n openfaas create secret generic basic-auth --from-literal=basic-auth-user=admin --from-literal=basic-auth-password="$PASSWORD"

# 6. Install OpenFaaS using the chart: 
helm upgrade openfaas --install openfaas/openfaas --namespace openfaas --set functionNamespace=openfaas-fn --set basic_auth=true

# Get admin password: 
export PASSWORD=$(kubectl -n openfaas get secret basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 --decode)

export OPENFAAS_URL=http://$(minikube ip):31112
echo export OPENFAAS_URL=$OPENFAAS_URL | sudo tee -a /etc/profile.d/mine.sh
# 7. Finally once all the Pods are started you can login using the CLI: 

echo Waiting for Openfaas pods to start, if this fails, rerun from this point forward
while : ; do 
    kubectl get pods -n openfaas | grep gateway.+Running
    [[ $? -ne 0 ]] || break
    echo Still waiting...
    sleep 1
done
echo -n $PASSWORD | faas-cli login -g $OPENFAAS_URL -u admin --password-stdin || exit 1

# Deploy Face Reconigition Function to OpenFaaS
# sudo mkdir -p /mnt/hgfs
# sudo vmhgfs-fuse .host:/ /mnt/hgfs/ -o allow_other -o uid=1000
export FUNCTIONS_SOURCE='/mnt/hgfs/Project 3'

cp -r "$FUNCTIONS_SOURCE/face_recognition" ./face_recognition
cp "$FUNCTIONS_SOURCE/functions.yml" ./functions.yml

# sudo reboot
cd "$FUNCTIONS_SOURCE"

echo Openfaas login: Username = admin, Password = $PASSWORD

open $OPENFAAS_URL && exit 0
exit 1