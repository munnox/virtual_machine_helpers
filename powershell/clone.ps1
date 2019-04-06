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

$base_image = @{
    windows= "vws"
    linux= "vlud"
}

# $BASE_VM = (Get-VM -Name $base_image)
# $seg_network_name = $BASE_VM.NetworkAdapters[0].SwitchName

$project = "test_segment_01";
$baseIP = "192.168.0";
$mask = 24;

#User name and Password
$AdminAccount="Administrator"
$AdminPassword="passw0rd!"

$seg_network_name = "$Project range: $baseIP.0/$mask";
$seg_network_type = "Internal";

$seg_main_network="Main";

Write-Host "Segment network: '$seg_network_name' to use.";

$machines= @(
    @{
        name='T1-win'
        base_image=$base_images['windows']
        description="$project Windows"
        cpucount=2
        memory=2GB
        nics= @(
            @{
                name="main"
                network=$seg_main_network
                ip="$baseIP.1"
                gateway="$baseIP.1"
                dns="$baseIP.1"
            }
        )
        tags=@('windows', 'unattend', 'start', 'server')
    },
    @{
        name='T1-linux'
        base_image=$base_images['linux']
        description="Network $project Linux"
        cpucount=2
        memory=2GB
        nics= @(
            @{
                name="main"
                network=$seg_main_network
                ip="$baseIP.2"
                gateway="$baseIP.1"
                dns="$baseIP.1"
            }
        )
        tags=@('linux', 'start', 'server')
    }# ,
    # @{
    #     name='T1-DC'
    #     base_image=$base_image
    #     description="Network $project Domain Controller"
    #     cpucount=2
    #     memory=2GB
    #     nics= @(
    #         @{
    #             name="domain"
    #             network=$seg_network_name
    #             ip="$baseIP.2"
    #             gateway="$baseIP.1"
    #             dns="$baseIP.2"
    #         }
    #     )
    #     tags=@('win', 'dc', 'server')
    # },
    # @{
    #     name='T1-CL'
    #     base_image=$base_image
    #     description="Network $project Client"
    #     cpucount=2
    #     memory=2GB
    #     nics= @(
    #         @{
    #             name="domain"
    #             network=$seg_network_name
    #             ip="$baseIP.3"
    #             gateway="$baseIP.1"
    #             dns="$baseIP.2"
    #         }
    #     )
    #     tags=@('win', 'client')
    # }
)

$segment = @{
    project = $project
    admin_credentials = @{
        username = "Administrator"
        password = "passw0rd!"
    }
    network = @{
        baseIP = $baseIP
        mask = $mask
    }
    machines=$machines
 }

function Rename-VM {
    Param($vm_name, $cred, $new_vm_name)

    $old = Invoke-Command -VMName $vm_name -Credential $cred -ScriptBlock { $env:COMPUTERNAME };
    Write-Host "Changing name of $vm_name, from $old to $new_vm_name";
    Invoke-Command -VMName $vm_name -Credential $cred -ScriptBlock {
        Param($new_vm_name);
        Rename-Computer -NewName $new_vm_name -Restart -Force -PassThru
    } -ArgumentList $new_vm_name;
}

function Clone-HDD {
    param($new_name, $old_harddrive_path)
    $base_path = Split-Path -Path $old_harddrive_path;
    $ext = (Split-Path -Path $old_harddrive_path -Leaf).split('.')[-1 ];
    $new_harddrive_path = Join-Path $base_path ($new_name + "." + $ext) ;

    Write-Host "Copying HDD from $old_harddrive_path to $new_harddrive_path";
    Copy-Item $old_harddrive_path $new_harddrive_path;
    Write-Host "Copying HDD complete";

    return $new_harddrive_path;
}

function Rename-VMnics {
    Param($new_vm_name, $cred, $nics)
    Write-Host "Rename Nics"
    foreach ($nic in $nics) {
        $nic_name = $nic['name'];
        $nic_network = $nic['network'];
        $nic_mac = $nic['macaddress'];
        Write-Host "Finding $nic_mac renameing it to $nic_name";
        Invoke-Command -VMName $new_vm_name -Credential $cred -ScriptBlock {
            Param($nic_mac, $nic_name);
            Write-Host "Testing remote machine mac: $nic_mac name: $nic_name";
            Get-NetAdapter | ?{$_.MacAddress -eq $nic_mac} | Rename-NetAdapter -NewName $nic_name;
        } -ArgumentList @($nic_mac, $nic_name)
        # Rename-NetAdapter -Name "Ethernet" -NewName $machine['nics'][0]['name']
    }
}

function Set-VMNICS {
    Param($new_vm_name, $nics)

    Write-Host "set-vmnics getting mac addresses"

    #clean the network adapters
    Get-VMNetworkAdapter -VMName $new_vm_name | Remove-VMNetworkAdapter

    foreach ($nic in $nics) {
        $nic_name = $nic['name'];
        $nic_network = $nic['network'];
        #Add one back
        Add-VMNetworkAdapter -VMName $new_vm_name -SwitchName $nic_network -Name $nic_name -DeviceNaming On

        #Start and stop VM to get mac address, then arm the new MAC address on the NIC itself
        start-vm $new_vm_name
        sleep 5
        stop-vm $new_vm_name -Force
        sleep 5
        $MACAddress=get-VMNetworkAdapter -VMName $new_vm_name -Name $nic_name | select MacAddress -ExpandProperty MacAddress
        $MACAddress=($MACAddress -replace '(..)','$1-').trim('-')
        get-VMNetworkAdapter -VMName $new_vm_name -Name $nic_name | Set-VMNetworkAdapter -StaticMacAddress $MACAddress
        $nic['macaddress'] = $MACAddress
        Write-Host "New NIC: $nic[0]['macaddress'] $MACAddress";
    }
    # Write-Host $nics
    return $nics
}

function Set-VMHDD {
    Param($new_vm_name, $new_harddrive_path)
    # Add HD
    Add-VMHardDiskDrive -VMName $new_vm_name -ControllerType SCSI -Path $new_harddrive_path

    #Set first boot device to the disk we attached
    $Drive=Get-VMHardDiskDrive -VMName $new_vm_name | where {$_.Path -eq "$new_harddrive_path"}
    # Get-VMBios -VMName $new_vm_name | Set-VMBios @("SCSI", "Floppy", "LegacyNetworkAdapter", "CD")
    Set-VMFirmware -VMName $new_vm_name -FirstBootDevice $Drive
    return $Drive
}

function Add-UnattendToHDD {
    Param($Unattendfile, $VHDPath)

    Write-Host "Adding $Unattendfile to HDD at $VHDPath";
    #Mount the new virtual machine VHD
    mount-vhd -Path $VHDPath
    #Find the drive letter of the mounted VHD
    $VolumeDriveLetter=GET-DISKIMAGE $VHDPath | `
        GET-DISK | GET-PARTITION |get-volume | `
        ?{$_.FileSystemLabel -ne "Recovery"}|select DriveLetter -ExpandProperty DriveLetter
    #Construct the drive letter of the mounted VHD Drive
    $DriveLetter="$VolumeDriveLetter"+":"
    #Copy the unattend.xml to the drive
    Copy-Item $Unattendfile $DriveLetter\unattend.xml
    #Dismount the VHD
    Dismount-Vhd -Path $VHDPath
}

function Set-Unattend {
    Param($Name, $machine, $VHDPath, $UnattendLocation, $StartupFolder)

    # Write-Verbose $machine -Verbose
    
    #Org info
    $Organization="Munnox"
    #This ProductID is actually the AVMA key provided by MS
    $ProductID="TMJ3Y-NTRTM-FJYXT-T22BY-CWG3J"
    $IPDomain=$machine['nics'][0]['ip'];
    $IPMask=$mask;
    $MACAddress=$machine['nics'][0]['macaddress'];
    $DefaultGW=$machine['nics'][0]['gateway'];
    $DNSServer=$machine['nics'][0]['dns'];
    $DNSDomain=$machine['nics'][0]['domain'];

    #Prepare the unattend.xml file to send out, simply copy to a new file and replace values
    Copy-Item $UnattendLocation $StartupFolder\"unattend"$Name".xml"
    $DefaultXML=$StartupFolder+ "\unattend"+$Name+".xml"
    $NewXML=$StartupFolder + "\unattend$Name.xml"
    $DefaultXML=Get-Content $DefaultXML
    $DefaultXML  | Foreach-Object {
        $_ -replace '1AdminAccount', $AdminAccount `
        -replace '1Organization', $Organization `
        -replace '1Name', $Name `
        -replace '1ProductID', $ProductID`
        -replace '1MacAddressDomain',$MACAddress `
        -replace '1DefaultGW', $DefaultGW `
        -replace '1DNSServer', $DNSServer `
        -replace '1DNSDomain', $DNSDomain `
        -replace '1AdminPassword', $AdminPassword `
        -replace '1IPDomain', $IPDomain `
        -replace '1IPMask', $IPMask
        } | Set-Content $NewXML
 
    Write-Host "Copy $NewXML to the harddrive: $VHDPath"
    Write-Host "Add-UnattendToHDD $NewXML $VHDPath"
    Add-UnattendToHDD $NewXML $VHDPath


}

function Clone_VMs {
    Param($unattendxml, $unattendpath, $machines, $AdminAccount, $AdminPassword)

    Write-Host "Unattendxml: $unattendxml"
    Write-Host "Unattend path: $unattendpath"

    foreach ($machine in $machines) {
        # Name of new vm
        $new_vm_name = $machine['name'];
        # THe name of the base image to clone
        $base_vm_name = $machine['base_image'];

        # Get cpu
        $cpu = $machine['cpucount'];
        # Get memory
        $memory = $machine['memory'];

        # Get nics
        $nics = $machine['nics'];
        Write-Host $nics;
        # $network_name = $nics[0]['network'];

        # informational tag to modify behaviour
        $tags = $machine['tags'];

        # Basic Creds
        $LocalUser = "$AdminAccount"
        $LocalPassword = ConvertTo-SecureString -String $AdminPassword -AsPlainText -Force
        $LocalCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $LocalUser, $LocalPassword

        #Get base VM
        $base_vm = (Get-VM -Name $base_vm_name);

        try {
            $vm = (Get-VM -Name $new_vm_name);
        }
        catch {
            $vm = $false;
        }

        if ($vm) {
            Write-Host "New VM found Continuing"
            continue;
        }
        else {
            Write-Host "New VM not found"
        }

        # test that base image found but not new image so it wont duplicate vm's
        Write-Host $base_vm "vm: $vm" ($vm -ne $false);
        if ($base_vm -and (-not $vm)) {
            # Get HDD of base
            $old_harddrive_path = $base_vm.HardDrives.Path;

            $new_harddrive_path = Clone-HDD $new_vm_name $old_harddrive_path

            # Building VM
            Write-Host "Building VM Network=$network_name HDD=$new_harddrive_path";
            New-VM -Name $new_vm_name `
                -MemoryStartupBytes $memory `
                -NoVHD `
                -Generation $BASE_VM.Generation;

            $nics = Set-VMNICS $new_vm_name $nics

            $nic = $nics[0];
            Write-Host "NIC[0] : " $nic

            $Drive = Set-VMHDD $new_vm_name $new_harddrive_path
            Set-VM -Name $new_vm_name `
                -ProcessorCount $cpu  `
                -AutomaticStartAction Start `
                -AutomaticStopAction ShutDown `
                -AutomaticStartDelay 0k

            # Copy the Base images secure boot status to new vm
            if ((Get-VMFirmware -VMName $base_vm_name).SecureBoot -eq "Off") {
                Set-VMFirmware -VMName $new_vm_name -EnableSecureBoot Off
            }

            Try {
                $new_vm = Get-VM -Name $new_vm_name;
            }
            Catch {
            }

            if ($new_vm) {
                Write-Host "Can now start the VM $new_vm_name";

                if (($tags -icontains "windows") -and ($tags -icontains "unattend")) {
                    Write-Host "Windows detected will use unattended install"
                    Set-Unattend $new_vm_name $machine $new_harddrive_path $unattendxml $unattendpath
                }

                if ($tags -icontains "start") {
                    Start-VM -Name $new_vm_name

                    if ($tags -icontains "windows") {
                        # Write-Host "wait 50 seconds to start"
                        # sleep -Seconds 50;
                        Write-Verbose "Now testing the computer for response." -Verbose;

                        # Source <https://social.technet.microsoft.com/wiki/contents/articles/36609.windows-server-2016-unattended-installation.aspx>
                        # After the inital provisioning, we wait until PowerShell Direct is functional and working within the guest VM before moving on.
                        # Big thanks to Ben Armstrong for the below useful Wait code 
                        # Write-Verbose “Waiting for PowerShell Direct to start on VM [$DCVMName]” -Verbose
                        #     while ((icm -VMName $new_vm_name -Credential $DCLocalCredential {“Test”} -ea SilentlyContinue) -ne “Test”) {Sleep -Seconds 1}
            
                        $count = 0 # Got to 60,65,62
                        Write-Verbose “Waiting for PowerShell Direct to start on VM [$new_vm_name]” -Verbose
                        while ((icm -VMName $new_vm_name -Credential $LocalCredential {“Test”} -ea SilentlyContinue) -ne “Test”) {
                            Sleep -Seconds 1
                            $count = $count + 1;
                            Write-Host "Waiting C=$count";
                            If ($count -gt 90) { break; }
                        }
                    }
                    # Other tasks here

                    if ($tags -icontains "windows") {
                        Rename-VM $new_vm_name $LocalCredential $new_vm_name
                        
                        Rename-VMnics $new_vm_name $LocalCredential $nics
                    }
                }
            }
            else {
                Write-Host "New VM not created";
            }
        }
        else {
            Write-Host "VM not found";
        }
    }
}

function Ensure-VMSwitch {
    param($network_name, $network_type);

    $found = $false;
    $switches = Get-VMSwitch -Name $network_name;

    if ($switches) {
        Write-Host "Switch found under segment name: $network_name";
    }
    else {
        Write-Host "Switch not found under segment name: $network_name";
        New-VMSwitch -Name $network_name -SwitchType $network_type;
        Write-Host "Switch created.";
    }
}


Ensure-VMSwitch $seg_network_name $seg_network_type

Clone_VMs "$PSScriptRoot\Unattend.xml" `
    $PSScriptRoot `
    $segment['machines'] `
    $segment['admin_credentials']['username'] `
    $segment['admin_credentials']['password']