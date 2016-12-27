<#
.SYNOPSIS
Written By John N Lewis
v 1.9
This script provides an automated deployment capability for DSC and Azure Automation.

.DESCRIPTION
Provides framework for deploying DSC to Azure Automation. Creates New Automation Account, Creates Storage Account, Uploads Modules to Azure Automation for utilization.

.PARAMETER containerName

.PARAMETER ResourceGroupName

.PARAMETER StorageName

.PARAMETER thisfolder

.PARAMETER localfolder

.PARAMETER destfolder

.PARAMETER ContentLink

.PARAMETER AutoAcctName

.PARAMETER modulename

.PARAMETER Location

.PARAMETER Action

.EXAMPLE

#>

param(
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$containerName = "dsc",
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$ResourceGroupName = "tstaz",
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[bool]
$CreateStorage = $True,
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[bool]
$CreateAzAutoAcct = $False,
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$StorageName = "aiptbhjb1",
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$thisfolder = "C:\Temp",
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$localfolder = "$thisfolder\Zip",
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$destfolder = "Modules",
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$ContentLink = "https://$StorageName.blob.core.windows.net/dsc/Modules/$modulename.zip",
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$AutoAcctName = "azauto",
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$Location = 'EastUs2',
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$Profile = "profile",
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[ValidateSet("New","Set","remove")]
[string]
$Action = 'New',
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
$modulename = @('xNetworking','xComputerManagement','xWindowsUpdate','xWebAdministration','xSQLServer','xStorage','xRobocopy','xPSDesiredStateConfiguration','xDSCDomainJoin','xActiveDirectory','xNetworking','xSCOM','xCredSSP','xAzure','xSCOM','SharePointDsc','NxNetworking','Nx','xPendingReboot','xCertificate',' xRemoteDesktopAdmin','xDnsServer','xDhcpServer','NuGet','xExchange','xSqlIps','xWebDeploy','xDatabase','xDisk','xReleaseManagement','xAzure','xWinEventLog','xFailOverCluster','xOU','xBitlocker','xAdcsDeployment','cSQLConfig','PowerShellModule','xDfS','xDSCFireWall','vscode','BiztalkServer','PSDscResources','ChocolateyGet','AU','cChoco','cChoco-testing')
)
### Authenticate to Microsoft Azure using Microsoft Account (MSA) or Azure Active Directory (AAD)

Function StorageNameCheck
{
$checkname =  Get-AzureRmStorageAccountNameAvailability -Name $StorageName | Select-Object -ExpandProperty NameAvailable
if($checkname -ne 'True') {
Write-Host "Storage Account Name in use, please choose a different name for your storage account"
Start-Sleep 5
exit
}
}

Function validate-profile {
$comparedate = (Get-Date).AddDays(-14)
$fileexist = Test-Path $ProfileFile -NewerThan $comparedate
  if($fileexist)
  {
  Select-AzureRmProfile -Path $ProfileFile | Out-Null
		Write-Host "Using $ProfileFile"
  }
  else
  {
  Write-Host "Please enter your credentials"
  Add-AzureRmAccount
  Save-AzureRmProfile -Path $ProfileFile -Force
  Write-Host "Saved Profile to $ProfileFile"
  exit
  }
}

Function AddAzAutoAccount {
New-AzureRmAutomationAccount -Location $Location -ResourceGroupName $resourceGroupName -Name $AutoAcctName -Plan Free -WarningAction SilentlyContinue
}

Function NewStorage {
$StorageAccount = @{
	ResourceGroupName = $ResourceGroupName;
	Name = $StorageName;
	SkuName = 'Standard_LRS';
	Location = $Location;
	ErrorAction = 'SilentlyContinue';
	Warningaction = 'SilentlyContinue';
	}
New-AzureRmStorageAccount @StorageAccount;

### Obtain the Storage Account authentication keys using Azure Resource Manager (ARM)
$Keys = Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageName;

### Use the Azure.Storage module to create a Storage Authentication Context
$StorageContext = New-AzureStorageContext -StorageAccountName $StorageName -StorageAccountKey $Keys[0].Value -ErrorAction SilentlyContinue;

### Create a Blob Container in the Storage Account
New-AzureStorageContainer -Context $StorageContext -Name dsc -Permission Blob -ErrorAction SilentlyContinue;
### Upload files to the Microsoft Azure Storage Blob Container
}

Function Upload-Files {
$Keys = Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageName;
$StorageContext = New-AzureStorageContext -StorageAccountName $StorageName -StorageAccountKey $Keys[0].Value -ErrorAction SilentlyContinue;
$storageAccountKey = Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageName;
$blobContext = New-AzureStorageContext -StorageAccountName $StorageName -StorageAccountKey $Keys[0].Value -ErrorAction SilentlyContinue;
$files = Get-ChildItem $localFolder
foreach($file in $files)
{
  $fileName = "$localFolder\$file"
  $blobName = "$destfolder/$file"
  write-host "copying $fileName to $blobName"
  Set-AzureStorageBlobContent -File $filename -Container $containerName -Blob $blobName -Context $blobContext -Force -ErrorAction Stop -Confirm:$False
}
write-host "All files in $localFolder uploaded to $containerName!"
}

Function NewModule {
$modulename = @('xNetworking','xComputerManagement','xWindowsUpdate','xWebAdministration','xSQLServer','xStorage','xRobocopy','xPSDesiredStateConfiguration','xDSCDomainJoin','xActiveDirectory','xNetworking','xSCOM','xCredSSP','xAzure','xSCOM','SharePointDsc','NxNetworking','Nx','xPendingReboot','xCertificate',' xRemoteDesktopAdmin','xDnsServer','xDhcpServer','NuGet','xExchange','xSqlIps','xWebDeploy','xDatabase','xDisk','xReleaseManagement','xAzure','xWinEventLog','xFailOverCluster','xOU','xBitlocker','xAdcsDeployment','cSQLConfig','PowerShellModule','xDfS','xDSCFireWall','vscode','BiztalkServer','PSDscResources','ChocolateyGet','AU','cChoco','cChoco-testing');

foreach($module in $modulename)
{
[psobject]$content = "https://$StorageName.blob.core.windows.net/dsc/Modules/$module.zip"
New-AzureRmAutomationModule -Name $module -ContentLink $content -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutoAcctName
}
}

Function SetModule {
$modulename = @('xNetworking','xComputerManagement','xWindowsUpdate','xWebAdministration','xSQLServer','xStorage','xRobocopy','xPSDesiredStateConfiguration','xDSCDomainJoin','xActiveDirectory','xNetworking','xSCOM','xCredSSP','xAzure','xSCOM','SharePointDsc','NxNetworking','Nx','xPendingReboot','xCertificate',' xRemoteDesktopAdmin','xDnsServer','xDhcpServer','NuGet','xExchange','xSqlIps','xWebDeploy','xDatabase','xDisk','xReleaseManagement','xAzure','xWinEventLog','xFailOverCluster','xOU','xBitlocker','xAdcsDeployment','cSQLConfig','PowerShellModule','xDfS','xDSCFireWall','vscode','BiztalkServer','PSDscResources','ChocolateyGet','AU','cChoco','cChoco-testing');
foreach($module in $modulename)
{
[psobject]$content = '\.$module.zip'
Set-AzureRmAutomationModule -Name $module -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutoAcctName
}
}

Function RemoveModule {
$modulename = @('xNetworking','xComputerManagement','xWindowsUpdate','xWebAdministration','xSQLServer','xStorage','xRobocopy','xPSDesiredStateConfiguration','xDSCDomainJoin','xActiveDirectory','xNetworking','xSCOM','xCredSSP','xAzure','xSCOM','SharePointDsc','NxNetworking','Nx','xPendingReboot','xCertificate',' xRemoteDesktopAdmin','xDnsServer','xDhcpServer','NuGet','xExchange','xSqlIps','xWebDeploy','xDatabase','xDisk','xReleaseManagement','xAzure','xWinEventLog','xFailOverCluster','xOU','xBitlocker','xAdcsDeployment','cSQLConfig','PowerShellModule','xDfS','xDSCFireWall','vscode','BiztalkServer','PSDscResources','ChocolateyGet','AU','cChoco','cChoco-testing');

foreach($module in $modulename)
{
Remove-AzureRmAutomationModule -Name $module -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutoAcctName -Force -Confirm:$false
}
}

Function ExecutionAction {
switch  ($Action)
	{
		"New" {
NewModule
}
		"Remove" {
RemoveModule
}
		"Set" {
SetModule
}
		default{"An unsupported action was referenced"
		break
					}
}
}

$workfolder = Split-Path $script:MyInvocation.MyCommand.Path
$ProfileFile = $workfolder+'\'+$profile+'.json'

validate-profile
### Create an Azure Resource Manager (ARM) Resource Group
$ResourceGroup = @{
Name = $ResourceGroupName;
Location = $Location;
Force = $true;
}
New-AzureRmResourceGroup @ResourceGroup;

if($CreateAzAutoAcct) {AddAzAutoAccount}
if($CreateStorage) {
NewStorage }

Upload-Files
ExecutionAction