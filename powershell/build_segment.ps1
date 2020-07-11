# Very simple script to take an existing base image and clone it
# This pull the hdd generation and network from the original.
#
# Now makes multiple VM from a list of names with the same characteristics.
# Also renames them after creation with a basic admin account setup below.
#
# Added better configureation from the Unattended setup system
# Source <https://social.technet.microsoft.com/wiki/contents/articles/36609.windows-server-2016-unattended-installation.aspx>
# Source of inspiration at <https://www.altaro.com/hyper-v/powershell-script-deploy-vms-configure-guest-os-one-go/> 
#
# Author Robert Munnoch
# [about_Execution_Policies](https:/go.microsoft.com/fwlink/?LinkID=135170)
# `Get-ExecutionPolicy` or `Get-ExecutionPolicy -List` or `Get-ExecutionPolicy -Scope CurrentUser`
#         Scope ExecutionPolicy
#         ----- ---------------
# MachinePolicy       Undefined
#    UserPolicy       Undefined
#       Process       Undefined
#   CurrentUser    RemoteSigned
#  LocalMachine       AllSigned
# Group Policy 	                                | Execution Policy
# ----------------------------------------------| ----------------
# Allow all scripts                             |  Unrestricted
# Allow local scripts and remote signed scripts |  RemoteSigned
# Allow only signed scripts                     |  AllSigned
# `Set-ExecutionPolicy -ExecutionPolicy Unrestricted`

$base_images = @{
    windows= "vws"
    linuxdesktop= "Image-ud180404"
    linuxserver= "Image-us180404"
    client= "ansible_client"
    pfsense="Image-pfsense"
}

# $BASE_VM = (Get-VM -Name $base_image)
# $seg_network_name = $BASE_VM.NetworkAdapters[0].SwitchName

$project = "test_segment";
$baseIP = "192.168.0";
$mask = 24;

#User name and Password
$AdminAccount="Administrator"
$AdminPassword="passw0rd!"

$seg_network_name = "$Project range: $baseIP.0/$mask";
$seg_network_type = "Internal";

$seg_network="NIC-A";
$seg_main_network="LocalNet";

Write-Host "Segment network: '$seg_network_name' to use.";

$machines= @(
    # @{
    #     name='testwin'
    #     base_image=$base_images['windows']
    #     description="$project Windows"
    #     cpucount=2
    #     memory=2GB
    #     nics= @(
    #         @{
    #             name="main"
    #             network=$seg_main_network
    #             vlan=5
    #             ip="$baseIP.1"
    #             gateway="$baseIP.1"
    #             dns="8.8.8.8"
    #         }
    #     )
    #     tags=@(
    #         'windows',
    #         'unattend',
    #         # 'allowvirtualisation',
    #         'start',
    #         'server'
    #     )
    # }
    @{
        name='log_server_01'
        base_image=$base_images['linuxdesktop']
        description="Network $project Linux"
        cpucount=2
        memory=4GB
        nics= @(
            @{
                name="main"
                network=$seg_main_network
                #vlan=5
                #ip="$baseIP.2"
                #gateway="$baseIP.1"
                #dns="8.8.8.8"
            }
        )
        tags=@(
            'linux',
            'allowvirtualisation',
            'start',
            'server'
        )
    }
    @{
        name='log_server_02'
        base_image=$base_images['linuxdesktop']
        description="Network $project Linux"
        cpucount=2
        memory=4GB
        nics= @(
            @{
                name="main"
                network=$seg_main_network
                #vlan=5
                #ip="$baseIP.2"
                #gateway="$baseIP.1"
                #dns="8.8.8.8"
            }
        )
        tags=@(
            'linux',
            'allowvirtualisation',
            'start',
            'server'
        )
    }
        )


$single_machine= @(
    @{
        name='testpfsense'
        base_image=$base_images['pfsense']
        description="$project router"
        cpucount=2
        memory=2GB
        nics= @(
            @{
                name="main"
                network=$seg_main_network
                vlan=5
                ip="$baseIP.1"
                gateway="$baseIP.1"
                dns="8.8.8.8"
            }
            @{
                name="main"
                network=$seg_network_name
                vlan=5
                ip="$baseIP.1"
                gateway="$baseIP.1"
                dns="8.8.8.8"
            }
        )
        tags=@(
            'windows',
            'unattend',
            # 'allowvirtualisation',
            'start',
            'server'
        )
    }
)

$segment = @{
    project = $project
    admin_credentials = @{
        username = $AdminAccount
        password = $AdminPassword
    }
    network = @{
        baseIP = $baseIP
        mask = $mask
    }
    machines=$machines
}


function Get-ScriptPath
{
    Split-Path $myInvocation.ScriptName
}

$script_path = Get-ScriptPath;
$vmlib = $script_path + "\VirtualisationLib.psm1"
Write-Host "Importing my VM module from path: " $vmlib
Import-Module $vmlib
# . .\VirtualisationLib.ps1

$segment_filename = $script_path + "\current_segment.json"
$machines_json = ConvertTo-Json $segment
Set-Content -Path $segment_filename -Value $machines_json


$new_segment = Get-Content -Path $segment_filename | ConvertFrom-Json
# Ensure-VMSwitch $seg_network_name $seg_network_type

Write-Host $new_segment
Clone-VMs "$PSScriptRoot\Unattend.xml" `
    $PSScriptRoot `
    $new_segment.machines `
    $new_segment.admin_credentials.username `
    $new_segment.admin_credentials.password