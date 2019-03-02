# Very simple script to take an existing base image and clone it
# This pull the hdd generation and network from the original
#
# Author Robert Munnoch

$base_image="vws";
$BASE_VM = (Get-VM -Name $base_image)
$network_name = $BASE_VM.NetworkAdapters[0].SwitchName

$new_name = "vm-image";
$memory = 4GB;

$old_harddrive_path = $BASE_VM.HardDrives.Path;
$base_path = Split-Path -Path $old_harddrive_path;
$ext = (Split-Path -Path $old_harddrive_path -Leaf).split('.')[1];
$new_harddrive_path = Join-Path $base_path ($new_name + "." + $ext) ;

Write-Host "Copying HDD from $old_harddrive_path to $new_harddrive_path";
Copy-Item $old_harddrive_path $new_harddrive_path;
Write-Host "Copying HDD complete";

Write-Host "Building VM Network=$network_name HDD=$new_harddrive_path";
New-VM -Name $new_name -SwitchName $network_name -VHDPath $new_harddrive_path -MemoryStartupBytes $memory -Generation $BASE_VM.Generation;

$NEW_VM = Get-VM -Name $new_name
