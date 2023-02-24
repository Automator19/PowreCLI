Connect-VIServer -Server vcenter01,vcenter02
$esx_hosts = Get-VMHost * | where {$_.ConnectionState -ne “NotResponding”}

foreach ($esx_host in $esx_hosts) {
Write-Host $esx_host -ForegroundColor Green
$esxcli = (get-vmhost $esx_host) | get-esxcli -v2

$arguments1 = $esxcli.system.account.add.CreateArgs()
$arguments1.id = "username"
$arguments1.password = "password" 
$arguments1.passwordconfirmation = "password"
$arguments1.description = "description"
$arguments1

$esxcli.system.account.add.Invoke($arguments1)

$arguments2 = $esxcli.system.permission.set.CreateArgs()
$arguments2.id = ‘username’
$arguments2.role = ‘Admin’
$arguments2

$esxcli.system.permission.set.Invoke($arguments2)
}