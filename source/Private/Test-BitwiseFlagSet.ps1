<#
    .SYNOPSIS
        Tests if a value has specific bitwise flags set.

    .DESCRIPTION
        The `Test-BitwiseFlagSet` function performs a bitwise AND operation to
        determine if a value has specific flags set. It returns $true if the
        flags are set, $false otherwise.

    .PARAMETER Value
        The value to test for flags.

    .PARAMETER Flag
        The flag(s) to test for.

    .INPUTS
        None.

    .OUTPUTS
        System.Boolean

        Returns $true if the flag is set, $false otherwise.

    .EXAMPLE
        Test-BitwiseFlagSet -Value 7 -Flag 4

        Returns $true because 7 (binary: 111) has the flag 4 (binary: 100) set.
#>
function Test-BitwiseFlagSet
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Int64]
        $Value,

        [Parameter(Mandatory = $true)]
        [System.Int64]
        $Flag
    )

    return ($Value -band $Flag) -eq $Flag
}
