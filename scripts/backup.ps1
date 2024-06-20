#rsync -aAXv --delete --exclude=".[!.]*"  ~/ rsync://huis.duijzer.com/$rsyncdir

# VARIABLES
$rsyncdir = "windows"
$rsyncSource = "~/Documents"
$rsyncDestination = "rsync://huis.duijzer.com/$rsyncdir"
$networkAdapter = "Ethernet"

# CHECK OF rsync IS AVAILABLE
if (-not (Get-Command rsync -ErrorAction SilentlyContinue)) {
    Write-Output "rsync command not found. Please install rsync."
    exit 1
}

# CHECK IF NETWORK IS CONNECTED
$networkCheck = Get-NetAdapter | Where-Object { $_.Name -eq "$networkAdapter" -and $_.Status -eq "Up" }
if (-not $networkCheck) {
	Write-Output "Network not connected, skipping backup."
	exit 1
}

# CHECK If POWER IS CONNECTED
$power = Get-WmiObject -Query "SELECT * FROM Win32_Battery"
if ($power.Availability -ne 2) {
	Write-Output "Power is not connected, skipping backup."
	exit 1
}

Write-Output "Network connected, power connected, starting backup."

# PERFORMING rsync OPERATION
$rsyncArgs = "-aAXv --delete --exclude='.[!.]*' $rsyncSource $rsyncDestination"
Start-Process rsync -ArgumentList $rsyncArgs -NoNewWindow -Wait

Write-Output "Sync completed succesfully."
