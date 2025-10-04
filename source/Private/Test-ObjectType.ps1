<#
    .SYNOPSIS
        Tests whether two values have the same type.

    .DESCRIPTION
        The `Test-ObjectType` function checks if two values are of the same type.
        This is used for strict type checking in assertion commands to ensure type
        compatibility before comparing values.

    .PARAMETER ActualValue
        The actual value to check the type of.

    .PARAMETER ExpectedValue
        The expected value to compare the type against.

    .INPUTS
        None. This function does not accept pipeline input.

    .OUTPUTS
        System.Boolean

        Returns $true if the values have the same type, $false otherwise.

    .EXAMPLE
        Test-ObjectType -ActualValue 123 -ExpectedValue 456

        Returns $true because both values are [System.Int32].

    .EXAMPLE
        Test-ObjectType -ActualValue 123 -ExpectedValue '123'

        Returns $false because the types differ ([System.Int32] vs [System.String]).
#>
function Test-ObjectType
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [System.Object]
        $ActualValue,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [System.Object]
        $ExpectedValue
    )

    # Handle null cases
    if ($null -eq $ActualValue -and $null -eq $ExpectedValue)
    {
        # Both null - types match
        return $true
    }

    if ($null -eq $ActualValue -or $null -eq $ExpectedValue)
    {
        # One is null, the other is not - types don't match
        return $false
    }

    # Both are non-null, compare types
    try
    {
        $actualType = $ActualValue.GetType()
    }
    catch
    {
        $errorMessage = $script:localizedData.Test_ObjectType_GetTypeFailed -f $script:localizedData.Common_WordActual

        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                [System.InvalidOperationException]::new($errorMessage),
                'TOT0001',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $ActualValue
            )
        )
    }

    try
    {
        $expectedType = $ExpectedValue.GetType()
    }
    catch
    {
        $errorMessage = $script:localizedData.Test_ObjectType_GetTypeFailed -f $script:localizedData.Common_WordExpected

        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                [System.InvalidOperationException]::new($errorMessage),
                'TOT0001',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $ExpectedValue
            )
        )
    }

    return $actualType -eq $expectedType
}
