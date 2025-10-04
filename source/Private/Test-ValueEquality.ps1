<#
    .SYNOPSIS
        Tests whether two values are equal.

    .DESCRIPTION
        The `Test-ValueEquality` function performs equality comparison between
        two values, handling special cases such as null values and arrays.
        This function assumes type compatibility has already been validated
        when strict type checking is required.

    .PARAMETER ActualValue
        The actual value to compare.

    .PARAMETER ExpectedValue
        The expected value to compare against.

    .OUTPUTS
        System.Boolean

        Returns $true if the values are equal, $false otherwise.

    .EXAMPLE
        Test-ValueEquality -ActualValue $actual -ExpectedValue $expected

        Compares $actual and $expected values for equality.

    .EXAMPLE
        Test-ValueEquality -ActualValue @(1, 2, 3) -ExpectedValue @(1, 2, 3)

        Returns $true because the arrays have the same elements in the same order.
#>
function Test-ValueEquality
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

    $valuesAreEqual = $false

    if ($null -eq $ActualValue -and $null -eq $ExpectedValue)
    {
        $valuesAreEqual = $true
    }
    elseif ($null -eq $ActualValue -or $null -eq $ExpectedValue)
    {
        # One is null and the other is not
        $valuesAreEqual = $false
    }
    elseif ($ActualValue -is [System.Array] -and $ExpectedValue -is [System.Array])
    {
        # Use StructuralEqualityComparer for element-wise array comparison (supports value-type arrays)
        $valuesAreEqual = [System.Collections.StructuralComparisons]::StructuralEqualityComparer.Equals($ActualValue, $ExpectedValue)
    }
    else
    {
        # Use PowerShell's built-in comparison
        $valuesAreEqual = $ActualValue -eq $ExpectedValue
    }

    return $valuesAreEqual
}
