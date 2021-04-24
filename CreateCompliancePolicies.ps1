Param (  
    [Parameter(Mandatory = $True)][string]$Tenantname,
    [Parameter(Mandatory = $True)][string]$ApplicationID,
    [Parameter(Mandatory = $True)][string]$ApplicationSecret
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


#########################################################################################
#
#       Part 2 - Creating and assigning compliance policies
#
#########################################################################################

#region Adding notification template and message

#Defining URI variable for notification template creation
Write-Verbose "Defining URI variable for notification template creation"
$GraphURIforNotificationTemplate = "https://graph.microsoft.com/beta/deviceManagement/notificationMessageTemplates/"

#Composing JSON object for notification template assignment
Write-Verbose "Composing JSON object for notification template assignment"
$JSONforNotificationTemplate = @'
{
    "@odata.type": "#microsoft.graph.notificationMessageTemplate",    
    "displayName": "Default notification",
    "brandingOptions": "includeCompanyLogo,includeCompanyName,includeContactInformation,includeCompanyPortalLink"
}
'@

#Invoking rest method for notification template creation
try {
    Write-Verbose "Creating notification template"
    $NotificationTemplate = Invoke-RestMethod -Method Post -UseBasicParsing -Uri $GraphURIforNotificationTemplate -Body $JSONforNotificationTemplate -Headers $headerParams
}

catch {
    Write-Verbose "Failed to create notification template"
    Write-Output $Error[0]
    throw "Failed to create notification template"
}

#Defining URI variable for notification template message creation
Write-Verbose "Defining URI variable for notification template message creation"
$GraphURIforNotificationTemplateMessage = "https://graph.microsoft.com/beta/deviceManagement/notificationMessageTemplates/$($NotificationTemplate.id)/localizedNotificationMessages"

#Composing JSON object for notification template message assignment
Write-Verbose "Composing JSON object for notification template message assignment"
$JSONforNotificationTemplateMessage = @'
{
    "locale": "en-us",
    "subject": "Your device is not compliant",
    "messageTemplate": "Hi\n\nOne of your devices is now not compliant and may experience issues with connecting to company data.\n\nCheck the Company Portal app to see which device is not compliant anymore",
    "isDefault": true
}
'@

#Invoking rest method for notification template message creation
try {
    Write-Verbose "Creating notification template message"
    $NotificationTemplateMessage = Invoke-RestMethod -Method Post -UseBasicParsing -Uri $GraphURIforNotificationTemplateMessage -Body $JSONforNotificationTemplateMessage -Headers $headerParams
}

catch {
    Write-Verbose "Failed to create notification template message"
    Write-Output $Error[0]
    throw "Failed to create notification template message"
}


#endregion