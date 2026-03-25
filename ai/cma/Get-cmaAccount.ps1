<#
.SYNOPSIS
Get the list of system ids for a customer account

.DESCRIPTION
Automated system compile the unique ids used to identify each customer in each of the third party systems.
The "Account" record keeps each of these ids for a customer.

.PARAMETER Code
Customer Account Code

#>

Function Get-cmaAccount {
    param (
        [Parameter(Mandatory=$false)] [String] $Code
    )

    $url =  "/api/cma/account?code=$Code"

    $response = Invoke-cmaRequest1 -Method Get -Uri $url 

    return $response
}