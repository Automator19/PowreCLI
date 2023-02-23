
$path = split-path -Parent $MyInvocation.MyCommand.Definition
$newpath = $path + ".\vms.csv"
$csv = @()
$CSV = Import-CSV -Path $newpath
$timestamp = Get-Date -format yyyy.MM.dd-hh.mm.ss

#set-powercliconfiguration -InvalidCertificateAction Ignore -Confirm:$false

Connect-VIServer -server servername

foreach ($line in $csv) {
    $vmname = $line.vm
    $description = $line.description
    New-Snapshot -vm $vmname -Memory:$false -confirm:$false -name $description -RunAsync
}