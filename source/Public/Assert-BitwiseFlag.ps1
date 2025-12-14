<#
    .SYNOPSIS
        Asserts that a value has specific bitwise flags set.

    .DESCRIPTION
        The `Assert-BitwiseFlag` command verifies that an integer value has
        specific bitwise flags set. This is commonly used in unit testing
        scenarios to verify enum flags, permission masks, file attributes,
        and other bitwise operations.

    .PARAMETER Flag
        The bitwise flag(s) to assert are set on the value. Can be an integer
        or an enum value.

    .PARAMETER Actual
        The value to be inspected for the bitwise flag. This parameter accepts
        pipeline input.

    .PARAMETER Because
        An optional reason or explanation for the assertion.

    .PARAMETER Each
        When specified and the input is an array, asserts that each element in
        the array has the specified flag set. Without this parameter, the
        assertion checks the array object itself.

    .INPUTS
        System.Object

        Accepts any integer or enum value via the pipeline for bitwise inspection.

    .OUTPUTS
        None

        This command does not return any output on success.

    .EXAMPLE
        PS> Assert-BitwiseFlag -Actual 7 -Flag 4

        This example asserts that the value 7 (binary: 111) has the flag 4
        (binary: 100) set. This will pass because 7 -band 4 equals 4.

    .EXAMPLE
        PS> $fileAttributes | Assert-BitwiseFlag -Flag [System.IO.FileAttributes]::ReadOnly

        This example demonstrates pipeline usage with enum flags. The file
        attributes value is checked for the ReadOnly flag.

    .EXAMPLE
        PS> Assert-BitwiseFlag -Actual $permissions -Flag 0x04 -Because 'execute permission should be set'

        This example asserts that the permissions value has the execute bit
        (0x04) set, providing a reason for the assertion.

    .EXAMPLE
        PS> @(7, 15, 23) | Assert-BitwiseFlag -Flag 4 -Each

        This example asserts that each value in the array has the flag 4 set.
        The `-Each` parameter enables element-by-element checking.
#>
function Assert-BitwiseFlag
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseProcessBlockForPipelineCommand', '')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '')]
    [CmdletBinding()]
    [Alias('Should-HaveFlag')]
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

            if (-not $hasFlagSet)
            {
                $message = $script:localizedData.Assert_BitwiseFlag_FlagNotSet -f $Flag, $currentValue
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

        if (-not $hasFlagSet)
        {
            $message = $script:localizedData.Assert_BitwiseFlag_FlagNotSet -f $Flag, $Actual
            throw (New-AssertionError -Message $message -Because $Because -InvocationInfo $MyInvocation)
        }
    }
}
