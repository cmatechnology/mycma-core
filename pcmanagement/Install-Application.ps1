function Install-Application {
    param (
        $packageid,
        $InstallOptions
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

    $choco_version = choco --version
    if($choco_version.StartsWith("2")){
    $choco_install = choco list
    }
    else {
    $choco_install = choco list -lo  
    }

    Write-Host ""
    Write-Host "#########################"
    Write-Host "CHOCO INSTALL PACKAGEID: $packageid"

    $source = 'https://pkgs.dev.azure.com/cmatechnologyprojects/Chocolatey/_packaging/mycma/nuget/v2/'

    if($installoptions) {
    Write-Host "INSTALL OPTIONS: $installoptions"
    #$choco_output = choco.exe upgrade $package --source $source --yes --no-progress --allowemptychecksum --params $installoptions
    choco.exe upgrade $packageid --source $source --yes --no-progress --allowemptychecksum --params $installoptions
    } else {
    #$choco_output = choco.exe upgrade $package --source $source --yes --no-progress --allowemptychecksum
    choco.exe upgrade $packageid --source $source --yes --no-progress --allowemptychecksum
    }   
    $ExitCode = $LASTEXITCODE

    if ($ExitCode -eq 0) {
        Write-Host "Installed $packageid"
    }
    elseif ($ExitCode -ne 0) {
        Write-Error "Failed to install $packageid."
        Write-Host $choco_output
        Write-Host "Installer returned exit code: $($ExitCode)"
    }



    
}