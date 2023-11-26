# source '/mnt/hgfs/Project 3/setup_ceph.sh'

# https://www.highgo.ca/2023/03/24/setup-an-all-in-one-ceph-storage-cluster-on-one-machine/

# Add ceph user
# sudo useradd -d /home/ceph -m ceph
# sudo passwd ceph
# echo "ceph ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ceph
# sudo chmod 0440 /etc/sudoers.d/ceph
# su - ceph

# Install ceph dependencies
sudo apt -y install lvm2 ntp ntpdate ntp-doc

cd ~
# Install cephadm
curl --silent --remote-name --location https://github.com/ceph/ceph/raw/octopus/src/cephadm/cephadm
chmod +x cephadm

sudo ./cephadm add-repo --release octopus
sudo ./cephadm install

# https://docs.ceph.com/en/latest/cephadm/install/#single-host
sudo tee -a /tmp/init_ceph.conf <<EOF
[global]
osd crush chooseleaf type = 0
EOF

# MON_IP is first ip from `ip addr show` that does not start with 127 (localhost)
export MON_IP=192.168.49.1
# Start Ceph Dashboard with cephadm
sudo ./cephadm bootstrap --mon-ip $MON_IP --dashboard-password-noupdate --initial-dashboard-user admin --initial-dashboard-password password --config /tmp/init_ceph.conf || exit 1

# Install helper cli tools (ceph status)
sudo cephadm install ceph-common


# Add Object Storage Devices (OSD's)

# May need to add new hard disk through VMWare
# Player > Manage > Virtual Device Settings (Ctrl + d)
# Click Add at the bottom > Hard Disk > SCSI > Create New Virtual Disk > 20 GB Single File > osd-[1,3]
# Must be larger than 5 GB
# Create at least 2 to remove warnings

# Use this command to refresh available devices
# sudo ceph orch device ls --wide --refresh

# Creates osd for each new virtual disk added above
sudo ceph orch apply osd --all-available-devices

# sudo ceph config set mon mon_allow_pool_delete true

# Setup RGW daemon for S3 interface
sudo apt -y install radosgw
echo waiting for 3 osd to be available...
sudo /etc/init.d/radosgw start -v

sudo radosgw-admin realm create --rgw-realm=default --default
sudo radosgw-admin zonegroup create --rgw-zonegroup=default --master --default
sudo radosgw-admin zone create --rgw-zonegroup=default --rgw-zone=us-east-1 --master --default
sudo ceph orch apply rgw default us-east-1 --placement="1 `hostname -s`"

# Finally, create RGW user
sudo radosgw-admin user create --uid=s3-user --display-name=s3-user --system

# Get user login (for s3 clients like boto3)
sudo apt -y install jq
s3userInfo=$(sudo radosgw-admin user info --uid=s3-user)
s3AccessKeyId=$(echo $s3userInfo | jq -r '.keys[0].access_key')
s3SecretKeyId=$(echo $s3userInfo | jq -r '.keys[0].secret_key')
export AWS_ACCESS_KEY_ID_S3=$s3AccessKeyId
export AWS_SECRET_ACCESS_KEY_S3=$s3SecretKeyId
echo export AWS_ACCESS_KEY_ID_S3=$s3AccessKeyId | sudo tee -a /etc/profile.d/mine.sh
echo export AWS_SECRET_ACCESS_KEY_S3=$s3SecretKeyId | sudo tee -a /etc/profile.d/mine.sh


echo -n $s3AccessKeyId > /tmp/rgw_access_key
echo -n $s3SecretKeyId > /tmp/rgw_secret_key 


sudo ceph dashboard set-rgw-api-access-key -i /tmp/rgw_access_key
sudo ceph dashboard set-rgw-api-secret-key -i /tmp/rgw_secret_key

export RGW_URL=http://$MON_IP:80
echo export RGW_URL=$RGW_URL | sudo tee -a /etc/profile.d/mine.sh
# Now you have Ceph RGW running and ready for you to upload videos using your username/key.
echo Ceph RGW listening on $RGW_URL
 
#  Create bucket notifications
curl -d "Action=CreateTopic&Name=sentmessage&push-endpoint=http://192.168.49.2:31112/async-function/facerecognition" -X POST $RGW_URL

curl -d "Action=CreateTopic&Name=respondmessage&push-endpoint=http://192.168.49.1:5000/print_output_bucket" -X POST $RGW_URL

sudo apt -y install python3-pip
pip install boto3 flask

FUNCTIONS_SOURCE='/mnt/hgfs/Project 3'
python3 "$FUNCTIONS_SOURCE/add_bucket_notification.py"

# Provide function credentials
faas-cli secret create s3-access-key-id --from-literal $s3AccessKeyId
faas-cli secret create s3-secret-key --from-literal  $s3SecretKeyId

echo Enter your AWS Access Key:
read AWS_ACCESS_KEY_ID
echo Enter your AWS Secret Key:
read AWS_SECRET_ACCESS_KEY

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY

faas-cli secret create aws-access-key-id --from-literal $AWS_ACCESS_KEY_ID
faas-cli secret create aws-secret-key --from-literal  $AWS_SECRET_ACCESS_KEY

echo logging into docker...
docker login
cd ~/openfaas
# Deploy function
# NOTE: Takes about 712 to build and 120 to push (~ 13 mins first build)
faas-cli up -f functions.yml

echo OpenFaaS listening on $OPENFAAS_URL/function/face_recognition
