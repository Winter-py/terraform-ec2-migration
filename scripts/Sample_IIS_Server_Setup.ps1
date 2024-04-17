<#
This is a sample script used to configure Windows Server 2022 with IIS and applications and tools. 
#>


# Install IIS features
Install-WindowsFeature -name Web-Server -IncludeManagementTools



#This Enables TLS 1.3 since it's not enabled by default 
try {
    if (!(Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3')) {
    New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3' -Force | Out-Null
    New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Client' -Force | Out-Null
    New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Server' -Force | Out-Null
}

    # Create Enabled DWORD value and set it to 1
    New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Client' -Name 'Enabled' -Value '1' -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Server' -Name 'Enabled' -Value '1' -PropertyType DWORD -Force | Out-Null

    Write-Host 'TLS 1.3 has been enabled for SCHANNEL.'
}
catch {
    Write-Host 'TLS 1.3 has been not been enabled for SCHANNEL.'
}


#Setup SQL Connection for SSMS

$sqlscript = @"
USE [master]
GO
IF NOT EXISTS
(SELECT name FROM master.sys.server_principals WHERE name = 'BUILTIN\Users')
BEGIN
CREATE LOGIN [BUILTIN\Users] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]
END
GO
"@

$sqlauth = @"
USE master;
GO
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2;
GO
"@

$sqlauth | Set-Content $ENV:TEMP\auth.sql
$sqlscript | Set-Content $ENV:TEMP\master.sql
$EXITCODE = sqlcmd.exe -S localhost -E -i $ENV:TEMP\master.sql
$AUTHCODE = sqlcmd.exe -S localhost -E -i $ENV:TEMP\auth.sql

if($EXITCODE -ne 0){
    Write-Host "Database command status good: $EXITCODE"
}else {
    Write-Error "Somthing went wrong"
}

if($AUTHCODE -ne 0){
    Write-Host "Database command status good: $EXITCODE"
}else {
    Write-Error "Somthing went wrong"
}

Write-Host "IIS Cleaning up"
Import-Module WebAdministration
Remove-WebSite -Name "Default Web Site"
Remove-WebAppPool -Name "DefaultAppPool"
Remove-WebAppPool -Name ".NET v4.5"
Remove-WebAppPool ".NET v4.5 Classic"


Write-Host "Downloading Maintenance Solution"

If(-not(test-path -PathType Container $Tools)){
    New-Item -ItemType Directory -Path $Tools | Out-Null 
}

Invoke-WebRequest -Uri "https://ola.hallengren.com/scripts/MaintenanceSolution.sql" -OutFile "C:\Tools\MaintenanceSolution.sql"

$MaintenaceSolution = sqlcmd.exe -S localhost -E -i "C:\Tools\MaintenanceSolution.sql"

if($MaintenaceSolution -ne 0){
    Write-Host "Database command status good: $MaintenaceSolution"
}else {
    Write-Error "Somthing went wrong"
}