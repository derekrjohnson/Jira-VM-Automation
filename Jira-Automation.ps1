# Set Jira url and credentials to interact with the api
$jiraURL = "https://<company>.atlassian.net
$username = <USERNAME>
$apiToken = Ninja-Property-Get "jiraapitoken"

# Convert the username + API token into a Base64 encoded hash for basic authentication
$pair = "$($username):$($apiToken)"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)
$headers = @{ Authorization = "Basic $base64" } 

# Set issue id and custom field ids
$projectKey = "VM"
$cybersecurity_risk_id = "customfield_10152"
$financial_risk_id = "customfield_10153"
$compliance_risk_id = "customfield_10157"
$reputation_risk_id = "customfield_10158"
$vendor_risk_field_id = "customfield_10163"
$last_vendor_review_id = "customfield_10156"
$annual_cost_id = "customfield_10155"
$subtask_duedate_id = "customfield_10167"

# This function calculates the risk score based on the custom fields using the logic outlined in the VM Risk Scoring document
function DetermineRisk($issue) {
    $cybersecurity_risk_value = [int]$issue.fields.$cybersecurity_risk_id.value
    $financial_risk_value = [int]$issue.fields.$financial_risk_id.value
    $compliance_risk_value = [int]$issue.fields.$compliance_risk_id.value
    $reputation_risk_value = [int]$issue.fields.$reputation_risk_id.value

    # Find the largest value out of the custom fields
    $largest_value = $cybersecurity_risk_value
    if ($financial_risk_value -gt $largest_value) {
        $largest_value = $financial_risk_value
    }
    if ($compliance_risk_value -gt $largest_value) {
        $largest_value = $compliance_risk_value
    }
    if ($reputation_risk_value -gt $largest_value) {
        $largest_value = $reputation_risk_value
    }

    # Determine the risk category based on the largest value
    if ($largest_value -le 2) {
        Write-Host "Risk Category: Trivial"
        return "Trivial"
    } elseif ($largest_value -ge 9) {
        Write-Host "Risk Category: Critical"
        return "Critical"
    } else {
        Write-Host "Risk Category: Moderate"
        return "Moderate"
    }
}

# This function takes the output of the DetermineRisk function and updates the vendor risk field
function Update-VendorRiskField($issue, $risk_category) {
    $vendor_risk_url = "$jiraURL/rest/api/2/issue/$($issue.key)"
    $vendor_risk_payload = @{
        fields = @{
            $vendor_risk_field_id = @{
                value = $risk_category
            }
        }
    } | ConvertTo-Json

    Invoke-RestMethod -Method Put -Uri $vendor_risk_url -Headers $headers -Body $vendor_risk_payload -ContentType "application/json" -Verbose
}

# This function uses the output of the DetermineRisk function to update the priority field
function Update-Priority($issue, $risk_category) {
    $priority_field_id = "priority" # Replace with the ID of the priority field

    $priority_value = switch ($risk_category) {
        "Trivial" { @{ id = "5" } }     # ID for "Lowest" priority
        "Moderate" { @{ id = "3" } }    # ID for "Medium" priority
        "Critical" { @{ id = "1" } }    # ID for "Highest" priority
        default { throw "Invalid risk category: $risk_category" }
    }

    $priority_url = "$jiraURL/rest/api/2/issue/$($issue.key)"
    $priority_body = @{
        fields = @{
            $priority_field_id = $priority_value
        }
    } | ConvertTo-Json

    Invoke-RestMethod -Method Put -Uri $priority_url -Headers $headers -Body $priority_body -ContentType "application/json" -Verbose
}

# This function calculates the vendor review duration based on the risk category and annual cost value
function VendorReview($risk_category, $annual_cost_value) {
    $annual_cost_value = [int]$issue.fields.$annual_cost_id.value

    if ($VendorRisk -eq "Critical") {
        Write-Host "Vendor Review Duration: 365 days"
        return 365
    }
    elseif ($VendorRisk -eq "Moderate" -and $annual_cost_value -gt 30000) {
        Write-Host "Vendor Review Duration: 730 days"
        return 730
    }
    else {
        Write-Host "Vendor Review Duration: 1095 days"
        return 1095
    }
}

# This function calculates the next review date based on the vendor review duration and last vendor review date
function NextReviewDate ($vendor_review_duration, $last_vendor_review_date) {
    # This code pulls the last vendor review date from the issue
    $last_vendor_review_date_url = "$jiraURL/rest/api/2/issue/$($issue.key)?fields=$last_vendor_review_id"
    $response = Invoke-RestMethod -Uri $last_vendor_review_date_url -Headers $headers -Method Get

    # If the last vendor review date field is populated, it uses it and the review duration to calculate the next vendor review date
    if ($response.fields.$last_vendor_review_id) {
        $last_vendor_review_date = [DateTime]$response.fields.$last_vendor_review_id
        $next_review_date = $last_vendor_review_date.AddDays($vendor_review_duration)
        Write-Host "Next Review Date for $($issue.key): $next_review_date"
        return $next_review_date
    }
    # If no vendor review date is found, it returns a message
    else {
        Write-Host "No Last Vendor Review Date found for $($issue.key)."
    }
}

# This function creates a subtask for the issue
function JiraSubtask ($issue, $next_review_date) {
    $subtask_url = "$jiraURL/rest/api/2/issue/"
    $subtask_body = @{
        fields = @{
            duedate = $duedate
            priority = "Highest"
            project = @{
                key = $projectKey
            } 
            parent = @{
                key = $issue.key
            }
            summary = "This vendor is 21 days from their next review date $duedate"
            description = "Please review this vendor's risk score and update the appropriate custom fields before $duedate"
            issuetype = @{
                name = "Sub-task"
            }
            $subtask_duedate_id = $duedate
        }
    } | ConvertTo-Json

    Invoke-RestMethod -Method Post -Uri $subtask_url -Headers $headers -Body $subtask_body -ContentType "application/json" -Verbose
}

# This function updates due date for each issue
function UpdateDueDate ($issue, $duedate) {
    $duedate_url = "$jiraURL/rest/api/2/issue/$($issue.key)"
    $duedate_body = @{
        fields = @{
            duedate = $duedate
        }
    } | ConvertTo-Json

    Invoke-RestMethod -Method Put -Uri $duedate_url -Headers $headers -Body $duedate_body -ContentType "application/json" -Verbose
}

# This function Edit-JiraIssueTransition 
function Edit-JiraIssueTransition ($issue) {
    $transition_url = "$jiraURL/rest/api/2/issue/$($issue.key)/transitions"
    $transition_body = @{
        transition = @{
            id = "71"
        }
    } | ConvertTo-Json

    Invoke-RestMethod -Method Post -Uri $transition_url -Headers $headers -Body $transition_body -ContentType "application/json" -Verbose
}

# Function that checks if issue is a subtask
function CheckifSubtask ($issue) {
    $issue_url = "$jiraURL/rest/api/2/issue/$($issue.key)"
    $response = Invoke-RestMethod -Uri $issue_url -Headers $headers -Method Get
    if ($response.fields.issuetype.subtask -eq $true) {
        Write-Host "Issue $($issue.key) is a subtask"
        return $true
    }
    else {
        Write-Host "Issue $($issue.key) is not a subtask"
        return $false
    }
}

# This function updates the subtask
function UpdateSubtask ($issue) {
    $issue_url = "$jiraURL/rest/api/2/issue/$($issue.key)"
    $issue_response = Invoke-RestMethod -Uri $issue_url -Headers $headers -Method Get
    $parent_key = $issue_response.fields.parent.key
    $parentissue_url = "$jiraURL/rest/api/2/issue/$($parent_key)"
    $parent_response = Invoke-RestMethod -Uri $parentissue_url -Headers $headers -Method Get
    $parent_due_date = $parent_response.fields.duedate
    $parent_priority = $parent_response.fields.priority.name
    $parent_assignee = $parent_response.fields.assignee
    $subtask_body = @{
        fields = @{
            duedate = $parent_due_date
            priority = @{
                name = $parent_priority
            }
            assignee = $parent_assignee
        }
    } | ConvertTo-Json

    Invoke-RestMethod -Method Put -Uri $issue_url -Headers $headers -Body $subtask_body -ContentType "application/json" -Verbose

}

# Make the REST API call to search for issues within the project
$jqlQuery = "project=$projectKey"
$fields = "$cybersecurity_risk_id,$financial_risk_id,$compliance_risk_id,$reputation_risk_id"
$restAPIuri = "$jiraURL/rest/api/2/search?jql=$jqlQuery&fields=$fields"
$response = Invoke-RestMethod -Uri $restAPIuri -Headers $headers -Method Get

# Loop through the issues and calculate the risk score, update the vendor risk field, and update the priority
foreach ($issue in $response.issues) {
    Write-Host "Processing Issue: $($issue.key)"

    $risk_category = DetermineRisk $issue
    Update-VendorRiskField $issue $risk_category
    Update-Priority $issue $risk_category

    # Sets the vendor review duration using the output of the VendorReview function
    $vendor_review_duration = VendorReview $risk_category $annual_cost_value

    # Sets the next review date using the output of the NextReviewDate function
    $next_review_date = NextReviewDate $vendor_review_duration $last_vendor_review_date

    # If the $next_review_date variable is not null, calculate the number of days until the next review date
    if ($null -ne $next_review_date) {
        $duedate = $next_review_date.ToString("yyyy-MM-dd")
        $today = Get-Date
        $daysUntilDue = ($next_review_date - $today).Days + 1
        Write-Host "Days Until Due: $daysUntilDue"
        Write-Host "duedate: $duedate"
        # Call the function to update the due date
        UpdateDueDate $issue $duedate
    }

    # If the $daysUntilDue variable is equal to 21 and $next_review_date is not null create a subtask using the JiraSubtask function
    if (($daysUntilDue -eq 21) -and ($null -ne $next_review_date)) {
        Write-Host "Creating Jira Subtask for Issue: $($issue.key)"
        # Call the function to create the sub task
        JiraSubtask $issue $next_review_date $issue.key
        # Call the function to transition the issue to the "In Review" status
        Edit-JiraIssueTransition $issue 
    }
    CheckifSubtask $issue
    if (CheckifSubtask $issue -eq $true) {
        UpdateSubtask $issue
    }
}
