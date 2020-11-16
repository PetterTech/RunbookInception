Param  
(  
    [Parameter (Mandatory = $false)]  
    [object] $WebhookData  
)  
 
Write-Verbose "Runbook started"
#Setting variables
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

Write-Verbose "Starting part 2"

#Getting runas connection
try {
    Write-Verbose "Getting runas connection"
    $ServicePrincipalConnection = Get-AutomationConnection -Name 'AzureRunAsConnection'
}

catch {
    Write-Verbose "Failed to get runas connection"
    Write-Output $Error[0]
    throw "Failed to get runas connection"
}

#Connecting to Azure
try {
    Write-Verbose "Connecting to Azure"
    Connect-AzAccount `
    -ServicePrincipal `
    -Tenant $ServicePrincipalConnection.TenantId `
    -ApplicationId $ServicePrincipalConnection.ApplicationId `
    -CertificateThumbprint $ServicePrincipalConnection.CertificateThumbprint | Out-Null
}

catch {
    Write-Verbose "Failed to connect"
    Write-Output $Error[0]
    throw "Failed to connecy"
}

#Composing parameter object
Write-Verbose "Composing CreateGroups parameters"
$CreateGroupsBody = @{
    "Tenantname" = $WebhookInput.Tenantname;
    "ApplicationID" = $WebhookInput.ApplicationID;
    "ApplicationSecret" = $WebhookInput.ApplicationSecret
}

#Starting runbook
try {
    Write-Verbose "Starting runbook to create groups"
    $CreateGroupsJob = Start-AzAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name CreateGroups -Parameters $CreateGroupsBody
    Write-Verbose "Runbook started"
}

catch {
    Write-Verbose "Failed to start runbook"
    Write-Output $Error[0]
    throw "Failed to start runbook"
}

#Getting job id
Write-Verbose "Getting Job ID for CreateGrops job"
$CreateGroupsJobId = $CreateGroupsJob.JobId.guid
Write-Verbose "Job Id for group creation is $($CreateGroupsJobId)"

#Waiting for runbook to complete successfully
Write-Verbose "Checking status of CreateGroups job"
while ((Get-AzAutomationJob -id $CreateGroupsJobId -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName).status -eq "New") {
    Write-Verbose "Status is New, sleeping"
    Start-Sleep -Seconds 10
    }

while ((Get-AzAutomationJob -id $CreateGroupsJobId -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName).status -eq "Running") {
    Write-Verbose "Status is Running, sleeping some more"
    Start-Sleep -Seconds 10
}

if ((Get-AzAutomationJob -id $CreateGroupsJobId -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName).status -eq "Failed") {
    Write-Verbose "Status of CreateGroups job is failed"
    Write-Output "Status of CreateGroups job is failed"
    throw "Status of CreateGroups job is failed"
}

elseif ((Get-AzAutomationJob -id $CreateGroupsJobId -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName).status -eq "Suspended") {
    Write-Verbose "Status of CreateGroups job is Suspended"
    Write-Output "Status of CreateGroups job is Suspended"
    throw "Status of CreateGroups job is Suspended"
}

elseif ((Get-AzAutomationJob -id $CreateGroupsJobId -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName).status -eq "Stopped") {
    Write-Verbose "Status of CreateGroups job is Stopped"
    Write-Output "Status of CreateGroups job is Stopped"
    throw "Status of CreateGroups job is Stopped"    
}

Write-Verbose "Groups created"
#endregion