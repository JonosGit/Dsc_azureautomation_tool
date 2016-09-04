<#
.SYNOPSIS
Written By John N Lewis
v 1.7
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
$ResourceGroupName = "auto-dsc",
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[bool]
$CreateStorage = $True,
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[bool]
$CreateAzAutoAcct = $False,
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$StorageName = "aiptblvg1",
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$thisfolder = "C:\Templates",
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$localfolder = "$thisfolder\dsc",
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$destfolder = "Modules",
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$ContentLink = "https://$StorageName.blob.core.windows.net/dsc/Modules/$modulename.zip",
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$AutoAcctName = "dscauto",
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$Location = 'EastUs2',
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$Action = 'Ne',
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$modulename = "xWebAdministration"
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

Function VerifyProfile {
$ProfileFile = "c:\Temp\live.json"
$fileexist = Test-Path $ProfileFile
  if($fileexist)
  {Write-Host "Profile Found"
  Select-AzureRmProfile -Path $ProfileFile
  }
  else
  {
  Write-Host "Please enter your credentials"
  Add-AzureRmAccount
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
	}
New-AzureRmStorageAccount @StorageAccount;

### Obtain the Storage Account authentication keys using Azure Resource Manager (ARM)
$Keys = Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageName;

### Use the Azure.Storage module to create a Storage Authentication Context
$StorageContext = New-AzureStorageContext -StorageAccountName $StorageName -StorageAccountKey $Keys[0].Value -ErrorAction SilentlyContinue;

### Create a Blob Container in the Storage Account
New-AzureStorageContainer -Context $StorageContext -Name dsc -ErrorAction SilentlyContinue;

### Upload files to the Microsoft Azure Storage Blob Container

$storageAccountKey = Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageName;
$blobContext = New-AzureStorageContext -StorageAccountName $StorageName -StorageAccountKey $Keys[0].Value -ErrorAction SilentlyContinue;
$files = Get-ChildItem $localFolder
foreach($file in $files)
{
  $fileName = "$localFolder\$file"
  $blobName = "$destfolder/$file"
  write-host "copying $fileName to $blobName"
  Set-AzureStorageBlobContent -File $filename -Container $containerName -Blob $blobName -Context $blobContext -Force -ErrorAction Stop
}
write-host "All files in $localFolder uploaded to $containerName!"
}

Function NewModule {
$module = $modulename
$content = $ContentLink
New-AzureRmAutomationModule -Name $module -ContentLink $content -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutoAcctName
}

Function SetModule {
$module = $modulename
$content = $ContentLink
Set-AzureRmAutomationModule -Name $module -ContentLinkUri $content -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutoAcctName
}

Function RemoveModule {
$module = $modulename
Remove-AzureRmAutomationModule -Name $module -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutoAcctName -Force -Confirm:$false
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

VerifyProfile
### Create an Azure Resource Manager (ARM) Resource Group
$ResourceGroup = @{
Name = $ResourceGroupName;
Location = $Location;
Force = $true;
}
New-AzureRmResourceGroup @ResourceGroup;

if($CreateAzAutoAcct) {AddAzAutoAccount}
if($CreateStorage) {
StorageNameCheck
NewStorage
}
ExecutionAction