Param (  
    [Parameter(Mandatory = $True)][string]$Tenantname,
    [Parameter(Mandatory = $True)][string]$ApplicationID,
    [Parameter(Mandatory = $True)][string]$ApplicationSecret,
    [Parameter(Mandatory = $True,HelpMessage='The ID of the group to which config policies will be assigned')][string]$GroupID,
    [Parameter(Mandatory = $false)][switch]$SkipAndroidConfig,
    [Parameter(Mandatory = $false)][switch]$SkipAndroidEnterpriseConfig,
    [Parameter(Mandatory = $false)][switch]$SkipMacOSConfig,
    [Parameter(Mandatory = $false)][switch]$SkipiOSConfig,
    [Parameter(Mandatory = $false)][switch]$SkipWin10Config,
    [Parameter(Mandatory = $false)][switch]$SkipMacOSEndpointConfig,
    [Parameter(Mandatory = $false)][switch]$SkipWin10EndpointConfig
)  
 
Write-Verbose "Runbook started"
#region Part 1

#########################################################################################
#
#       Part 1 - Getting data and token
#
#########################################################################################

#Getting token from Graph
Write-Verbose "Composing body for token request"
try {
    $ReqTokenBody = @{
        Grant_Type    = "client_credentials"
        Scope         = "https://graph.microsoft.com/.default"
        client_Id     = $ApplicationID
        Client_Secret = $ApplicationSecret
    }
    Write-Verbose "Body composed"
}

catch {
    Write-Verbose "Failed to compose body"
    Write-Output $Error[0]
    throw "Failed to compose body"
}

Write-Verbose "Invoking rest method to get token from graph"
try {
    $TokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$($Tenantname)/oauth2/v2.0/token" -Method POST -Body $ReqTokenBody
    Write-Verbose "Got token"
}

catch {
    Write-Verbose "Failed to get token"
    Write-Output $Error[0]
    throw "Failed to get token"
}

Write-Verbose "Setting headerParams"
$headerParams = @{
    'Authorization' = "Bearer $($TokenResponse.access_token)"
    'Content-Type' = "application/json"
}

Write-Verbose "Finished with part 1"
#endregion

#region Part 2
#########################################################################################
#
#       Part 2 - Setting configuration policies
#
#########################################################################################

#Defining URI variable for config policy creation
Write-Verbose "Defining URI variable for config policy creation"
$GraphURIforCreateConfigPolicy = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations"

#Composing JSON object for config policy assignment
Write-Verbose "Composing JSON object for config policy assignment"
$JSONforConfigAssignment = @'
{
    "@odata.type": "#microsoft.graph.deviceConfigurationAssignment",
    "target": {
      "@odata.type": "microsoft.graph.groupAssignmentTarget",
      "deviceAndAppManagementAssignmentFilterId": null,
      "deviceAndAppManagementAssignmentFilterType": "none",
      "groupId": "
'@

$JSONforConfigAssignment = $JSONforConfigAssignment + $GroupID
$JSONforConfigAssignment = $JSONforConfigAssignment + @'
"
    }
}
'@

if (!($SkipMacOSConfig)) {
#region macOS

#Composing JSON object for macOS config policy
Write-Verbose "Composing JSON object for macOS"
$JSONformacOS = @'
{
    "@odata.type": "#microsoft.graph.macOSGeneralDeviceConfiguration",
    "description": null,
    "displayName": "macOS - Device Restrictions - runbooktest",
    "version": 1,
    "compliantAppListType": "none",
    "emailInDomainSuffixes": [],
    "passwordBlockSimple": true,
    "passwordExpirationDays": null,
    "passwordMinimumCharacterSetCount": 1,
    "passwordMinimumLength": 7,
    "passwordMinutesOfInactivityBeforeLock": 15,
    "passwordMinutesOfInactivityBeforeScreenTimeout": 10,
    "passwordPreviousPasswordBlockCount": null,
    "passwordRequiredType": "alphanumeric",
    "passwordRequired": true,
    "compliantAppsList": []
}
'@

#Invoking rest method
try {
    Write-Verbose "Creating macOS config policy"
    $MacOSConfigPolicy = Invoke-RestMethod -Method Post -UseBasicParsing -Uri $GraphURIforCreateConfigPolicy -Body $JSONformacOS -Headers $headerParams
}

catch {
    Write-Verbose "Failed to create config policy for macOS"
    Write-Output $Error[0]
    throw "Failed to create policy for macOS"
}

#Defining URI variable
Write-Verbose "Defining URI variable for macOS"
$GraphURIforCreateConfigPolicyAssignmentmacOS = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$($MacOSConfigPolicy.id)/assignments"

#Invoking rest method
try {
    Write-Verbose "Creating macOS config policy"
    $MacOSConfigPolicy = Invoke-RestMethod -Method Post -UseBasicParsing -Uri $GraphURIforCreateConfigPolicyAssignmentmacOS -Body $JSONforConfigAssignment -Headers $headerParams
}

catch {
    Write-Verbose "Failed to create config policy assignment"
    Write-Output $Error[0]
    throw "Failed to create policy assignment"
}

Write-Output "MacOS config policy created and assigned"
#endregion
}

if (!($SkipiOSConfig)) {
#region iOS

#Composing JSON object for iOS config policy
Write-Verbose "Composing JSON object for iOS"
$JSONforiOS = @'
{
    "@odata.type": "#microsoft.graph.iosGeneralDeviceConfiguration",
    "description": null,
    "displayName": "iOS - Device Restrictions - runbooktest",
    "passcodeBlockFingerprintUnlock": true,
    "passcodeBlockSimple": true,
    "passcodeMinimumLength": 4,
    "passcodeMinutesOfInactivityBeforeLock": 15,
    "passcodeMinutesOfInactivityBeforeScreenTimeout": 15,
    "passcodeRequiredType": "numeric",
    "passcodeRequired": true
}
'@

#Invoking rest method for config policy creation
try {
    Write-Verbose "Creating iOS config policy"
    $iOSConfigPolicy = Invoke-RestMethod -Method Post -UseBasicParsing -Uri $GraphURIforCreateConfigPolicy -Body $JSONforiOS -Headers $headerParams
}

catch {
    Write-Verbose "Failed to create config policy for iOS"
    Write-Output $Error[0]
    throw "Failed to create policy for iOS"
}

#Defining URI variable
Write-Verbose "Defining URI variable for macOS"
$GraphURIforCreateConfigPolicyAssignmentiOS = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$($iOSConfigPolicy.id)/assignments"

#Invoking rest method
try {
    Write-Verbose "Creating iOS config policy"
    $iOSConfigPolicy = Invoke-RestMethod -Method Post -UseBasicParsing -Uri $GraphURIforCreateConfigPolicyAssignmentiOS -Body $JSONforConfigAssignment -Headers $headerParams
}

catch {
    Write-Verbose "Failed to create config policy assignment"
    Write-Output $Error[0]
    throw "Failed to create policy assignment"
}

Write-Output "iOS config policy created and assigned"
#endregion
}

if (!($SkipAndroidConfig)) {
#region Android

#Composing JSON object for Android config policy
Write-Verbose "Composing JSON object for Android"
$JSONforAndroid = @'
{
    "@odata.type": "#microsoft.graph.androidGeneralDeviceConfiguration",
    "description": null,
    "displayName": "Android - Device Restrictions - runbooktest",
    "storageRequireDeviceEncryption": true,
    "passwordMinimumLength": 4,
    "passwordMinutesOfInactivityBeforeScreenTimeout": 15,
    "passwordRequiredType": "numericComplex",
    "requiredPasswordComplexity": "medium",
    "passwordRequired": true
}
'@

#Invoking rest method for config policy creation for Android
try {
    Write-Verbose "Creating Android config policy"
    $AndroidConfigPolicy = Invoke-RestMethod -Method Post -UseBasicParsing -Uri $GraphURIforCreateConfigPolicy -Body $JSONforAndroid -Headers $headerParams
}

catch {
    Write-Verbose "Failed to create config policy for Android"
    Write-Output $Error[0]
    throw "Failed to create policy for Android"
}

#Defining URI variable
Write-Verbose "Defining URI variable for Android"
$GraphURIforCreateConfigPolicyAssignmentAndroid = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$($AndroidConfigPolicy.id)/assignments"

#Invoking rest method for Android config policy assignment
try {
    Write-Verbose "Creating Android config policy"
    $AndroidConfigPolicyAssignment = Invoke-RestMethod -Method Post -UseBasicParsing -Uri $GraphURIforCreateConfigPolicyAssignmentAndroid -Body $JSONforConfigAssignment -Headers $headerParams
}

catch {
    Write-Verbose "Failed to create config policy assignment for Android"
    Write-Output $Error[0]
    throw "Failed to create policy assignment for Android"
}

Write-Output "Android config policy created and assigned"
#endregion
}

if (!($SkipAndroidEnterpriseConfig)) {
#region Android Enterprise

#Composing JSON object for Android Enterprise config policy
Write-Verbose "Composing JSON object for Android Enterprise"
$JSONforAndroidEnt = @'
{
    "@odata.type": "#microsoft.graph.androidWorkProfileGeneralDeviceConfiguration",
    "id": "997bf777-5e93-444e-a559-5606d663d7e8",
    "description": null,
    "displayName": "Android Enterprise - Device Restrictions (Work Profile) - runbooktest",
    "passwordMinimumLength": 4,
    "passwordMinutesOfInactivityBeforeScreenTimeout": 15,
    "passwordRequiredType": "numericComplex",
    "workProfileDataSharingType": "deviceDefault",
    "workProfileDefaultAppPermissionPolicy": "deviceDefault",
    "workProfileBlockCrossProfileCopyPaste": true,
    "workProfilePasswordMinimumLength": 4,
    "workProfilePasswordMinutesOfInactivityBeforeScreenTimeout": 15,
    "workProfilePasswordRequiredType": "numericComplex",
    "workProfileRequirePassword": true,
    "securityRequireVerifyApps": true
}
'@

#Invoking rest method for config policy creation for Android Enterprise
try {
    Write-Verbose "Creating Android Enterprise config policy"
    $AndroidEntConfigPolicy = Invoke-RestMethod -Method Post -UseBasicParsing -Uri $GraphURIforCreateConfigPolicy -Body $JSONforAndroidEnt -Headers $headerParams
}

catch {
    Write-Verbose "Failed to create config policy for Android Enterprise"
    Write-Output $Error[0]
    throw "Failed to create policy for Android Enterprise"
}

#Defining URI variable
Write-Verbose "Defining URI variable for Android Enterprise"
$GraphURIforCreateConfigPolicyAssignmentAndroidEnt = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$($AndroidEntConfigPolicy.id)/assignments"

#Invoking rest method for Android Enterprise config policy assignment
try {
    Write-Verbose "Creating Android Enterprise config policy"
    $AndroidEntConfigPolicyAssignment = Invoke-RestMethod -Method Post -UseBasicParsing -Uri $GraphURIforCreateConfigPolicyAssignmentAndroidEnt -Body $JSONforConfigAssignment -Headers $headerParams
}

catch {
    Write-Verbose "Failed to create config policy assignment for Android Enterprise"
    Write-Output $Error[0]
    throw "Failed to create policy assignment for Android Enterprise"
}

Write-Output "Android Enterprise config policy created and assigned"
#endregion
}

if (!($SkipWin10Config)) {
#region Win10

#Composing JSON object for Win10 config policy
Write-Verbose "Composing JSON object for Win10"
$JSONforWin10 = @'
{
    "@odata.type": "#microsoft.graph.windows10GeneralConfiguration",
    "description": null,
    "displayName": "Win10 - Device Restrictions - runbooktest",
    "authenticationAllowSecondaryDevice": true,
    "passwordBlockSimple": true,
    "passwordMinimumLength": 7,
    "passwordMinutesOfInactivityBeforeScreenTimeout": 15,
    "passwordMinimumCharacterSetCount": 3,
    "passwordRequired": true,
    "passwordRequireWhenResumeFromIdleState": true,
    "passwordRequiredType": "alphanumeric"
}
'@

#Invoking rest method for config policy creation for Win10
try {
    Write-Verbose "Creating Win10 config policy"
    $Win10ConfigPolicy = Invoke-RestMethod -Method Post -UseBasicParsing -Uri $GraphURIforCreateConfigPolicy -Body $JSONforWin10 -Headers $headerParams
}

catch {
    Write-Verbose "Failed to create config policy for Win10"
    Write-Output $Error[0]
    throw "Failed to create policy for Win10"
}

#Defining URI variable
Write-Verbose "Defining URI variable for Win10"
$GraphURIforCreateConfigPolicyAssignmentWin10 = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$($Win10ConfigPolicy.id)/assignments"

#Invoking rest method for Win10 config policy assignment
try {
    Write-Verbose "Creating Win10 config policy"
    $Win10ConfigPolicyAssignment = Invoke-RestMethod -Method Post -UseBasicParsing -Uri $GraphURIforCreateConfigPolicyAssignmentWin10 -Body $JSONforConfigAssignment -Headers $headerParams
}

catch {
    Write-Verbose "Failed to create config policy assignment for Win10"
    Write-Output $Error[0]
    throw "Failed to create policy assignment for Win10"
}

Write-Output "Win10 config policy created and assigned"
#endregion
}

if (!($SkipMacOSEndpointConfig)) {
#region macOS - Endpoint

#Composing JSON object for macOS - Endpoint config policy
Write-Verbose "Composing JSON object for macOS - Endpoint"
$JSONforMacOSEndpoint = @'
{
    "@odata.type": "#microsoft.graph.macOSEndpointProtectionConfiguration",
    "description": null,
    "displayName": "macOS - Endpoint Protection - runbooktest",
    "fileVaultEnabled": true,
    "fileVaultSelectedRecoveryKeyTypes": "personalRecoveryKey",
    "fileVaultPersonalRecoveryKeyHelpMessage": "To retrieve a lost or recently rotated recovery key, sign in to the Intune Company Portal website from any device. In the portal, go to Devices and select the device that has FileVault enabled, and then select Get recovery key. ",
    "fileVaultAllowDeferralUntilSignOut": true
}
'@

#Invoking rest method for config policy creation for macOS - Endpoint
try {
    Write-Verbose "Creating macOS - Endpoint config policy"
    $MacOSEndpointConfigPolicy = Invoke-RestMethod -Method Post -UseBasicParsing -Uri $GraphURIforCreateConfigPolicy -Body $JSONforMacOSEndpoint -Headers $headerParams
}

catch {
    Write-Verbose "Failed to create config policy for macOS - Endpoint"
    Write-Output $Error[0]
    throw "Failed to create policy for macOS - Endpoint"
}

#Defining URI variable
Write-Verbose "Defining URI variable for macOS - Endpoint"
$GraphURIforCreateConfigPolicyAssignmentMacOSEndpoint = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$($MacOSEndpointConfigPolicy.id)/assignments"

#Invoking rest method for macOS - Endpoint config policy assignment
try {
    Write-Verbose "Creating macOS - Endpoint config policy"
    $MacOSEndpointConfigPolicyAssignment = Invoke-RestMethod -Method Post -UseBasicParsing -Uri $GraphURIforCreateConfigPolicyAssignmentMacOSEndpoint -Body $JSONforConfigAssignment -Headers $headerParams
}

catch {
    Write-Verbose "Failed to create config policy assignment for macOS - Endpoint"
    Write-Output $Error[0]
    throw "Failed to create policy assignment for macOS - Endpoint"
}

Write-Output "macOS - Endpoint config policy created and assigned"
#endregion
}

if (!($SkipWin10EndpointConfig)) {
#region Win10 - Endpoint

#Composing JSON object for Win10 - Endpoint config policy
Write-Verbose "Composing JSON object for Win10 - Endpoint"
$JSONforWin10Endpoint = @'
{
    "@odata.type": "#microsoft.graph.windows10EndpointProtectionConfiguration",
    "id": "ea5b8264-fb09-4f68-9b64-e9f651fb80b8",
    "description": null,
    "displayName": "Win10 - Endpoint Protection - runbooktest",
    "bitLockerEnableStorageCardEncryptionOnMobile": true,
    "bitLockerEncryptDevice": true,
    "bitLockerSystemDrivePolicy": {
        "startupAuthenticationRequired": true,
        "startupAuthenticationBlockWithoutTpmChip": false,
        "startupAuthenticationTpmUsage": "allowed",
        "startupAuthenticationTpmPinUsage": "allowed",
        "startupAuthenticationTpmKeyUsage": "allowed",
        "startupAuthenticationTpmPinAndKeyUsage": "allowed",
        "recoveryOptions": {
            "recoveryPasswordUsage": "allowed",
            "recoveryKeyUsage": "allowed",
            "enableRecoveryInformationSaveToStore": true,
            "recoveryInformationToStore": "passwordAndKey",
            "enableBitLockerAfterRecoveryInformationToStore": false
        }
    }
}
'@

#Invoking rest method for config policy creation for Win10 - Endpoint
try {
    Write-Verbose "Creating Win10 - Endpoint config policy"
    $Win10EndpointConfigPolicy = Invoke-RestMethod -Method Post -UseBasicParsing -Uri $GraphURIforCreateConfigPolicy -Body $JSONforWin10Endpoint -Headers $headerParams
}

catch {
    Write-Verbose "Failed to create config policy for Win10 - Endpoint"
    Write-Output $Error[0]
    throw "Failed to create policy for Win10 - Endpoint"
}

#Defining URI variable
Write-Verbose "Defining URI variable for Win10 - Endpoint"
$GraphURIforCreateConfigPolicyAssignmentWin10Endpoint = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$($Win10EndpointConfigPolicy.id)/assignments"

#Invoking rest method for Win10 - Endpoint config policy assignment
try {
    Write-Verbose "Creating Win10 - Endpoint config policy"
    $Win10EndpointConfigPolicyAssignment = Invoke-RestMethod -Method Post -UseBasicParsing -Uri $GraphURIforCreateConfigPolicyAssignmentWin10Endpoint -Body $JSONforConfigAssignment -Headers $headerParams
}

catch {
    Write-Verbose "Failed to create config policy assignment for Win10 - Endpoint"
    Write-Output $Error[0]
    throw "Failed to create policy assignment for Win10 - Endpoint"
}

Write-Output "Win10 - Endpoint config policy created and assigned"
#endregion
}
