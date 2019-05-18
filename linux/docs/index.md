# Linux VM information

main app is `virsh` informtion

try `virsh help` first to see more information

# Network information

Linux has a interesting network system with helpers to aid the configuration
and setup.

The Manager used in Ubuntu 18.04 is Netplan a manager which allow a YAML config to set the systems below. 

# Network Configuration

Two main network systems

* Network-Manager
* systemd-networkd

## [Network Manager](https://en.wikipedia.org/wiki/NetworkManager)

Originaly devleoped by Redhat.

Main commands are:

* `nmcli` - Main controller
* `nm-connection-editor` - Giu to add new interfaces

## [Systemd-Networkd](https://wiki.archlinux.org/index.php/Systemd-networkd)

Main commands are:

* `networkctl` - Network configuration

# VLANS

Virtual Lans can be setup on linux machines there seems to be a few different ways to set the interfaces.

`vconfig` or `nmcli` seem to be the main ways to control it.

