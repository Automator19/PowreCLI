$VIServers = @("vcenter01,vcenter02")
Connect-VIServer $VIServers

$path= split-path -Parent $MyInvocation.MyCommand.Definition
$newpath = $path + ".\vms.csv"
$csv =@()
$CSV = Import-CSV -Path $newpath

foreach ($line in $csv )

{

$vmname = $line.vmname
$snapTime = get-date($line.snaptime) #17/02/20 01:45
$snapName = $line.snapname
$snapDescription =  $line.snapdescription
$snapMemory = $false
$snapQuiesce = $false
$emailAddr = $line.emailaddress

$vm = Get-VM $vmname

foreach ($VIServer in $VIServers) {

    if ($vm.Uid -like "*$VIServer*") {
        $SIServer = $VIServer
    }

}

$si = Get-View ServiceInstance -Server $SIServer
$scheduledTaskManager = Get-View $si.Content.ScheduledTaskManager -Server $SIServer
$spec = New-Object VMware.Vim.ScheduledTaskSpec
$spec.Name = "my-Snapshot",$vm.Name -join ' '
$spec.Description = $_.Description
$spec.Enabled = $true
$spec.Notification = $emailAddr
$spec.Scheduler = New-Object VMware.Vim.OnceTaskScheduler
$spec.Scheduler.runat = $snapTime
$spec.Action = New-Object VMware.Vim.MethodAction
$spec.Action.Name = "CreateSnapshot_Task"

@($snapName,$snapDescription,$snapMemory,$snapQuiesce) | %{

    $arg = New-Object VMware.Vim.MethodActionArgument
    $arg.Value = $_
    $spec.Action.Argument += $arg

}

$scheduledTaskManager.CreateObjectScheduledTask($vm.ExtensionData.MoRef, $spec)

}

#
# CSV files columns
# vmname,snaptime,snapname,snapdescription,emailaddress

<#

1)	Subtract 15 minutes from time 
          =C1-(15*(1/1440))

2)	Change Date format to from 01-Jan-2021 to  01/01/2021 

3)	Join Date and Time in a new column

        =concatenate(text(B1,"dd/mm/yyyy")&" "&text(D1,"hh:mm:ss"))


Ref: https://bettersolutions.com/excel/formulas/subtract-minutes-from-a-time.htm

#>