function Invoke-CIPPStandardTeamsEnrollUser {
    <#
    .FUNCTIONALITY
        Internal
    .COMPONENT
        (APIName) TeamsEnrollUser
    .SYNOPSIS
        (Label) Default voice and face enrollment
    .DESCRIPTION
        (Helptext) Controls whether users with this policy can set the voice profile capture and enrollment through the Recognition tab in their Teams client settings.
        (DocsDescription) Controls whether users with this policy can set the voice profile capture and enrollment through the Recognition tab in their Teams client settings.
    .NOTES
        CAT
            Teams Standards
        TAG
        ADDEDCOMPONENT
            {"type":"autoComplete","required":true,"multiple":false,"creatable":false,"name":"standards.TeamsEnrollUser.EnrollUserOverride","label":"Voice and Face Enrollment","options":[{"label":"Disabled","value":"Disabled"},{"label":"Enabled","value":"Enabled"}]}
        IMPACT
            Low Impact
        ADDEDDATE
            2024-11-12
        POWERSHELLEQUIVALENT
            Set-CsTeamsMeetingPolicy -Identity Global -EnrollUserOverride \$false
        RECOMMENDEDBY
        UPDATECOMMENTBLOCK
            Run the Tools\Update-StandardsComments.ps1 script to update this comment block
    .LINK
        https://docs.cipp.app/user-documentation/tenant/standards/list-standards
    #>

    param($Tenant, $Settings)
    $TestResult = Test-CIPPStandardLicense -StandardName 'TeamsEnrollUser' -TenantFilter $Tenant -RequiredCapabilities @('MCOSTANDARD', 'MCOEV', 'MCOIMP', 'TEAMS1','Teams_Room_Standard')

    # Get EnrollUserOverride value using null-coalescing operator

    if ($TestResult -eq $false) {
        Write-Host "We're exiting as the correct license is not present for this standard."
        return $true
    } #we're done.
    $enrollUserOverride = $Settings.EnrollUserOverride.value ?? $Settings.EnrollUserOverride

    try {
        $CurrentState = New-TeamsRequest -TenantFilter $Tenant -Cmdlet 'Get-CsTeamsMeetingPolicy' -cmdParams @{Identity = 'Global' } |
        Select-Object EnrollUserOverride
    }
    catch {
        $ErrorMessage = Get-NormalizedError -Message $_.Exception.Message
        Write-LogMessage -API 'Standards' -Tenant $Tenant -Message "Could not get the TeamsEnrollUser state for $Tenant. Error: $ErrorMessage" -Sev Error
        return
    }

    $StateIsCorrect = ($CurrentState.EnrollUserOverride -eq $enrollUserOverride)

    if ($Settings.remediate -eq $true) {
        if ($StateIsCorrect -eq $true) {
            Write-LogMessage -API 'Standards' -tenant $Tenant -message "Teams Enroll User Override settings already set to $enrollUserOverride." -sev Info
        } else {
            $cmdParams = @{
                Identity           = 'Global'
                EnrollUserOverride = $enrollUserOverride
            }

            try {
                $null = New-TeamsRequest -TenantFilter $Tenant -Cmdlet 'Set-CsTeamsMeetingPolicy' -cmdParams $cmdParams
                Write-LogMessage -API 'Standards' -tenant $Tenant -message "Updated Teams Enroll User Override setting to $enrollUserOverride." -sev Info
            } catch {
                $ErrorMessage = Get-CippException -Exception $_
                Write-LogMessage -API 'Standards' -tenant $Tenant -message "Failed to set Teams Enroll User Override setting to $enrollUserOverride." -sev Error -LogData $ErrorMessage
            }
        }
    }

    if ($Settings.alert -eq $true) {
        if ($StateIsCorrect -eq $true) {
            Write-LogMessage -API 'Standards' -tenant $Tenant -message 'Teams Enroll User Override settings is set correctly.' -sev Info
        } else {
            Write-StandardsAlert -message 'Teams Enroll User Override settings is not set correctly.' -object $CurrentState -tenant $Tenant -standardName 'TeamsEnrollUser' -standardId $Settings.standardId
            Write-LogMessage -API 'Standards' -tenant $Tenant -message 'Teams Enroll User Override settings is not set correctly.' -sev Info
        }
    }

    if ($Settings.report -eq $true) {
        Add-CIPPBPAField -FieldName 'TeamsEnrollUser' -FieldValue $StateIsCorrect -StoreAs bool -Tenant $Tenant

        if ($StateIsCorrect) {
            $FieldValue = $true
        } else {
            $FieldValue = $CurrentState
        }
        Set-CIPPStandardsCompareField -FieldName 'standards.TeamsEnrollUser' -FieldValue $FieldValue -Tenant $Tenant
    }
}
