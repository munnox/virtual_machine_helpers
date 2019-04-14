#!/bin/bash

# Source <https://www.linuxtechi.com/install-configure-kvm-ubuntu-18-04-server/>

# Test the CPU
egrep -c '(vmx|svm)' /proc/cpuinfo
egrep -i '^flags.*(svm|vmx)' /proc/cpuinfo

sudo apt install cpu-checker

# Install KVM and dependancies
sudo apt update
sudo apt install qemu qemu-kvm libvirt-bin  bridge-utils  virt-manager

# Start KVM
sudo service libvirtd start
sudo update-rc.d libvirtd enable

# Configure Network
sudo vi /etc/netplan/50-cloud-init.yaml

# network:
#   version: 2
#   ethernets:
#     ens33:
#       dhcp4: no
#       dhcp6: no
# 
#   bridges:
#     br0:
#       interfaces: [ens33]
#       dhcp4: no
#       addresses: [192.168.0.51/24]
#       gateway4: 192.168.0.1
#       nameservers:
#         addresses: [192.168.0.1]

# then apply
sudo netplan apply
sudo netplan --debug  apply

# check
sudo networkctl status -a

# sudo virt-install  \
#     -n DB-Server  \
#     --description "Test VM for Database" \
#     --os-type=Linux  \
#     --os-variant=rhel7  \
#     --ram=1096 \
#     --vcpus=1 \
#     --disk path=/var/lib/libvirt/images/dbserver.img,bus=virtio,size=10 \
#     --network bridge:br0 \
#     --graphics none \
#     --location /home/linuxtechi/rhel-server-7.3-x86_64-dvd.iso \
#     --extra-args console=ttyS0

# OpenVswitch
# Source <https://github.com/openvswitch/ovs/blob/master/Documentation/tutorials/ovs-advanced.rst>
