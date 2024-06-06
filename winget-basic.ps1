# Inspired by Kugane, Edited by Jacob
#

### Here can you add apps that you want to configure during installation ###
# just add the app id from winget
$graphical = @(
    "ClamWin.ClamWin"
);

### These apps are installed silently for all users ###
# for msstore apps you need to specify the source like below

$apps = @(
	"AutoHotkey.AutoHotkey"
	"DEVCOM.JetBrainsMonoNerdFont"
	"JetBrains.Rider"
	"glzr-io.glazewm"
	"GNU.Emacs"
	"Neovim.Neovim"
	"Spotify.Spotify"
	"Vivaldi.Vivaldi"
	"XP8LFCZM790F6B"	# Visual Studio Code Insiders"
	"9WZDNCRDK3WP"		# Slack
);

$bloatware = @(
    # default Windows 11 apps
    "Microsoft.Todos"
    "Microsoft.PowerAutomateDesktop"
    "Microsoft.WindowsCamera"
    "MicrosoftCorporationII.QuickAssist"

    # Windows 11 23h2
    #"Microsoft.OutlookForWindows"
    #"Microsoft.Windows.DevHomeAzureExtension"           # DEV Home
    #"Microsoft.Windows.Ai.Copilot.Provider"         # Copilot

    # default Windows 10 apps
    "Microsoft.549981C3F5F10"           # Cortana Offline
    "Microsoft.BingNews"
    "Microsoft.BingWeather"
    "Microsoft.MicrosoftOfficeHub"
    "Microsoft.People"
    "microsoft.windowscommunicationsapps"          # Mail and Calender     
    "Microsoft.WindowsMaps"
    "Microsoft.WindowsSoundRecorder"
    "Microsoft.ZuneVideo"
    "Microsoft.YourPhone"
    "Microsoft.ZuneMusic"          # New Media Player in Windows

    # Xbox Apps
    "Microsoft.GamingApp"
    "Microsoft.Xbox.TCUI"
    "Microsoft.XboxGameOverlay"
    "Microsoft.XboxSpeechToTextOverlay"
    "Microsoft.XboxGamingOverlay"
    "Microsoft.XboxIdentityProvider"
    "Microsoft.XboxSpeechToTextOverlay"

    # Threshold 2 apps
    "Microsoft.GetHelp"
    "Microsoft.Getstarted"
    "Microsoft.WindowsFeedbackHub"
);

#############################################################################################
################################ Don't change anything below ################################
#############################################################################################

### Install WinGet ###
# Idea from this gist: https://gist.github.com/crutkas/6c2096eae387e544bd05cde246f23901
$hasPackageManager = Get-AppxPackage -Name 'Microsoft.Winget.Source' | Select Name, Version
$hasVCLibs = Get-AppxPackage -Name 'Microsoft.VCLibs.140.00.UWPDesktop' | Select Name, Version
$hasXAML = Get-AppxPackage -Name 'Microsoft.UI.Xaml.2.7*' | Select Name, Version
$hasAppInstaller = Get-AppxPackage -Name 'Microsoft.DesktopAppInstaller' | Select Name, Version
$DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
$errorlog = "$DesktopPath\winget_error.log"

function install_winget {
    Clear-Host
    Write-Host -ForegroundColor Yellow "Checking if WinGet is installed"
    if (!$hasPackageManager) {
            if ($hasVCLibs.Version -lt "14.0.30035.0") {
                Write-Host -ForegroundColor Yellow "Installing VCLibs dependencies..."
                Add-AppxPackage -Path "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
                Write-Host -ForegroundColor Green "VCLibs dependencies successfully installed."
            }
            else {
                Write-Host -ForegroundColor Green "VCLibs is already installed. Skip..."
            }
            if ($hasXAML.Version -lt "7.2203.17001.0") {
                Write-Host -ForegroundColor Yellow "Installing XAML dependencies..."
                Add-AppxPackage -Path "https://github.com/Kugane/winget/raw/main/Microsoft.UI.Xaml.2.7_7.2203.17001.0_x64__8wekyb3d8bbwe.Appx"
                Write-Host -ForegroundColor Green "XAML dependencies successfully installed."
            }
            else {
                Write-Host -ForegroundColor Green "XAML is already installed. Skip..."
            }
            if ($hasAppInstaller.Version -lt "1.16.12653.0") {
                Write-Host -ForegroundColor Yellow "Installing WinGet..."
    	        $releases_url = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
    		    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls13
    		    $releases = Invoke-RestMethod -Uri "$($releases_url)"
    		    $latestRelease = $releases.assets | Where-Object { $_.browser_download_url.EndsWith("msixbundle") } | Select-Object -First 1
    		    Add-AppxPackage -Path $latestRelease.browser_download_url
                Write-Host -ForegroundColor Green "WinGet successfully installed."
            }
    }
    else {
        Write-Host -ForegroundColor Green "WinGet is already installed. Skip..."
        Write-Host ""
        }
    Pause
}

### Install Apps with GUI ###
# Idea from this gist: https://gist.github.com/Codebytes/29bf18015f6e93fca9421df73c6e512c
function install_gui {
    Clear-Host
    Write-Host -ForegroundColor Cyan "Installing new Apps wit GUI"
    Foreach ($gui in $graphical) {
        $listGUI = winget list --exact --accept-source-agreements -q $gui
        if (![String]::Join("", $listGUI).Contains($gui)) {
            Write-Host -ForegroundColor Yellow "Install:" $gui
            winget install --exact --interactive --accept-source-agreements --accept-package-agreements $gui
            if ($LASTEXITCODE -eq 0) {
                Write-Host -ForegroundColor Green "$gui successfully installed."
            }
            else {
                "$gui couldn't be installed." | Add-Content $errorlog
                Write-Warning "$gui couldn't be installed."
                Write-Host -ForegroundColor Yellow "Write in $errorlog"
                Pause
            }
        }
        else {
            Write-Host -ForegroundColor Yellow "$gui already installed. Skip..."
        }
    }
    Pause
}

### Install Apps silent ###
function install_silent {
    Clear-Host
    Write-Host -ForegroundColor Cyan "Installing new Apps"
    Foreach ($app in $apps) {
        $listApp = winget list --exact --accept-source-agreements -q $app
        if (![String]::Join("", $listApp).Contains($app)) {
            Write-Host -ForegroundColor Yellow  "Install:" $app
            # MS Store apps
            if ((winget search --exact -q $app) -match "msstore") {
                winget install --exact --silent --accept-source-agreements --accept-package-agreements $app --source msstore
            }
            # All other Apps
            else {
                winget install --exact --silent --scope machine --accept-source-agreements --accept-package-agreements $app
            }
            if ($LASTEXITCODE -eq 0) {
                Write-Host -ForegroundColor Green "$app successfully installed."
            }
            else {
                $app + " couldn't be installed." | Add-Content $errorlog
                Write-Warning "$app couldn't be installed."
                Write-Host -ForegroundColor Yellow "Write in $errorlog"
                Pause
            }  
        }
        else {
            Write-Host -ForegroundColor Yellow "$app already installed. Skip..."
        }
    }
    Pause
}

### Debloating ###
# Based on this gist: https://github.com/W4RH4WK/Debloat-Windows-10/blob/master/scripts/remove-default-apps.ps1
function debloating {
    Clear-Host
    Write-Host -ForegroundColor Cyan "Removing bloatware..."
    Foreach ($blt in $bloatware) {
        $package = Get-AppxPackage -AllUsers $blt
        if ($package -ne $null) {
            Write-Host -ForegroundColor Red "Removing: $blt"
            $package | Remove-AppxPackage
        } else {
            Write-Host "$blt not found. Skip..."
        }
    }
    Pause
}

### Register Taskjob ###
function taskjob {
    $taskname = 'WinGet AutoUpgrade & Cleanup'
    Write-Host -ForegroundColor Yellow "Checking for Taskjob..."
    if ($(Get-ScheduledTask -TaskName $taskname -ErrorAction SilentlyContinue).TaskName -eq $taskname) {
        Write-Host -ForegroundColor Yellow "Taskjob already exists. Do you want to update to newer version? (y/n)"
        $update = Read-Host
        if ($update -eq 'y' -or $update -eq 'Y') {
            Unregister-ScheduledTask -TaskName $taskname -Confirm:$False -ErrorAction SilentlyContinue
            Write-Host -ForegroundColor Yellow "Taskjob updating..."
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls13
            Invoke-WebRequest -Uri https://github.com/Kugane/winget/raw/main/WinGet%20AutoUpgrade%20%26%20Cleanup.xml -OutFile '$taskjob' 
            Register-ScheduledTask -xml (Get-Content '$taskjob' | Out-String) -TaskName $taskname
            Write-Host -ForegroundColor Green "Taskjob successfully updated."
            Pause
            Clear-Host
        }
        else {
            Write-Warning "Taskjob not updated."
            Pause
            Clear-Host
        }
    }
    else {
        Write-Host -ForegroundColor Yellow "Installing taskjob..."
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls13
        Invoke-WebRequest -Uri https://github.com/Kugane/winget/raw/main/WinGet%20AutoUpgrade%20%26%20Cleanup.xml -OutFile '$taskjob' 
        Register-ScheduledTask -xml (Get-Content '$taskjob' | Out-String) -TaskName $taskname
        Write-Host -ForegroundColor Green "Taskjob successfully installed."
        Pause
        Clear-Host
    }
    Pause
    Clear-Host
}

### Get List of installed Apps ###
function get_list {
    Clear-Host
    $newPath = ("$DesktopPath\applist_$env:COMPUTERNAME" + "_" + $(Get-Date -Format 'yyyy_MM_dd') + ".txt")
    Write-Host -ForegroundColor Yellow "Generating Applist..."
    winget list > $newPath
    Write-Host -ForegroundColor Magenta "List saved in $newPath"
}

### Finished ###
function finish {
    Write-Host
    Write-Host -ForegroundColor Magenta  "Installation finished"
    Write-Host
    Pause
}

function check_rights {
    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
    {
        Write-Warning "The script needs to be executed with administrator privileges."
        Break
    }
}

### Question what to do ###
function menu {
    [string]$Title = 'Winget Menu'
    Clear-Host
    Write-Host "================ $Title ================"
    Write-Host
    Write-Host "1: Do all steps below"
    Write-Host
    Write-Host "2: Just install winget"
    Write-Host
    Write-Host "3: Install Apps under graphical"
    Write-Host "4: Install Apps under apps"
    Write-Host "5: Remove bloatware"
    Write-Host
    Write-Host "6: Install Taskjob for automatic updates"
    Write-Host "7: Get List of all installed Apps"
    Write-Host
    Write-Host -ForegroundColor Magenta "0: Quit"
    Write-Host
 
    $actions = "0"
    while ($actions -notin "0..7") {
    $actions = Read-Host -Prompt 'What you want to do?'
        if ($actions -in 0..7) {
            if ($actions -eq 0) {
                exit
            }
            if ($actions -eq 1) {
                install_winget
                install_gui
                install_silent
                debloating
                taskjob
                finish
            }
            if ($actions -eq 2) {
                install_winget
                finish
            }
            if ($actions -eq 3) {
                install_winget
                install_gui
                finish
            }
            if ($actions -eq 4) {
                install_winget
                install_silent
                finish
            }
            if ($actions -eq 5) {
                debloating
                finish
            }
            if ($actions -eq 6) {
                taskjob
                finish
            }
            if ($actions -eq 7) {
                install_winget
                get_list
            }
            menu
        }
        else {
            menu
        }
    }
}
check_rights
menu
