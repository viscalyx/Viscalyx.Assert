<#
    .SYNOPSIS
        Asserts that a value does not have specific bitwise flags set.

    .DESCRIPTION
        The `Assert-NotBitwiseFlag` command verifies that an integer value does
        not have specific bitwise flags set. This is commonly used in unit
        testing scenarios to verify enum flags, permission masks, file attributes,
        and other bitwise operations.

    .PARAMETER Flag
        The bitwise flag(s) to assert are not set on the value. Can be an integer
        or an enum value.

    .PARAMETER Actual
        The value to be inspected for the bitwise flag. This parameter accepts
        pipeline input.

    .PARAMETER Because
        An optional reason or explanation for the assertion.

    .PARAMETER Each
        When specified and the input is an array, asserts that each element in
        the array does not have the specified flag set. Without this parameter,
        the assertion checks the array object itself.

    .INPUTS
        System.Object

        Accepts any integer or enum value via the pipeline for bitwise inspection.

    .OUTPUTS
        None

        This command does not return any output on success.

    .EXAMPLE
        Assert-NotBitwiseFlag -Actual 3 -Flag 4

        This example asserts that the value 3 (binary: 011) does NOT have the
        flag 4 (binary: 100) set. This will pass because 3 -band 4 equals 0.

    .EXAMPLE
        $fileAttributes | Assert-NotBitwiseFlag -Flag [System.IO.FileAttributes]::Hidden

        This example demonstrates pipeline usage with enum flags. The file
        attributes value is checked to ensure the Hidden flag is not set.

    .EXAMPLE
        Assert-NotBitwiseFlag -Actual $permissions -Flag 0x02 -Because 'write permission should not be set for read-only user'

        This example asserts that the permissions value does not have the write bit
        (0x02) set, providing a reason for the assertion.

    .EXAMPLE
        @(1, 2, 3) | Assert-NotBitwiseFlag -Flag 4 -Each

        This example asserts that each value in the array does not have the flag 4 set.
        The `-Each` parameter enables element-by-element checking.
#>
function Assert-NotBitwiseFlag
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseProcessBlockForPipelineCommand', '')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '')]
    [CmdletBinding()]
    [Alias('Should-NotHaveFlag')]
    [OutputType()]
    param
    (
        [Parameter(Position = 0, Mandatory = $true)]
        [System.Object]
        $Flag,

        [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Actual,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Because,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Each
    )

    $hasPipelineInput = $MyInvocation.ExpectingInput

    if ($hasPipelineInput)
    {
        $Actual = @($local:Input)

        # If we're not using -Each and we have a single-element array, unwrap it
        if (-not $Each.IsPresent -and $Actual.Count -eq 1)
        {
            $Actual = $Actual[0]
        }
    }

    # Convert flag to integer for bitwise operations
    $flagValue = [System.Int64] $Flag

    # If Each is specified and we have an array, iterate through each element
    if ($Each.IsPresent -and $Actual -is [System.Array] -and $Actual.Count -gt 0)
    {
        foreach ($currentValue in $Actual)
        {
            # Check if the current value is null
            if ($null -eq $currentValue)
            {
                $message = $script:localizedData.Assert_BitwiseFlag_ActualIsNull
                throw (New-AssertionError -Message $message -Because $Because -InvocationInfo $MyInvocation)
            }

            # Validate that the value can be used in bitwise operations
            if (-not (Test-BitwiseCompatible -Value $currentValue))
            {
                $message = $script:localizedData.Assert_BitwiseFlag_InvalidType -f $currentValue.GetType().FullName
                throw (New-AssertionError -Message $message -Because $Because -InvocationInfo $MyInvocation)
            }

            $actualIntValue = [System.Int64] $currentValue
            $hasFlagSet = ($actualIntValue -band $flagValue) -eq $flagValue

            if ($hasFlagSet)
            {
                $message = $script:localizedData.Assert_BitwiseFlag_FlagShouldNotBeSet -f $Flag, $currentValue
                throw (New-AssertionError -Message $message -Because $Because -InvocationInfo $MyInvocation)
            }
        }
    }
    else
    {
        # Single value case (not an array or empty array)
        # Check if the actual value is null
        if ($null -eq $Actual)
        {
            $message = $script:localizedData.Assert_BitwiseFlag_ActualIsNull
            throw (New-AssertionError -Message $message -Because $Because -InvocationInfo $MyInvocation)
        }

        # Validate that the value can be used in bitwise operations
        if (-not (Test-BitwiseCompatible -Value $Actual))
        {
            $message = $script:localizedData.Assert_BitwiseFlag_InvalidType -f $Actual.GetType().FullName
            throw (New-AssertionError -Message $message -Because $Because -InvocationInfo $MyInvocation)
        }

        $actualIntValue = [System.Int64] $Actual
        $hasFlagSet = ($actualIntValue -band $flagValue) -eq $flagValue

        if ($hasFlagSet)
        {
            $message = $script:localizedData.Assert_BitwiseFlag_FlagShouldNotBeSet -f $Flag, $Actual
            throw (New-AssertionError -Message $message -Because $Because -InvocationInfo $MyInvocation)
        }
    }
}
