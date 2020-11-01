Param  
(  
    [Parameter (Mandatory = $false)]  
    [object] $WebhookData  
)  
 
Write-Verbose "Runbook started"
#Setting variables
$CreateGroupsWebhook = "https://84e8cab9-64dd-4663-92e9-987b0c6bf09a.webhook.we.azure-automation.net/webhooks?token=6ByaA0NfsnVSBhSbS0cfjELPhk%2bxpDfswC4UMIaj3q8%3d"
$ResourceGroupName = "rgr-automation"
$AutomationAccountName = "Automation"

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
Write-Output "Done with part 1"
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
    $CreateGroupsJob = Invoke-WebRequest -Uri $CreateGroupsWebhook -Method Post -Body (ConvertTo-Json $CreateGroupsBody) -UseBasicParsing
    Write-Verbose "Webrequest invoked"
}

catch {
    Write-Verbose "Failed to invoke webrequest"
    Write-Output $Error[0]
    throw "Failed to invoke webrequest"
}

Write-Output "Kicked off CreateGroups runbook"

Write-Verbose "Checking status of CreateGroups job"
while ((Get-AzAutomationJob -id ([guid]::new((($CreateGroupsJob.Content | ConvertFrom-Json).JobIds))) -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName).status -eq "New") {
    Write-Verbose "Status is New, sleeping"
    Start-Sleep -Seconds 10
    }

while ((Get-AzAutomationJob -id ([guid]::new((($CreateGroupsJob.Content | ConvertFrom-Json).JobIds))) -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName).status -eq "Running") {
    Write-Verbose "Status is Running, sleeping some more"
    Start-Sleep -Seconds 10
}

if ((Get-AzAutomationJob -id ([guid]::new((($CreateGroupsJob.Content | ConvertFrom-Json).JobIds))) -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName).status -eq "Failed") {
    Write-Verbose "Status of CreateGroups job is failed"
    Write-Output "Status of CreateGroups job is failed"
    throw "Status of CreateGroups job is failed"
}

elseif ((Get-AzAutomationJob -id ([guid]::new((($CreateGroupsJob.Content | ConvertFrom-Json).JobIds))) -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName).status -eq "Suspended") {
    Write-Verbose "Status of CreateGroups job is Suspended"
    Write-Output "Status of CreateGroups job is Suspended"
    throw "Status of CreateGroups job is Suspended"
}

elseif ((Get-AzAutomationJob -id ([guid]::new((($CreateGroupsJob.Content | ConvertFrom-Json).JobIds))) -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName).status -eq "Stopped") {
    Write-Verbose "Status of CreateGroups job is Stopped"
    Write-Output "Status of CreateGroups job is Stopped"
    throw "Status of CreateGroups job is Stopped"    
}

Write-Verbose "Groups created"
#endregion