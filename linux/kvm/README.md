# KVM

Main Source <https://www.linux.com/learn/intro-to-linux/2017/5/creating-virtual-machines-kvm-part-1>

Info <https://blog.programster.org/kvm-cheatsheet>

## Installation

for Ubuntu
```
sudo apt install qemu-kvm libvirt-bin virt-manager bridge-utils
```

for CentOSj
```
sudo yum install qemu-kvm libvirt-bin virt-manager bridge-utils
```

Join groups

```
sudo usermod -aG libvirt <user>
```

Check

```
virsh -c qemu:///system list
```

## Command line


