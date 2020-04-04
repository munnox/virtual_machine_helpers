<# This form was created using POSHGUI.com  a free online gui designer for PowerShell
.NAME
    Basic CLone GUI
#>

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '400,400'
$Form.text                       = "Form"
$Form.TopMost                    = $false

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "Initial VM:"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(18,18)
$Label1.Font                     = 'Microsoft Sans Serif,10'

$Label2                          = New-Object system.Windows.Forms.Label
$Label2.text                     = "target VM:"
$Label2.AutoSize                 = $true
$Label2.width                    = 25
$Label2.height                   = 10
$Label2.location                 = New-Object System.Drawing.Point(19,49)
$Label2.Font                     = 'Microsoft Sans Serif,10'

$InitialVMName                   = New-Object system.Windows.Forms.TextBox
$InitialVMName.multiline         = $false
$InitialVMName.width             = 170
$InitialVMName.height            = 20
$InitialVMName.location          = New-Object System.Drawing.Point(100,14)
$InitialVMName.Font              = 'Microsoft Sans Serif,10'

$ComboBox1                       = New-Object system.Windows.Forms.ComboBox
$ComboBox1.text                  = "comboBox"
$ComboBox1.width                 = 100
$ComboBox1.height                = 20
$ComboBox1.location              = New-Object System.Drawing.Point(35,126)
$ComboBox1.Font                  = 'Microsoft Sans Serif,10'

$TargetVMName                    = New-Object system.Windows.Forms.TextBox
$TargetVMName.multiline          = $false
$TargetVMName.width              = 169
$TargetVMName.height             = 20
$TargetVMName.location           = New-Object System.Drawing.Point(100,46)
$TargetVMName.Font               = 'Microsoft Sans Serif,10'

$CloneButton                     = New-Object system.Windows.Forms.Button
$CloneButton.text                = "button"
$CloneButton.width               = 257
$CloneButton.height              = 30
$CloneButton.location            = New-Object System.Drawing.Point(11,84)
$CloneButton.Font                = 'Microsoft Sans Serif,10'

$Form.controls.AddRange(@($Label1,$Label2,$InitialVMName,$ComboBox1,$TargetVMName,$CloneButton))

$CloneButton.Add_Click({ CloneVM $this $_ })

function CloneVM ($sender,$event) {
    Write-Host "Cloning Machine $sender, $event";
}


#Write your logic code here

[void]$Form.ShowDialog()