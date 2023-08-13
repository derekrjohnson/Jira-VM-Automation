# Jira VM Automation #

Automate risk assessment, priority updates, and subtask generation for VM Jira board.

## 📚 Description

This script works by authenticating with the Jira api to utilize multiple different endpoints. The script's main function is to calculate and set vendor risk and priority fields, calculate the next vendor review date and populate a custom field, create a subtask automatically when it is 21 days from a vendors next review date, and moves the task to the under review column on the project board when that subtask is created, all based on definitions outlined in the policy.

## 🚀 Getting Started

1. 📥 Clone this repository to your production environment.
2. 🛠 Modify the $jiraURL, $username, and $apiToken variables in the script. In my deployment I store the API token as a Ninja global custom field with permissions set to only allow scripts to read the field.(Note: the user set in the script needs to be an administrator on the project)

![image](https://github.com/derekrjohnson/Jira-VM-Automation/assets/142181223/8ce980cb-44e4-48d8-b8fa-3cc429cc5361)

4. 🧩 Configure an environment variable in your test environment to store the Teams webhook.
5. 🕰 Schedule a recurring task to run the script every minute, ensuring continuous monitoring.

⚠️ **Warning:** This repository is intended for production. Test implementations should be carried out in the designated test repository.

### 📄 DetermineRisk($issue) ###

This function assesses cybersecurity, financial, compliance, and reputation risks. It categorizes vendors as trivial, critical, or moderate.

### 🔄 Update-VendorRiskField($issue, $risk_category) ###

This function updates the vendor risk custom field with the calculated risk category.

### 🔄 Update-Priority($issue, $risk_category) ###

This function updates the issue priority based on the risk category.

### 📆 VendorReview($risk_category, $annual_cost_value) ###

This function determines the duration between vendor reviews based on the risk and cost.

### 📅 NextReviewDate($vendor_review_duration, $last_vendor_review_date) ###

This function calculates the next vendor review date.

### 📋 JiraSubtask($issue, $next_review_date) ###

This function creates a Jira subtask with a due date, summary, and description.

### 📆 UpdateDueDate($issue, $duedate) ###

This function updates the due date for each issue.

### 🔄 Edit-JiraIssueTransition($issue) ###

This function sets the transition id to 71 when a subtask is created 21 days from the review.

### ✅ CheckifSubtask($issue) ###

This function checks if an issue is a subtask.

### 🔄 UpdateSubtask($issue) ###

This function updates the subtask with parent information.

### 🔄 Main Loop ###

The main loop executes each function for VM board issues and creates a subtask if it's due in 21 days and $next_review_date isn't null.

## 📜 Version and Last Change ##
v1.1 - July 2023

## 🧙‍♂️ Origin Author ##
Derek Johnson

## 📚 References ##

* [JIRA Cloud REST API Reference](https://docs.atlassian.com/software/jira/docs/api/REST/1000.824.0/#:~:text=JIRA%20Cloud%20REST%20API%20Reference%201%20Getting%20started,methods%20...%208%20Experimental%20methods%20...%20More%20items)

