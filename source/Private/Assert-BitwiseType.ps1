<#
    .SYNOPSIS
        Validates that a value is compatible with bitwise operations.

    .DESCRIPTION
        The `Assert-BitwiseType` function validates that a value is compatible
        with bitwise operations (integer or enum type). If the value is not
        compatible, it throws a terminating error with a localized message.

    .PARAMETER Value
        The value to validate for bitwise compatibility.

    .PARAMETER ParameterName
        The name of the parameter being validated (e.g., 'Expected' or 'Actual').
        This is used in the error message.

    .PARAMETER Because
        An optional reason or explanation for the assertion.

    .PARAMETER InvocationInfo
        The invocation information from the calling command.

    .INPUTS
        None.

    .OUTPUTS
        None.

    .EXAMPLE
        Assert-BitwiseType -Value 42 -ParameterName 'Expected' -InvocationInfo $MyInvocation

        Validates that the value 42 is compatible with bitwise operations.
        Since 42 is an integer, this will succeed without throwing an error.
#>
function Assert-BitwiseType
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '')]
    [CmdletBinding()]
    [OutputType()]
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

    if (-not (Test-BitwiseCompatible -Value $Value))
    {
        $typeName = if ($null -eq $Value)
        {
            'null'
        }
        else
        {
            $Value.GetType().FullName
        }

        $message = $script:localizedData.Assert_BitwiseFlag_InvalidType -f $ParameterName, $typeName

        throw (New-AssertionError -Message $message -Because $Because -InvocationInfo $InvocationInfo)
    }
}
