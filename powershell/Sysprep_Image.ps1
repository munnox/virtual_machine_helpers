# Sysprep an image

# VM Image name
$name = "vws";

# Basic Creds
$LocalUser = "$name\Administrator"
$LocalPassword = ConvertTo-SecureString -String "passw0rd!" -AsPlainText -Force
$LocalCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $LocalUser, $LocalPassword

# Invoke the sysprep command on the remote VM using the credentials above
Invoke-Command -VMName $name -Credential $LocalCredential -ScriptBlock {
    C:\Windows\System32\Sysprep\sysprep.exe /generalize /oobe /shutdown
} -Verbose