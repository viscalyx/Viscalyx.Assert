<#
    .SYNOPSIS
        Tests whether a value can be used in bitwise operations.

    .DESCRIPTION
        The `Test-BitwiseCompatible` function checks if a value is of a type
        that supports bitwise operations (integers, enums, etc.).

    .PARAMETER Value
        The value to test for bitwise compatibility.

    .INPUTS
        None.

        This function does not accept pipeline input.

    .OUTPUTS
        System.Boolean

        Returns $true if the value can be used in bitwise operations, $false otherwise.

    .EXAMPLE
        Test-BitwiseCompatible -Value 42

        Returns $true because integers support bitwise operations.

    .EXAMPLE
        Test-BitwiseCompatible -Value [System.IO.FileAttributes]::ReadOnly

        Returns $true because enums support bitwise operations.
#>
function Test-BitwiseCompatible
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [System.Object]
        $Value
    )

    if ($null -eq $Value)
    {
        return $false
    }

    $type = $Value.GetType()

    # Check for numeric types that support bitwise operations
    $bitwiseTypes = @(
        [System.Byte],
        [System.SByte],
        [System.Int16],
        [System.UInt16],
        [System.Int32],
        [System.UInt32],
        [System.Int64],
        [System.UInt64]
    )

    if ($type -in $bitwiseTypes)
    {
        return $true
    }

    # Check if it's an enum (enums support bitwise operations)
    if ($type.IsEnum)
    {
        return $true
    }

    return $false
}
