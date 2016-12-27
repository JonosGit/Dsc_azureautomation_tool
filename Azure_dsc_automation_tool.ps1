<#
.SYNOPSIS
Written By John N Lewis
v 1.8
This script provides an automated deployment capability for DSC and Azure Automation.

.DESCRIPTION
Provides framework for deploying DSC to Azure Automation

.PARAMETER AutoAcctName

.PARAMETER VMName

.PARAMETER NodeName

.PARAMETER ConfigurationName

.PARAMETER VMresourceGroupName

.PARAMETER resourceGroupName

.PARAMETER locadmin

.PARAMETER locpassword

.PARAMETER Location

.PARAMETER VMLocation

.PARAMETER containerName

.PARAMETER thisfolder

.PARAMETER localfolder

.PARAMETER destfolder

.PARAMETER OutputFolder

.PARAMETER SourcePath

.PARAMETER nodeconfigpath

.PARAMETER SubscriptionID

.PARAMETER TenantID

.PARAMETER StorageName

.PARAMETER StorageType

.PARAMETER Action

.EXAMPLE

.EXAMPLE

.NOTES

#>

[CmdletBinding()]
Param(
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[ValidateSet("RegisterDSCNode","CompileJob","ExportConfig","AddAzAccount","ExportConfigreport","GetMetadata","ImportConfig","ImportNodeConfig")]
[string]
$Action = 'ImportConfig',

[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true,Position=0)]
[string]
$AutoAcctName = "omsauto",

[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true,Position=2)]
[string]
$VMName = "dc101",

[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$NodeName = $VMNAME,

[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$ConfigurationName = "PDC",

[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true,Position=1)]
[string]
$resourceGroupName = "oms",

[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true,Position=1)]
[string]
$VMresourceGroupName = "dcstest",

[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$locadmin = 'localadmin',

[Parameter(Mandatory=$False)]
[string]
$locpassword = 'P@ssW0rd!',

[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$Location = "EastUs2",

[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$VMLocation = "EastUs",
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$containerName = "dsc",
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$thisfolder = "c:\Temp",
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$localfolder = "$thisfolder\dsc",
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$destfolder = "dsc",
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$OutputFolder = "$thisfolder\dsc",
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$SourcePath = -join "$thisfolder\dsc\PDC.ps1",
[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$nodeconfigpath = "$thisfolder\dsc",

[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$SubscriptionID = '',

[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$TenantID = '',

[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[bool]
$CreateStorage = $False,

[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[bool]
$CreateAzAutoAcct = $False,

[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$StorageName = $VMName + 'str',

[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$true)]
[string]
$StorageType = "Standard_LRS"

)
# Global
# $ErrorActionPreference = "SilentlyContinue"
$date = Get-Date -UFormat "%Y-%m-%d-%H-%M"
$workfolder = Split-Path $script:MyInvocation.MyCommand.Path

Function StorageNameCheck
{
$checkname =  Get-AzureRmStorageAccountNameAvailability -Name $StorageName | Select-Object -ExpandProperty NameAvailable
if($checkname -ne 'True') {
Write-Host "Storage Account Name in use, please choose a different name for your storage account"
Start-Sleep 5
break
}
}

Function CreateStorage {
Write-Host "Starting Storage Creation.."
$StorageAccount = New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageName.ToLower() -Type $StorageType -Location $Location -ErrorAction Stop -WarningAction SilentlyContinue
#Get-AzureRmStorageAccount -Name $StorageName.ToLower() -ResourceGroupName $ResourceGroupName -WarningAction SilentlyContinue | ft "StorageAccountName" -OutVariable $stracct
Write-Host "Completed Storage Creation" -ForegroundColor White
} # Creates Storage

Function VerifyProfile {
$ProfileFile = "C:\Users\admin\Source\InProg\AIP_ARM\deploy\live.json"
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

Function RegisterAutoDSC {
				$ActionAfterReboot = 'ContinueConfiguration'
				$configmode = 'ApplyAndAutocorrect'
				$AutoAcctName = $Azautoacct
				$NodeName = $VMName
				$autorg = 'OMS'
				$config = "$ConfigurationName.$VMName"

				Register-AzureRmAutomationDscNode -AutomationAccountName $AutoAcctName -AzureVMName $VMName -ActionAfterReboot $ActionAfterReboot -ConfigurationMode $configmode -RebootNodeIfNeeded $True -ResourceGroupName $autorg -NodeConfigurationName $config -AzureVMLocation $Location -AzureVMResourceGroup $resourceGroupName -Verbose | Out-Null
}

Function UnRegisterAutoDSC {
param(
$Id = $VMName,
$VMresourceGroupName = $VMresourceGroupName,
$AutoAcctName = $AutoAcctName
)

Unregister-AzureRmAutomationDscNode -AutomationAccountName $AutoAcctName -Id $AzureVMName -ResourceGroupName $resourceGroupName -Force -Confirm $False
}

Function ExportConfig {
Export-AzureRmAutomationDscConfiguration -Name $ConfigurationName -OutputFolder $OutputFolder -AutomationAccountName $AutoAcctName -ResourceGroupName $resourceGroupName -Force -Confirm:$False
}
Function ExportConfigreport {
Export-AzureRmAutomationDscNodeReportContent -NodeId $NodeName -ResourceGroupName $resourceGroupName -AutomationAccountName $AutoAcctName -OutputFolder $OutputFolder -ReportId
}

Function ImportConfig {
Import-AzureRmAutomationDscConfiguration -SourcePath $SourcePath -ResourceGroupName $resourceGroupName -AutomationAccountName $AutoAcctName -Published -Force -Confirm:$False
}
Function ImportNodeConfig {
Import-AzureRmAutomationDscNodeConfiguration -Path $nodeconfigpath -ConfigurationName $ConfigurationName -AutomationAccountName $AutoAcctName -ResourceGroupName $resourceGroupName
}
Function GetMetadata {
Get-AzureRmAutomationDscOnboardingMetaconfig -AutomationAccountName $AutoAcctName -ResourceGroupName $ResourceGroupName
}
Function CompileJob {
$ConfigData = @{
	AllNodes = @(
		@{
			NodeName = "*"
			PSDscAllowPlainTextPassword = $True
			PSDscAllowDomainUser = $true
		},
		@{
			NodeName = "$VMName"
		}
	)
}

Start-AzureRmAutomationDscCompilationJob -ResourceGroupName $resourceGroupName -AutomationAccountName $AutoAcctName -ConfigurationName $ConfigurationName -ConfigurationData $ConfigData
}
Function AddAzAutoAccount {
New-AzureRmAutomationAccount -Location $Location -ResourceGroupName $resourceGroupName -Name $AutoAcctName -Plan Free -WarningAction SilentlyContinue
}

Function ExecutionAction {
switch  ($Action)
	{
		"AddAzAccount" {
AddAzAutoAccount
}
		"RegisterDSCNode" {
Register-AzureRmAutomationDscNode
}
		"ImportConfig" {
ImportConfig
}
		"ImportNodeConfig" {
ImportNodeConfig
}
		"GetMetadata" {
GetMetadata
}
		"CompileJob" {
CompileJob
}
		"ExportConfig" {
ExportConfigreport
}
		"ExportConfigReport" {
ExportConfig
}
		default{"An unsupported action was referenced"
		break
					}
}
}

VerifyProfile
try {
Get-AzureRmResourceGroup -Location $Location -ErrorAction Stop
}
catch {
	Write-Host -foregroundcolor Yellow `
	"User has not authenticated, use Add-AzureRmAccount or $($_.Exception.Message)"; `
	continue
}

New-AzureRmResourceGroup -Name $resourceGroupName -Location $Location -Force -Confirm:$False
if($CreateAzAutoAcct) {AddAzAutoAccount}
if($CreateStorage) {
StorageNameCheck
NewStorage
}

ExecutionAction

Get-AzureRmAutomationAccount -AutomationAccountName $AutoAcctName -ResourceGroupName $ResourceGroupName
 Write-Host "------------------------------------------------------------------------------"#
Get-AzureRmAutomationDscCompilationJob -AutomationAccountName $AutoAcctName -ResourceGroupName $ResourceGroupName | ft ConfigurationName
 Write-Host "------------------------------------------------------------------------------"
Get-AzureRmAutomationDscNode -AutomationAccountName $AutoAcctName -ResourceGroupName $ResourceGroupName | ft Name, NodeConfigurationName
Write-Host "------------------------------------------------------------------------------"
Get-AzureRmAutomationDscConfiguration -AutomationAccountName $AutoAcctName -ResourceGroupName $ResourceGroupName | ft Name, State