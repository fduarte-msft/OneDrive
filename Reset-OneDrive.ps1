$script:sourceName = [string]::Empty
$script:sourceName = 'Contoso Global'

$script:targetName = [string]::Empty
$script:targetName = 'CGI'

# Purpose : Get and stop OneDrive.exe process
# Result  : Stops OneDrive.exe before removing any configurations
Get-Process -Name "*onedrive*" -ErrorAction SilentlyContinue | Stop-Process -Verbose -Force -ErrorAction SilentlyContinue

# Purpose : Recursively remove the subcontent from %LOCALAPPDATA%\Microsoft\OneDrive
# Result  :  Removes any existing OneDrive configuraiton
$script:odLocalAppDataSubPath = [string]::Empty
$script:odLocalAppDataSubPath = Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Microsoft\OneDrive'
Remove-Item $odLocalAppDataSubPath -Recurse -Force -Verbose -ErrorAction SilentlyContinue 

# Purpose : Recursively remove the subcontent from %LOCALAPPDATA%\OneDrive
# Result  :  Removes any existing OneDrive configuraiton
$script:odLocalAppDataPath = [string]::Empty
$script:odLocalAppDataPath = Join-Path -Path $env:LOCALAPPDATA -ChildPath 'OneDrive'
Remove-Item $script:odLocalAppDataPath -Recurse -Force -Verbose -ErrorAction SilentlyContinue 

# Purpose : Create variables that hold source and target path
# Result  :  Initiate empty string variable place holders to store source and target paths
$script:odSourcePath = [string]::Empty
$script:odTargetPath = [string]::Empty
 
# Purpose : Populate variables with source and target paths
# Result  :  These variables will be used to rename OneDrive folder paths
$script:odSourcePath = "$($env:USERPROFILE)\Microsoft OneDrive - $($script:sourceName)"
$script:odTargetPath = "$($env:USERPROFILE)\Microsoft OneDrive - $($script:targetName)"

# Purpose : Rename source OneDrive path name
# Result  :  Source OneDrive path will be renamed to target OneDrive path
Rename-Item $script:odSourcePath -NewName $script:odTargetPath -Force -Verbose -ErrorAction SilentlyContinue

# Purpose : Remove OneDrive related registry entries form current user hive
# Result  : Any existing OneDrive configurations will be removed from the current user hive
Remove-Item "HKCU:\Software\Microsoft\OneDrive\*" -Recurse -Force -Verbose -ErrorAction SilentlyContinue
Remove-Item "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\*" -Recurse -Force -Verbose -ErrorAction SilentlyContinue
Remove-Item "HKCU:\Software\SyncEngines\Providers\OneDrive\*" -Recurse -Force -Verbose -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKCU:\Environment" -Name "OneDrive" -Force -Verbose -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKCU:\Environment" -Name "OneDriveCommercial" -Force -Verbose -ErrorAction SilentlyContinue
Remove-Item "HKCU:\Software\Classes\CLSID\{04271989*}\*" -Recurse -Force -Verbose -ErrorAction SilentlyContinue 
Remove-Item "HKCU:\Software\Classes\WOW6432Node\CLSID\{04271989*}\*" -Recurse -Force -Verbose -ErrorAction SilentlyContinue
Remove-Item "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{04271989*}\*" -Recurse -Force -Verbose -ErrorAction SilentlyContinue

# Purpose : Initiate empty string variables to build OneDrive command line
# Result  : Empty string variables will created
$script:userUPN = [string]::Empty
$script:powerShellFilePath = [string]::Empty
$script:powerShellParameters = [string]::Empty

# Purpose : Populate commandline variables
# Result  : Empty variables will be populated with values necessary to start OneDrive
$script:userUPN = & {whoami /upn}
$script:powerShellFilePath = Join-Path -Path $PSHOME -ChildPath 'powershell.exe'
$script:powerShellParameters = "Start-Process `"adopen://sync?useremail=`"$($script:userUPN)`""

# Purpose : Create has table for splatting the parameters to Start-Process
# Result  : The hash table will be populated with the necessary variables to launch OneDrive
$script:powerShellSplat = [hashtable]@{}
$script:powerShellSplat = @{
    FilePath = $script:powerShellFilePath
    ArgumentList = $script:powerShellParameters
}

Start-Process @script:powerShellSplat