<#
    .SYNOPSIS
        Creates a Pester assertion error record.

    .DESCRIPTION
        The `New-AssertionError` function creates a Pester-formatted error record
        with optional 'because' reasoning. This standardizes error creation across
        assertion commands.

    .PARAMETER Message
        The error message to include in the assertion error.

    .PARAMETER Because
        An optional reason or explanation for the assertion failure.

    .PARAMETER InvocationInfo
        The invocation information from the calling command, used to populate
        the error record with script name, line number, and line content.

    .INPUTS
        None. This function does not accept pipeline input.

    .OUTPUTS
        System.Management.Automation.ErrorRecord

        Returns a Pester-formatted error record.

    .EXAMPLE
        New-AssertionError -Message "Property not found" -Because "it is required" -InvocationInfo $MyInvocation

        Creates an assertion error with a because clause.
#>
function New-AssertionError
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'This function does not change system state, it only creates an error record object.')]
    [CmdletBinding()]
    [OutputType([System.Management.Automation.ErrorRecord])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Message,

        [Parameter()]
        [System.String]
        $Because,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.InvocationInfo]
        $InvocationInfo
    )

    if ($Because)
    {
        # Insert 'because <reason>' before ', but' to follow Pester's pattern:
        # "Expected <value>, because <reason>, but got <actual>"
        if ($Message -match ',\s+but\s+')
        {
            $Message = $Message -replace ',\s+but\s+', (", {0} $Because, but " -f $script:localizedData.Common_WordBecause)
        }
        else
        {
            # Fallback: append at the end if no ', but' pattern found
            $Message += " {0} $Because" -f $script:localizedData.Common_WordBecause
        }
    }

    $errorRecord = [Pester.Factory]::CreateShouldErrorRecord(
        $Message,
        $InvocationInfo.ScriptName,
        $InvocationInfo.ScriptLineNumber,
        $InvocationInfo.Line.TrimEnd([System.Environment]::NewLine),
        $true
    )

    return $errorRecord
}
