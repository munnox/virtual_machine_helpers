# Very simple script to take an existing base image and clone it
# This pull the hdd generation and network from the original.
#
# Now makes multiple VM from a list of names with the same characteristics.
# Also renames them after creation with a basic admin account setup below.
#
# Author Robert Munnoch

$base_image="vm-image";
$BASE_VM = (Get-VM -Name $base_image)
$network_name = $BASE_VM.NetworkAdapters[0].SwitchName

$new_names = @(“vm-host1", "vm-host2");
$memory = 8GB;

#User name and Password
$AdminAccount="Administrator"
$AdminPassword="passw0rd!"

function Rename-VM {
    Param($cred, $vm_name, $new_vm_name)

    $old = Invoke-Command -VMName $vm_name -Credential $cred -ScriptBlock { $env:COMPUTERNAME };
    Write-Host "Changing name of $vm_name, from $old to $new_vm_name";
    Invoke-Command -VMName $vm_name -Credential $cred -ScriptBlock {
        Param($new_vm_name);
        Rename-Computer -NewName $new_vm_name -Restart -Force -PassThru
    } -ArgumentList $new_vm_name;
}


foreach ($new_name in $new_names) {
    
    $old_harddrive_path = $BASE_VM.HardDrives.Path;
    $base_path = Split-Path -Path $old_harddrive_path;
    $ext = (Split-Path -Path $old_harddrive_path -Leaf).split('.')[1];
    $new_harddrive_path = Join-Path $base_path ($new_name + "." + $ext) ;

    $LocalUser = "$AdminAccount"
    $LocalPassword = ConvertTo-SecureString -String $AdminPassword -AsPlainText -Force
    $LocalCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $LocalUser, $LocalPassword


    Write-Host "Copying HDD from $old_harddrive_path to $new_harddrive_path";
    Copy-Item $old_harddrive_path $new_harddrive_path;
    Write-Host "Copying HDD complete";

    Write-Host "Building VM Network=$network_name HDD=$new_harddrive_path";
    New-VM -Name $new_name -SwitchName $network_name -VHDPath $new_harddrive_path -MemoryStartupBytes $memory -Generation $BASE_VM.Generation;

    Start-VM -Name $new_name

    # Write-Host "wait 50 seconds to start"
    # sleep -Seconds 50;
    Write-Verbose "Now testing the computer for response." -Verbose;

    # Source <https://social.technet.microsoft.com/wiki/contents/articles/36609.windows-server-2016-unattended-installation.aspx>
    # After the inital provisioning, we wait until PowerShell Direct is functional and working within the guest VM before moving on.
    # Big thanks to Ben Armstrong for the below useful Wait code 
    # Write-Verbose “Waiting for PowerShell Direct to start on VM [$DCVMName]” -Verbose
    #     while ((icm -VMName $new_vm_name -Credential $DCLocalCredential {“Test”} -ea SilentlyContinue) -ne “Test”) {Sleep -Seconds 1}
            
    $count = 0 # Got to 60,65,62
    Write-Verbose “Waiting for PowerShell Direct to start on VM [$new_name]” -Verbose
    while ((icm -VMName $new_name -Credential $LocalCredential {“Test”} -ea SilentlyContinue) -ne “Test”) {
        Sleep -Seconds 1
        $count = $count + 1;
        Write-Host "Waiting C=$count";
        If ($count -gt 90) { break; }
    }

    Rename-VM $LocalCredential $new_name $new_name
}