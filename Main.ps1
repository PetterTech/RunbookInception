Param  
(  
    [Parameter (Mandatory = $false)]  
    [object] $WebhookData  
)  
 
Write-Verbose "Runbook started"
#Setting variables
$CreateGroupsWebhook = "https://84e8cab9-64dd-4663-92e9-987b0c6bf09a.webhook.we.azure-automation.net/webhooks?token=6ByaA0NfsnVSBhSbS0cfjELPhk%2bxpDfswC4UMIaj3q8%3d"

#region Part 1

#########################################################################################
#
#       Part 1 - Getting data
#
#########################################################################################

#Checking if runbook was started from webhook  
Write-Verbose "Checking if webhookdata is present"
if ($WebhookData) {
    try {
        Write-Verbose "Grabbing webhookdata"
        # Collect properties of WebhookData  
        $WebhookInput = (ConvertFrom-Json -InputObject $WebHookData.RequestBody)
        Write-Verbose "Got webhookdata"        
    }

    catch {
        Write-Verbose "Failed to grab WebhookInput"
        throw "Failed to grab WebhookInput"
    }

}

else {  
    Write-Verbose "Webhookdata is NOT present"
    Write-Error -Message 'Runbook was not started from Webhook' -ErrorAction stop  
} #End if webhookdata

Write-Verbose "Done with part 1"
#endregion

#region Part 2
#########################################################################################
#
#       Part 2 - Running runbooks
#
#########################################################################################

#Running CreateGroups runbook
Write-Verbose "Starting part 2"

Write-Verbose "Composing CreateGroups body"
$CreateGroupsBody = @{
    "Tenantname" = $WebhookInput.Tenantname;
    "ApplicationID" = $WebhookInput.ApplicationID;
    "ApplicationSecret" = $WebhookInput.ApplicationSecret
}

try {
    Write-Verbose "Invoking webrequest to create groups"
    Start-AzAutomationRunbook –AutomationAccountName 'automation' –Name 'CreateGroups' -ResourceGroupName 'rgr-automation' –Parameters $CreateGroupsBody –Wait
    #$CreateGroupsJob = Invoke-WebRequest -Uri $CreateGroupsWebhook -Body (ConvertTo-Json $CreateGroupsBody) -UseBasicParsing
    Write-Verbose "Webrequest invoked"
}

catch {
    Write-Verbose "Failed to invoke webrequest"
    Write-Output $Error[0]
    throw "Failed to invoke webrequest"
}

Write-Verbose "Groups created"


#endregion