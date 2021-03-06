# Daniel Jean Schmidt
# Last updated: 10/03/2021

# This script is going to set up an AD server, with minimal effort as an administrator.
# The script will replicate itself from Github, and will continue after reboots. 
# It will clean up after itself when done installing.

#
# Configure these options here
#

# Servername
$ServerName = "DomainController01"
# Domain
$DomainName = "Viemoseintern.nu"
$Domainnetbiosname = "VIEMOSEINTERN"
$SafeModeAdministratorPassword = ConvertTo-SecureString "Twikkibanan25!" -AsPlainText -Force
# Network
$ServerIP = '192.168.0.235'
$ServerMask = '24'
$ServerGateway = '192.168.0.1'
$ServerPrimaryDNS = '8.8.8.8'
$ServerSecondaryDNS = '8.8.4.4'
$ipif = (Get-NetAdapter).ifIndex


#########
#########
#########

# FUNCTIONS that is used throughout the script.

# Initial step ( Replicate scripts to local server from Github )
Function Replicate
{
    # Downloads the automated script file from Github
    $Replicate = Invoke-WebRequest https://raw.githubusercontent.com/Twikki/Powershell_Scripts/master/Build_Domain.ps1
    Set-Content -Path 'C:\Scripts\Build_Domain.ps1' -Value $Replicate

    # Downloads the CMD file from Github
    $Replicatetwo = Invoke-WebRequest https://raw.githubusercontent.com/Twikki/Powershell_Scripts/master/RunPowershell.cmd
    Set-Content -Path 'C:\Users\Administrator\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\RunPowershell.cmd' -Value $Replicatetwo
}


# Step 1
function RenameServer 
{
    Set-Content $ProgressPath -Value 1
    Rename-Computer -NewName "$ServerName" -Force -Restart
}


# Step 2
function InstallAD 
{

# Sets the server's ip address, subnetmask and Gateway
#New-NetIPAddress -InterfaceIndex $ipif -IPAddress $ServerIP -PrefixLength $ServerMask -DefaultGateway $ServerGateway

# From Microsoft
New-NetIPAddress -IPAddress $ServerIP -PrefixLength $ServerMask ` -InterfaceIndex $ipif -DefaultGateway $ServerGateway

# Sets the server's DNS 
Set-DnsClientServerAddress -InterfaceIndex $ipif -ServerAddresses ($ServerPrimaryDNS,$ServerSecondaryDNS)

Write-Host 'Static ip and DNS has been set. Starting installation of AD' -ForegroundColor Green

# Installs the AD Domain services
Install-windowsfeature -name AD-Domain-Services -IncludeManagementTools

# Imports the modules needed
Import-Module ADDSDeployment

Write-Host 'AD Modules has been installed and imported. Beginning installation' -ForegroundColor Green

# Installs AD
Install-ADDSForest -DomainName $Domainname -DomainNetbiosName $Domainnamebios -DomainMode WinThreshold -ForestMode WinThreshold -CreateDnsDelegation:$false -DatabasePath "C:\Windows\NTDS" -InstallDns:$true -LogPath "C:\Windows\NTDS" -NoRebootOnCompletion:$false -SysvolPath "C:\Windows\SYSVOL" -Force:$true -SafeModeAdministratorPassword:$SafeModeAdministratorPassword
 
 
Set-Content $ProgressPath -Value 2
}



# Logic starts here

# Checks if folder "AutoUpdates already exists on the server. If it doesn't it creates it."
$ChkPath = "C:\Scripts"
$PathExists = Test-Path $ChkPath
If ($PathExists -eq $false)
{
    mkdir C:\Scripts
}



$ProgressPath = "C:\Progress.txt"

$ChkFile = "C:\Progress.txt"
$FileExists = Test-Path $ChkFile
If ($FileExists -eq $false)
{
    Replicate
    New-Item -ItemType "file" -Path $ProgressPath
    Set-Content $ProgressPath -Value 0
}


# Reads the file for status
# This is the logic used to control the installation status of the server.
$Status = Get-Content $ProgressPath -First 1

If ($Status -eq 0) 
{
    # Renames the server
    RenameServer
}
elseif ($Status -eq 1)
{
    # Begins to install Active Directory Services
    InstallAD
}