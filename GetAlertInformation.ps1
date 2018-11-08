$WarningPreference = 'SilentlyContinue'
Function Run {
    # list all subscriptions
    $subscriptions = Get-AzureRmSubscription | Where-Object State -eq "Enabled"
    $subscriptionIndex = 1
    # loop through them
    Foreach ($subscription in $subscriptions)
    {
        GetInformationFromSubscription $subscription $subscriptionIndex
        $subscriptionIndex++
    }
}
Function GetInformationFromSubscription ($subscription, $subscriptionIndex, $verbose) {
    # connect to the subscription
    $context = Set-AzureRmContext -SubscriptionId $subscription.SubscriptionId
    
    # get all resourcegroups
    $resourceGroups = Get-AzureRmResourceGroup
    # check each resourcegroup
    Foreach ($group in $resourceGroups){
        $values = GetAlertsInResourceGroup $group.ResourceGroupName $verbose
        $totalClassicRules += $values[0]
        $totalResources += $values[1]
        $totalMetricRules += $values[2]
        $totalScheduleQueryRules += $values[3]
    }
    # get all activitylog alerts for the entire subscription
    $totalActivityLogAlerts = Get-AzureRmActivityLogAlert
    If ($verbose) {
        Foreach ($rule in $totalActivityLogAlerts){
            Write-Host ("  ActivityLogAlerts: " + $rule.Name + " - " + $rule.Description)
        }
    }
    # write information
    Write-Host ("Subscription " + $subscriptionIndex + " has " + $resourceGroups.Count + " resource groups with " + $totalResources + " resources")
    Write-Host ("Classic alertrules:      " + $totalClassicRules)
    Write-Host ("ActivityLogAlert:        " + $totalActivityLogAlerts.Count)
    Write-Host ("MetricRules:             " + $totalMetricRules)
    Write-Host ("TotalScheduleQueryRules: " + $totalScheduleQueryRules)
    Write-Host "-----------------------------------------------------"
}
Function GetAlertsInResourceGroup ($resourceGroupName, $verbose){
    $resources = Get-AzureRmResource | Where-Object -Property ResourceGroupName -eq $resourceGroupName
    #$resources = Get-AzureRmResource -ResourceGroupName $resourceGroupName
    $classicRulesInGroup = Get-AzureRmAlertRule -ResourceGroup $resourceGroupName -DetailedOutput
    $metricAlerts = $resources | Where-Object ResourceType -eq "Microsoft.Insights/metricAlerts"
    #$alertRules = $resources | Where-Object ResourceType -eq "MICROSOFT.INSIGHTS/ALERTRULES" # 'Classic' alert rules
    #$activityLogAlerts = $resources | Where-Object ResourceType -eq "MICROSOFT.INSIGHTS/ACTIVITYLOGALERTS" # same as 'Get-AzureRmActivityLogAlert'
    $scheduleQueryRules = $resources | Where-Object ResourceType -eq "microsoft.insights/scheduledqueryrules"
    
    #Foreach ($resource in $resources){Write-Host ("    " + $resource.Name + " type: " + $resource.ResourceType)}
    If ($verbose) {
        Foreach ($rule in $metricAlerts){
            Write-Host ("  metricAlert: " + $rule.Name + " - " + $rule.Description)
        }
        Foreach ($rule in $classicRulesInGroup){
            Write-Host ("  classicRuleInGroup: " + $rule.Name + " - " + $rule.Description)
        }
     
        Foreach ($rule in $scheduleQueryRules){
            Write-Host ("  scheduleQueryRule: " + $rule.Name + " - " + $rule.Description)
        }
    }
    return $classicRulesInGroup.Count, $resources.Count, $metricAlerts.Count, $scheduleQueryRules.Count
}

# connect to your Azure account
Connect-AzureRmAccount

# run the script
Run