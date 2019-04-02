# Source <https://linuxconfig.org/how-to-create-and-manage-kvm-virtual-machines-from-cli>

virt-install --name=ubuntu18.04-Image \
  --vcpus=2 \
  --memory=2048 \
  --cdrom="/var/ubuntu-18.04.1-desktop-amd64.iso" \
  --disk size=15 \
  --os-variant=ubuntu18.04
