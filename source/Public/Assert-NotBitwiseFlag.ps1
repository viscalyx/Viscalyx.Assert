<#
    .SYNOPSIS
        Asserts that a value does not have specific bitwise flags set.

    .DESCRIPTION
        The `Assert-NotBitwiseFlag` command verifies that an integer value does
        not have specific bitwise flags set. This is commonly used in unit
        testing scenarios to verify enum flags, permission masks, file attributes,
        and other bitwise operations.

    .PARAMETER Expected
        The bitwise flag(s) to assert are not set on the value. Can be an integer
        or an enum value.

    .PARAMETER Actual
        The value to be inspected for the bitwise flag. This parameter accepts
        pipeline input.

    .PARAMETER Because
        An optional reason or explanation for the assertion.

    .PARAMETER Each
        When specified and the input is an array, the command iterates through
        each element in the array. Use with -All or -Any to specify validation
        requirements. Without this parameter, the assertion checks the array
        object itself.

    .PARAMETER All
        When used with -Each, requires that all elements in the array do not have
        the specified flag set. This is the default behavior when -Each is used
        without -Any.

    .PARAMETER Any
        When used with -Each, requires that at least one element in the array
        does not have the specified flag set. Cannot be used together with -All.

    .INPUTS
        System.Object

        Accepts any integer or enum value via the pipeline for bitwise inspection.

    .OUTPUTS
        None

        This command does not return any output on success.

    .EXAMPLE
        Assert-NotBitwiseFlag -Actual 3 -Expected 4

        This example asserts that the value 3 (binary: 011) does NOT have the
        flag 4 (binary: 100) set. This will pass because 3 -band 4 equals 0.

    .EXAMPLE
        $fileAttributes | Assert-NotBitwiseFlag -Expected [System.IO.FileAttributes]::Hidden

        This example demonstrates pipeline usage with enum flags. The file
        attributes value is checked to ensure the Hidden flag is not set.

    .EXAMPLE
        Assert-NotBitwiseFlag -Actual $permissions -Expected 0x02 -Because 'write permission should not be set for read-only user'

        This example asserts that the permissions value does not have the write bit
        (0x02) set, providing a reason for the assertion.

    .EXAMPLE
        @(1, 2, 3) | Assert-NotBitwiseFlag -Expected 4 -Each -All

        This example asserts that all values in the array do not have the flag 4
        set. The `-Each -All` combination checks every element.

    .EXAMPLE
        @(7, 7, 7) | Assert-NotBitwiseFlag -Expected 4 -Each -Any

        This example asserts that at least one value in the array does not have
        the flag 4 set. This will fail because all values (7) have the flag 4 set.
#>
function Assert-NotBitwiseFlag
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples are syntactically correct. The rule does not seem to understand that there is pipeline input.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseProcessBlockForPipelineCommand', '')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '')]
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [Alias('Should-NotHaveFlag')]
    [OutputType()]
    param
    (
        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'Default')]
        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'EachDefault')]
        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'EachAll')]
        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'EachAny')]
        [System.Object]
        $Expected,

        [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Default')]
        [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'EachDefault')]
        [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'EachAll')]
        [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'EachAny')]
        [System.Object]
        $Actual,

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'EachDefault')]
        [Parameter(ParameterSetName = 'EachAll')]
        [Parameter(ParameterSetName = 'EachAny')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Because,

        [Parameter(Mandatory = $true, ParameterSetName = 'EachDefault')]
        [Parameter(Mandatory = $true, ParameterSetName = 'EachAll')]
        [Parameter(Mandatory = $true, ParameterSetName = 'EachAny')]
        [System.Management.Automation.SwitchParameter]
        $Each,

        [Parameter(Mandatory = $true, ParameterSetName = 'EachAll')]
        [System.Management.Automation.SwitchParameter]
        $All,

        [Parameter(Mandatory = $true, ParameterSetName = 'EachAny')]
        [System.Management.Automation.SwitchParameter]
        $Any
    )

    $processedInput = Get-ProcessedPipelineInput -InvocationInfo $MyInvocation -Each:$Each

    if ($null -ne $processedInput)
    {
        $Actual = $processedInput
    }

    # Validate flag for bitwise operations
    Assert-BitwiseType -Value $Expected -ParameterName $script:localizedData.Common_WordExpected -Because $Because -InvocationInfo $MyInvocation

    # If Each is specified and we have an array, iterate through each element
    if ($Each.IsPresent -and $Actual -is [System.Array] -and $Actual.Count -gt 0)
    {
        # Default to -All if neither -All nor -Any is specified
        $useAny = $Any.IsPresent
        $useAll = $All.IsPresent -or -not $Any.IsPresent
        $anyFound = $false

        foreach ($currentValue in $Actual)
        {
            # Validate current value for bitwise operations
            Assert-BitwiseType -Value $currentValue -ParameterName $script:localizedData.Common_WordActual -Because $Because -InvocationInfo $MyInvocation

            $hasFlagSet = Test-BitwiseFlagSet -Value $currentValue -Expected $Expected

            if ($useAny)
            {
                # For -Any, we just need to find one without the flag
                if (-not $hasFlagSet)
                {
                    $anyFound = $true
                    break
                }
            }
            elseif ($useAll)
            {
                # For -All (default), none should have the flag
                if ($hasFlagSet)
                {
                    $message = $script:localizedData.Assert_BitwiseFlag_FlagShouldNotBeSet -f $Expected, $currentValue

                    throw (New-AssertionError -Message $message -Because $Because -InvocationInfo $MyInvocation)
                }
            }
        }

        # If using -Any and no element without the flag was found, throw error
        if ($useAny -and -not $anyFound)
        {
            $message = $script:localizedData.Assert_BitwiseFlag_AllElementsHaveFlag -f $Expected

            throw (New-AssertionError -Message $message -Because $Because -InvocationInfo $MyInvocation)
        }
    }
    else
    {
        # Single value case (not an array or empty array)
        Assert-BitwiseType -Value $Actual -ParameterName $script:localizedData.Common_WordActual -Because $Because -InvocationInfo $MyInvocation

        $hasFlagSet = Test-BitwiseFlagSet -Value $Actual -Expected $Expected

        if ($hasFlagSet)
        {
            $message = $script:localizedData.Assert_BitwiseFlag_FlagShouldNotBeSet -f $Expected, $Actual

            throw (New-AssertionError -Message $message -Because $Because -InvocationInfo $MyInvocation)
        }
    }
}
