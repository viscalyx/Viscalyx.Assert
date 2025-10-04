<#
    .SYNOPSIS
        Gets the full type name of a value.

    .DESCRIPTION
        The `Get-TypeName` command returns the full type name of a value. If the
        value is `$null`, it returns the string 'null' instead of attempting to
        call GetType() on a null reference.

    .PARAMETER Value
        The value to get the type name for.

    .INPUTS
        None

        This command does not accept pipeline input.

    .OUTPUTS
        System.String

        Returns the full type name as a string, or 'null' if the value is null.

    .EXAMPLE
        Get-TypeName -Value 'Hello'

        Returns 'System.String'.

    .EXAMPLE
        Get-TypeName -Value $null

        Returns 'null'.

    .EXAMPLE
        Get-TypeName -Value 123

        Returns 'System.Int32'.
#>
function Get-TypeName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [System.Object]
        $Value
    )

    if ($null -eq $Value)
    {
        return 'null'
    }

    return $Value.GetType().FullName
}
