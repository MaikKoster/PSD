<#
.SYNOPSIS

.DESCRIPTION

.LINK

.NOTES
          FileName: PSDDrivers.ps1
          Solution: PowerShell Deployment for MDT
          Purpose: Download and install drivers
          Author: PSD Development Team
          Contact: @Mikael_Nystrom , @jarwidmark , @mniehaus , @SoupAtWork , @JordanTheItGuy
          Primary: @Mikael_Nystrom 
          Created: 
          Modified: 2019-06-02

          Version - 0.0.0 - () - Finalized functional version 1.
          Version - 0.0.1 - () - Changed BaseDriverPath = "PSDResources\DriverPackages", to "fit" the new folder structure


          TODO:
          Add support for PNP

.Example
#>

param (

)

# Load core modules
Import-Module Microsoft.BDD.TaskSequenceModule -Scope Global
Import-Module DISM
Import-Module PSDUtility
Import-Module PSDDeploymentShare

# Check for debug in PowerShell and TSEnv
if($TSEnv:PSDDebug -eq "YES"){
    $Global:PSDDebug = $true
}
if($PSDDebug -eq $true)
{
    $verbosePreference = "Continue"
}
Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Load core modules"

# Building source and destionation paths based on model DriverGroup001
$BaseDriverPath = "PSDResources\DriverPackages"
$SourceDriverPackagePath = ($BaseDriverPath + "\" + ($tsenv:DriverGroup001).Replace("\"," - ")).replace(" ","_")
Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): tsenv:DriverGroup001 is $($tsenv:DriverGroup001)"
Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): SourceDriverPackagePath is now $SourceDriverPackagePath"

#Copy drivers to cache
Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Copy $SourceDriverPackagePath to cache "
Get-PSDContent -content $SourceDriverPackagePath

#Get all ZIP files from the cache
Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Getting drivers..."
$Zips = Get-ChildItem -Path "$($tsenv:OSVolume):\MININT\Cache\DriverPackages" -Filter *.zip -Recurse

#Did we find any?
Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Found $($Zips.count) packages"
Foreach($Zip in $Zips)
{
    Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Unpacking $($Zip.FullName)"
    #Need to use this method, since the assemblys can not be loaded due to a issue...
    Start PowerShell -ArgumentList "Expand-Archive -Path $($Zip.FullName) -DestinationPath $($tsenv:OSVolume):\Drivers -Force -Verbose" -Wait
}

Start-Sleep -Seconds 1

#What do we have here
Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Get list of drivers from \Drivers"
$Drivers = Get-ChildItem -Path "$($tsenv:OSVolume):\Drivers" -Filter *.inf -Recurse
foreach($Driver in $Drivers){
    Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): $($Driver.Name) is now in the \Drivers folder"
    $TSxDriverInfo = Get-PSDDriverInfo -Path $Driver.FullName
    Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Driverinfo: Name:$($TSxDriverInfo.Name)  Vendor:$($TSxDriverInfo.Manufacturer)  Class:$($TSxDriverInfo.Class)  Date:$($TSxDriverInfo.Date)  Version:$($TSxDriverInfo.Version)"
}
