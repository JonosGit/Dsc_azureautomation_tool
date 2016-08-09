<#
.SYNOPSIS
Written By John N Lewis
v 1.6
This script provides an automated deployment capability for DSC and Azure Automation.

.DESCRIPTION
Provides framework for deploying DSC to Azure Automation

.PARAMETER containerName

.PARAMETER ResourceGroupName

.PARAMETER StorageName

.PARAMETER thisfolder

.PARAMETER localfolder

.PARAMETER destfolder

.PARAMETER ContentLink

.PARAMETER AutoAcctName

.PARAMETER modulename

.PARAMETER InformationAction

.PARAMETER InformationVariable

.EXAMPLE

#>


param(
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$containerName = "dsc",
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$ResourceGroupName = "",
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$StorageName = "",
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
$ContentLink = "",
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$AutoAcctName = "",
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$modulename = "xWebAdministration"
)
### Authenticate to Microsoft Azure using Microsoft Account (MSA) or Azure Active Directory (AAD)

Function NewModule {
$module = $modulename
$content = $ContentLink
New-AzureRmAutomationModule -Name $module -ContentLink $content -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutoAcctName
}

Function VerifyProfile {
$ProfileFile = ""
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
Remove-AzureRmAutomationModule -Name $module -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutoAcctName -Force -Confirm $false
}
VerifyProfile
### Create an Azure Resource Manager (ARM) Resource Group
$ResourceGroup = @{
Name = $ResourceGroupName;
Location = 'EastUs2';
Force = $true;
}
New-AzureRmResourceGroup @ResourceGroup;

$StorageAccount = @{
    ResourceGroupName = $ResourceGroupName;
    Name = $StorageName;
    SkuName = 'Standard_LRS';
    Location = 'EastUS2';
    }
New-AzureRmStorageAccount @StorageAccount;

### Obtain the Storage Account authentication keys using Azure Resource Manager (ARM)
$Keys = Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageName;

### Use the Azure.Storage module to create a Storage Authentication Context
$StorageContext = New-AzureStorageContext -StorageAccountName $StorageName -StorageAccountKey $Keys[0].Value -ErrorAction SilentlyContinue;

### Create a Blob Container in the Storage Account
New-AzureStorageContainer -Context $StorageContext -Name dsc -ErrorAction SilentlyContinue;

### Upload a file to the Microsoft Azure Storage Blob Container

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

### Deploy Modules to Automation Acct

NewModule

