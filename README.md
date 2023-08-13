# Jira VM Automation #

Automate risk assessment, priority updates, and subtask generation for VM Jira board.

## 📚 Description

This script works by authenticating with the Jira api to utilize multiple different endpoints. The script's main function is to calculate and set vendor risk and priority fields, calculate the next vendor review date and populate a custom field, create a subtask automatically when it is 21 days from a vendors next review date, and moves the task to the under review column on the project board when that subtask is created, all based on definitions outlined in the policy.

### 📄 DetermineRisk($issue) ###

 - Assess cybersecurity, financial, compliance, and reputation risks.
 - Categorizes vendors as trivial, critical, or moderate.

### 🔄 Update-VendorRiskField($issue, $risk_category) ###

 - Updates vendor risk custom field with calculated risk category.

### 🔄 Update-Priority($issue, $risk_category) ###

 - Updates issue priority based on risk category.

### 📆 VendorReview($risk_category, $annual_cost_value) ###

 - Determines duration between vendor reviews based on risk and cost.

### 📅 NextReviewDate($vendor_review_duration, $last_vendor_review_date) ###

 - Calculates the next vendor review date.

### 📋 JiraSubtask($issue, $next_review_date) ###

 - Creates Jira subtask with due date, summary, and description.

### 📆 UpdateDueDate($issue, $duedate) ###

 - Updates due date for each issue.

### 🔄 Edit-JiraIssueTransition($issue) ###

 - Sets transition id to 71 when subtask is created 21 days from review.

### ✅ CheckifSubtask($issue) ###

 - Checks if issue is a subtask.

### 🔄 UpdateSubtask($issue) ###

 - Updates subtask with parent information.

### 🔄 Main Loop ###

 - Executes each function for VM board issues.
 - Creates subtask if due in 21 days and $next_review_date isn't null.

## 📜 Version and Last Change ##
v1.1 - July 2023

## 🧙‍♂️ Origin Author ##
Derek (powershell wizard apprentice) Johnson

## 🙌 Contributors ##
