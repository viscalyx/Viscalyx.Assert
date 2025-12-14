<#
    .SYNOPSIS
        Validates and converts a value to Int64 for bitwise operations.

    .DESCRIPTION
        The `ConvertTo-BitwiseFlagValue` function validates that a value can be
        used in bitwise operations and converts it to Int64. This is used by
        bitwise assertion commands to ensure values are compatible with bitwise
        operations.

    .PARAMETER Value
        The value to validate and convert.

    .PARAMETER ParameterName
        The name of the parameter being validated, used in error messages.

    .PARAMETER Because
        An optional reason for the validation, used in error messages.

    .PARAMETER InvocationInfo
        The invocation info from the calling command, used for error reporting.

    .INPUTS
        None.

    .OUTPUTS
        System.Int64

        Returns the value converted to Int64.

    .EXAMPLE
        $result = ConvertTo-BitwiseFlagValue -Value 4 -ParameterName 'Flag' -InvocationInfo $MyInvocation

        Validates that the value 4 is bitwise-compatible and converts it to Int64.
#>
function ConvertTo-BitwiseFlagValue
{
    [CmdletBinding()]
    [OutputType([System.Int64])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [System.Object]
        $Value,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ParameterName,

        [Parameter()]
        [System.String]
        $Because,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.InvocationInfo]
        $InvocationInfo
    )

    # Check if the value is null
    if ($null -eq $Value)
    {
        $message = $script:localizedData.Assert_BitwiseFlag_ActualIsNull

        throw (New-AssertionError -Message $message -Because $Because -InvocationInfo $InvocationInfo)
    }

    # Validate that the value can be used in bitwise operations
    if (-not (Test-BitwiseCompatible -Value $Value))
    {
        $localizedStringKey = if ($ParameterName -eq 'Flag')
        {
            'Assert_BitwiseFlag_InvalidFlagType'
        }
        else
        {
            'Assert_BitwiseFlag_InvalidType'
        }

        $message = $script:localizedData.$localizedStringKey -f $Value.GetType().FullName

        throw (New-AssertionError -Message $message -Because $Because -InvocationInfo $InvocationInfo)
    }

    return [System.Int64] $Value
}
