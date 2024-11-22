function Install-Printer {
    param (
        $PrinterName,
        $Package,
        $DriverName,
        $IPAddress,
        $Color,
        $Collate,
        $Duplex
    )

    if (!(Test-Path($env:ChocolateyInstall + "\choco.exe"))) {
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }
    
    $ver = Get-CimInstance -Class Win32_OperatingSystem | ForEach-Object -MemberName Caption
    #NO PRINTERS FOR OLD SYSTEMS
    if($ver.Trim() -eq "Microsoft Windows 7 Professional") { return; }
    if($ver.Trim() -eq "Microsoft Windows Server 2008 R2 Standard") { return; }
    
    #FIRST CASE CHOCO PATH IS NOT IN PROFILE.  AFTER REBOOT IT'S OK
    $pathSplit = $env:path -split ';'
    if(-Not $pathSplit.Contains("C:\ProgramData\chocolatey\bin")){
      Write-Host "Adding env:Path C:\ProgramData\chocolatey\bin"
      $env:path += ";C:\ProgramData\chocolatey\bin"  
    }

    #IF THE DRIVER IS FROM MICROSOFT WE DON'T NEED TO INSTALL.  IT'S ALREADY ON THE SYSTEM
    if(-Not $package.ToLower().Contains("microsoft")){
        $source = 'https://pkgs.dev.azure.com/cmatechnologyprojects/Chocolatey/_packaging/mycma/nuget/v2/'
        $choco_output = choco.exe upgrade $package --source $source --yes --no-progress
        $ExitCode = $LASTEXITCODE
        
        if ($ExitCode -eq 0) {
            Write-Host "Installed $package"
        }
        elseif ($ExitCode -ne 0) {
            Write-Error "Failed to install $package."
            Write-Host $choco_output
            Write-Host "Installer returned exit code: $($ExitCode)"
        }
    }    


    #GET THE LOCAL PRINTER INFORMATION
    $deviceDrivers = Get-PrinterDriver
    $devicePorts = Get-PrinterPort
    $devicePrinters = @()
    foreach ($p in (Get-Printer)){
        $dp = New-Object PSObject -Property @{ name = $p.Name; driver = $p.DriverName; port = $p.PortName; ipaddress = ""; collate = 0; color = 0; duplex = 0 }
        $printConfig = Get-PrintConfiguration -PrinterName $p.Name -ErrorAction SilentlyContinue
        if($printConfig){
            $dp.collate = $printConfig.Collate
            $dp.color = $printConfig.Color
            $dp.duplex = $printConfig.DuplexingMode
        }
        $printPort = $ports | Where-Object { $_.Name -eq $p.PortName } 
        if ($printPort -And $printPort.PrinterHostAddress) {
            $dp.ipaddress = $printPort.PrinterHostAddress
        }
        $devicePrinters += $dp
    }

  Write-Host "#########################"
  Write-Host "Installing Printer: $printerName"
  #ADD PRINTER DRIVER
  $driver = $deviceDrivers | Where-Object { $_.Name -eq $driverName }
  if(-Not $driver) {
    Add-PrinterDriver -Name $drivername
  }
  
  #ADD PRINTER PORT
  $portName = "CMA_$ipaddress"
  $port = $devicePorts | Where-Object { $_.Name -eq $portName }
  if(-Not $port){
    Add-PrinterPort -Name $portName -PrinterHostAddress $ipaddress
  }
  
  #ADD PRINTER
  $color = [int]$color
  $collate = [int]$collate
  $duplex = [int]$duplex

  $printer = $devicePrinters | Where-Object { $_.Name -eq $printerName }
  if(-Not $printer) {
    Add-Printer -Name $printerName -DriverName $drivername -PortName $portName
    Set-PrintConfiguration -PrinterName $printerName -Collate $collate -Color $color -DuplexingMode $duplex
  }
  else {
    #DRIVER CHANGE
    if($printer.driver -ne $drivername) {
      Write-Host "Updating Driver $drivername"
      Set-Printer -Name $printerName -DriverName $drivername
    }
    #PORT/IPADDRESS CHANGE
    if($printer.port -ne $portName) {
      Write-Host "Updating Port/IP Address $portName"
      Set-Printer -Name $printerName -PortName $portName
    }
    #CONFIGURATION CHANGE
    if(-Not ($printer.color -eq $color -And $printer.collate -eq $collate -And $printer.duplex -eq $duplex)){
      Write-Host "Updating Color: $color Collate: $collate Duplex: $duplex"
      Set-PrintConfiguration -PrinterName $printerName -Collate $collate -Color $color -DuplexingMode $duplex
    }
    Write-Host "Printer Installed/Configured: $printerName"
  }

}