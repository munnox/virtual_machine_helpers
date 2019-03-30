# Source <https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/deploy/deploying-graphics-devices-using-dda>
#
# Useful external srcipt to find out what can be used <https://github.com/MicrosoftDocs/Virtualization-Documentation/blob/live/hyperv-tools/DiscreteDeviceAssignment/SurveyDDA.ps1>
#
# Author Robert Munnoch

$pnpdevs = Get-PnpDevice | Where-Object {$_.Present -eq $true} | Where-Object {$_.Class -eq "Display"}
# OR
$pnpdevs = Get-PnpDevice | Where-Object {$_.Class -like "*3D*"}

Write-Host $pnpdevs

$pnpdev = $pnpdevs[0]

$name = "DL-Host"

$locationpath = ($pnpdev | Get-PnpDeviceProperty DEVPKEY_Device_LocationPaths).data[0]

Write-Host $locationpath

# Prepare VM

Set-VM -Name $name -AutomaticStopAction TurnOff
Set-VM -VMName $name -GuestControlledCacheTypes $true

Set-VM -VMName $name -LowMemoryMappedIoSpace 3GB -VMName $name
Set-VM -VMName $name -HighMemoryMappedIoSpace 8GB -VMName $name

# Disable on local host and attach to VM
Dismount-VmHostAssignableDevice -locationpath $locationpath -force
Disable-PnpDevice -InstanceId $pnpdev.InstanceId -Confirm:$false
Add-VMAssignableDevice -locationpath $locationpath -VMname $name


# see the connected devices
Get-VMAssignableDevice -VMName $name


# Disable VM and attach to local host
Remove-VMAssignableDevice -location $locationpath -vmname $name
Mount-VMHostAssignableDevice -LocationPath $locationPath
Enable-PnpDevice -InstanceID $pnpdev.InstanceID -Confirm:$false


# see the connected devices
Get-VMAssignableDevice -VMName $name