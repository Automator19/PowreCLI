# List-Snapshots-older-than-48-hours
get-snapshot -vm * | Where-Object {$_.Created -lt (Get-Date).AddDays(-1)} | Remove-Snapshot -Confirm:$false -runasync

# Find Disk Locks 
get-vm vouk* | Get-HardDisk | Where {$_.Persistence -match "IndependentNonPersistent"}|ft -Property Parent,FileName 

# Connect to Multiple vCenters 

$hosts = @(
"VCenter001.local",
"VCenter002.local",
"VCenter003.local"
);

Connect-VIServer -server $hosts

# Copy Files from Guest to Local
copy-vmguestfile -source /tmp/test.txt -destination c:\temp\jp -vm Hostname -GuestToLocal -GuestUser root -GuestPassword Password1234

# Find Host of a VM 
get-vm Hostname | select Name, @{N="VMHost";E={Get-VMhost -VM $_}}, @{N="Datastore";E={Get-Datastore -VM $_}} | format-table -autosize

# Find IP address of a VM 
get-vm $vm | ft name, @{N="NIC";E={Get-NetworkAdapter -VM $_}},@{Name="IPAddress";E={($_ | Get-VMGuest).IPAddress}},@{Name="VLAN";E={($_ | Get-NetworkAdapter).NetworkName}}
or
Get-VM | Select Name, @{N="IP Address";E={@($_.guest.IPAddress[0])}}

# Find Cluster of a VM 
get-vm $vmname | select Name, @{N="Cluster";E={Get-Cluster -VM $_}}

# Find OS of a VM 
Get-VM $vm | Sort-Object -Property Name | Get-View -Property @("Name", "Config.GuestFullName", "Guest.GuestFullName") | Select-Object -Property Name, @{N="Configured OS";E={$_.Config.GuestFullName}}, @{N="Running OS";E={$_.Guest.GuestFullName}} | ft -AutoSize

# Get Name, PowerState, CPU, Memory, Cluster, RP, Datastore, NIC, IP, VLAN, OS of the VM 
get-vm $vm | select name, PowerState, NumCPU, MemoryGB, Version, @{N="Cluster";E={Get-Cluster -VM $_}}, VMHost, @{N="ResourcePool";E={Get-ResourcePool -VM $_}},@{N="Datastore";E={Get-Datastore -VM $_}}, @{N="NIC";E={Get-NetworkAdapter -VM $_}},@{Name="IPAddress";E={($_ | Get-VMGuest).IPAddress}},@{Name="VLAN";E={($_ | Get-NetworkAdapter).NetworkName}}, @{N="RunningOS";E={$_.Guest.GuestFullname}} 

# Increse VM Disk on Windows 
Check C Driver Disk Size = Invoke-VMScript -vm %vmname% -ScriptText "wmic logicaldisk get caption,size" -GuestUser admin -GuestPassword passsword -ScriptType BAT
Check vCenter Disk = get-vm %vmname% | Get-HardDisk | select Name,CapacityGB, FileName
Set New Disk on VC = get-vm %vmname% | Get-HardDisk -name 'Hard Disk 1' | set-harddisk -CapacityGB %newdisksize% -Confirm:$false
Extend Disk on VM  = Invoke-VMScript -vm %vmname% -ScriptText "echo select vol c > c:\diskpart.txt && echo rescan >> c:\diskpart.txt && echo extend >> c:\diskpart.txt && diskpart.exe /s c:\diskpart.txt" -GuestUser admin -GuestPassword password -ScriptType BAT
Verify the new disk size = Invoke-VMScript -vm %vmname% -ScriptText "wmic logicaldisk get caption,size" -GuestUser admin -GuestPassword password -ScriptType BAT

# Invoke VM Script execute multiple lines 
$code = @'
net user /add username password
wmic useraccount where “Name='username'” set PasswordExpires=false
'@
Invoke-VMScript -VM hostname -ScriptText $code -ScriptType bat -GuestUser admin -GuestPassword password

# Find UUID of a VM 
Get-VM servername | % {$server = $_ | get-view; $server.config.uuid | select @{Name="Name";Expression={$server.name}},@{Name = "UUID";Expression={$server.config.uuid}}}

# Display all Properties of a VM 
$vm=get-view -ViewType Virtualmachine -filter @{"Name"="hostname"}

Now type $vm to see objects. Select objects and child onjects to view properties
e.g $vm.config

# Check HA Cluster Status
Get-Cluster -Name $clusterName | Get-VMHost | Select Name,@{N='State';E={$_.ExtensionData.Runtime.DasHostState.State}}

