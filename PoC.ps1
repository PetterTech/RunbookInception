Param  
(  
    [Parameter (Mandatory = $false)]  
    [object] $WebhookData  
)  
 
Write-Verbose "Runbook started"

# If runbook was called from Webhook, WebhookData will not be null.  
Write-Verbose "Checking if webhookdata is present"
if ($WebhookData) {  
    Write-Verbose "Grabbing webhookdata"
    # Collect properties of WebhookData  
    $WebhookName = $WebHookData.WebhookName  
    $WebhookHeaders = $WebHookData.RequestHeader  
    $WebhookBody = $WebHookData.RequestBody  
    $Input = (ConvertFrom-Json -InputObject $WebhookBody)  
    Write-Verbose "Got webhookdata"
}  

else {  
    Write-Verbose "Webhookdata is NOT present"
    Write-Error -Message 'Runbook was not started from Webhook' -ErrorAction stop  
} 

#Connecting to tenant
Write-Verbose "Connecting to target tenant"
try {
    Connect-AzureAD -TenantId $input.TenantID -ApplicationId $input.ApplicationID -CertificateThumbprint $input.Thumbprint | Out-Null
    Write-Verbose "Connected to tenant"
}

catch {
    Write-Verbose "Something went wrong"
    Write-Output $error[0]
    throw "I have failed you"
}

#Creating test user
<#
try {
    Write-Verbose "Creating user"
    $PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
    $PasswordProfile.Password = "ThisIsNotMyPassw0rd"
    $user = New-AzureADUser -DisplayName "Jallamann Pedersen" -PasswordProfile $PasswordProfile -UserPrincipalName "jall@M365x015506.onmicrosoft.com" -AccountEnabled $true -MailNickName "Jall" 
    Write-Verbose "User created"
}

catch {
    Write-Verbose "Something went wrong"
    Write-Output $error[0]
    throw "I have failed you"
}
#>

#Creating group
try {
    Write-Verbose "Creating group"
    $Group = New-AzureADGroup -DisplayName "My new group"
    Write-Verbose "Group created"
}

catch {
    Write-Verbose "Something went wrong"
    Write-Output $error[0]
    throw "I have failed you"
}

#Add user to group
try {
    Write-Verbose "Adding user with objectID $($user.objectID) to the group with objectid $($group.objectID)"
    Add-AzureADGroupMember -ObjectId $group.objectID -RefObjectId $user.objectID
    Write-Verbose "Added member"
}

catch {
    Write-Verbose "Something went wrong"
    Write-Output $error[0]
    throw "I have failed you"
}