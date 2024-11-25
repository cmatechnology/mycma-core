Function Build-PrinterPackage {
    param (
        [Parameter(Mandatory = $true)] [string] $DriverName,
        [Parameter(Mandatory = $false)] [string] $DriverVersion,
        [Parameter(Mandatory = $false)] [string] $ChocolatelyPackageVersion
     )
     #Printer Driver Name
     #Printer Driver Version (Used when Multiple Versions of the Same Driver Are Installed)
     #CHOCOLATELY PACKAGE VERSION
     
     
     $oemdrivers = Get-WindowsDriver -Online
     #Filter out just printer drivers
     $oemdrivers = $oemdrivers | Where-Object { $_.classname -eq "Printer" }
     
     $WindowsPrinterDriver = $null
     $DriverVersions = @()
     foreach($d in $oemdrivers){
       #$dInfo = Get-WindowsDriver -Online -Driver $d.Driver
       #2024-08-21 - Found this was failing but script continued causing errors.
       try {
         $dInfo = Get-WindowsDriver -Online -Driver $d.Driver
       }
       catch {
         continue
       }  
       if($dInfo.HardwareDescription.Contains($DriverName) -and ($d.Version -eq $DriverVersion -or (!($DriverVersion))) ){
         if(-Not $DriverVersions.Contains($d.Version)){
           $DriverVersions += $d.Version
           $infPath = Split-Path -Path @($dInfo.OriginalFileName)[0] -Parent
           $WindowsPrinterDriver = New-Object PSObject -Property @{
             ofn = @($dInfo.OriginalFileName)[0]
             infpath =  $infPath
             packageid = $(Split-Path (Split-Path -Path $d.OriginalFileName -Parent) -Leaf)
             version =  $d.ManufacturerName + " " + $d.Version
             summary = $(@($dInfo.HardwareDescription) | Out-String)
             tags = $(@($dInfo.HardwareDescription.Replace(" ","_")) | Out-String)
             packageversion = "1.0.0.0"
           }
         }
       }
     }
     
     if($DriverVersions.Length -eq 0)
     {
         Write-Error "Printer Driver Not Found"
         return
     }
     if($DriverVersions.Length -gt 1)
     {
         $err = $DriverVersions -join '),('
         $msg = "Multiple Driver Versions Found " + "($err)" + "  Please select the appropriate driver version and try again."
         Write-Error $msg
         return
     }
     
     if($ChocolatelyPackageVersion) {
       $WindowsPrinterDriver.packageversion = $ChocolatelyPackageVersion
     }
     
     $nuspec = @"
     <?xml version="1.0" encoding="utf-8"?>
     <package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
     <metadata>
     <id>{{packageid}}</id>
     <version>{{packageversion}}</version>
     <title>mycma</title>
     <authors>mycma</authors>
     <projectUrl>https://www.mycma.com</projectUrl>
     <tags>{{tags}}</tags>
     <summary>{{summary}}</summary>
     <description>{{version}}</description>
     </metadata>
     <files>
     <file src="tools\**" target="tools" />
     </files>
     </package>
"@
     
     $nuspec = $nuspec.Trim()
     
     $chocoinstall = @'
     $toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
     $appPath = "$env:SystemRoot\system32\pnputil.exe"
     $cmdBatch = "-a `"$toolsDir\inf\*.inf`""
     Start-ChocolateyProcessAsAdmin -Statements $cmdBatch -ExeToRun $appPath
'@
     
     $chocoinstall = $chocoinstall.Trim()
     
     $packageid = "printer_" + $WindowsPrinterDriver.packageid.ToLower()
     
     $nuspec = $nuspec.Replace("{{packageid}}", $packageid)
     $nuspec = $nuspec.Replace("{{packageversion}}", $WindowsPrinterDriver.packageversion)
     $nuspec = $nuspec.Replace("{{version}}", $WindowsPrinterDriver.version)
     $nuspec = $nuspec.Replace("{{summary}}", $WindowsPrinterDriver.summary)
     $nuspec = $nuspec.Replace("{{tags}}", $WindowsPrinterDriver.tags)
     
     $null = [System.IO.Directory]::CreateDirectory("c:\temp")
     $packageDir = 'C:\temp\' + $packageid
     Set-Location C:\Temp
     
     $null = Remove-Item -Path $packageDir -Recurse -Force -ErrorAction SilentlyContinue
     $null = New-Item -ItemType Directory -Path "$packageDir\tools"
     $null = New-Item -ItemType Directory -Path "$packageDir\tools\inf"
     
     
     $null = Out-File -InputObject $nuspec -FilePath "$packageDir\$packageid.nuspec"
     $null = Out-File -InputObject $chocoInstall -FilePath "$packageDir\tools\chocolateyinstall.ps1"
     
     $infPath =  $WindowsPrinterDriver.infpath
     $null = Copy-Item -Path "$infPath\*" -Destination "$packageDir\tools\inf" -Recurse
     
     Write-Host "Package Created:  Execute ""choco pack $packageDir\$packageid.nuspec"""
     
     #BUILD THE PACKAGE
     & "choco" "pack" "$packageDir\$packageid.nuspec"
     
}