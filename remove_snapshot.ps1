$path= split-path -Parent $MyInvocation.MyCommand.Definition
$newpath = $path + ".\vms.csv"
$csv =@()
$CSV = Import-CSV -Path $newpath

Connect-VIServer -Server servername

foreach ($line in $csv)
{
  $vm=$line.vm
  try { $out = Get-snapshot -vm $vm | Remove-Snapshot -runasync -confirm:$false }
  catch { Write-Output "$vmname - $($_.Exception.Message)"}
}