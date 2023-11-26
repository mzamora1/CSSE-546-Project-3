sudo apt install open-vm-tools open-vm-tools-desktop curl
sudo reboot
# copy/paste is now enabled
# copy/paste these commands to enable shared folders
sudo mkdir -p /mnt/hgfs
sudo vmhgfs-fuse .host:/ /mnt/hgfs/ -o allow_other -o uid=1000
echo sudo vmhgfs-fuse .host:/ /mnt/hgfs/ -o allow_other -o uid=1000 | sudo tee -a /etc/profile.d/mine.sh 