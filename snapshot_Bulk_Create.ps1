$path= split-path -Parent $MyInvocation.MyCommand.Definition
$newpath = $path + ".\rmsnapshot.csv"
$csv =@()
$CSV = Import-CSV -Path $newpath

Connect-VIServer -server VCenterServer 

foreach ($line in $csv)

    {
        $vm=$line.vm
        New-Snapshot -vm $vm -Memory:$false -confirm:$false -name "Type-Description" -runasync
    }