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
        When specified and the input is an array, the command iterates through
        each element in the array. Use with -All or -Any to specify validation
        requirements. Without this parameter, the assertion checks the array
        object itself.

    .PARAMETER All
        When used with -Each, requires that all elements in the array have the
        specified flag set. This is the default behavior when -Each is used
        without -Any.

    .PARAMETER Any
        When used with -Each, requires that at least one element in the array
        has the specified flag set. Cannot be used together with -All.

    .INPUTS
        System.Object

        Accepts any integer or enum value via the pipeline for bitwise inspection.

    .OUTPUTS
        None

        This command does not return any output on success.

    .EXAMPLE
        Assert-BitwiseFlag -Actual 7 -Flag 4

        This example asserts that the value 7 (binary: 111) has the flag 4
        (binary: 100) set. This will pass because 7 -band 4 equals 4.

    .EXAMPLE
        $fileAttributes | Assert-BitwiseFlag -Flag [System.IO.FileAttributes]::ReadOnly

        This example demonstrates pipeline usage with enum flags. The file
        attributes value is checked for the ReadOnly flag.

    .EXAMPLE
        Assert-BitwiseFlag -Actual $permissions -Flag 0x04 -Because 'execute permission should be set'

        This example asserts that the permissions value has the execute bit
        (0x04) set, providing a reason for the assertion.

    .EXAMPLE
        @(7, 15, 23) | Assert-BitwiseFlag -Flag 4 -Each -All

        This example asserts that all values in the array have the flag 4 set.
        The `-Each -All` combination checks every element.

    .EXAMPLE
        @(1, 7, 3) | Assert-BitwiseFlag -Flag 4 -Each -Any

        This example asserts that at least one value in the array has the flag 4
        set. This will pass because 7 has the flag 4 set.
#>
function Assert-BitwiseFlag
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples are syntactically correct. The rule does not seem to understand that there is pipeline input.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseProcessBlockForPipelineCommand', '')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '')]
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [Alias('Should-HaveFlag')]
    [OutputType()]
    param
    (
        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'Default')]
        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'EachDefault')]
        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'EachAll')]
        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'EachAny')]
        [System.Object]
        $Flag,

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

    # Validate and convert flag to integer for bitwise operations
    $flagValue = ConvertTo-BitwiseFlagValue -Value $Flag -ParameterName 'Flag' -Because $Because -InvocationInfo $MyInvocation

    # If Each is specified and we have an array, iterate through each element
    if ($Each.IsPresent -and $Actual -is [System.Array] -and $Actual.Count -gt 0)
    {
        # Default to -All if neither -All nor -Any is specified
        $useAny = $Any.IsPresent
        $anyFound = $false

        foreach ($currentValue in $Actual)
        {
            $actualIntValue = ConvertTo-BitwiseFlagValue -Value $currentValue -ParameterName 'Actual' -Because $Because -InvocationInfo $MyInvocation
            $hasFlagSet = Test-BitwiseFlagSet -Value $actualIntValue -Flag $flagValue

            if ($useAny)
            {
                # For -Any, we just need to find one match
                if ($hasFlagSet)
                {
                    $anyFound = $true
                    break
                }
            }
            else
            {
                # For -All (default), all must match
                if (-not $hasFlagSet)
                {
                    $message = $script:localizedData.Assert_BitwiseFlag_FlagNotSet -f $Flag, $currentValue

                    throw (New-AssertionError -Message $message -Because $Because -InvocationInfo $MyInvocation)
                }
            }
        }

        # If using -Any and no match was found, throw error
        if ($useAny -and -not $anyFound)
        {
            $message = $script:localizedData.Assert_BitwiseFlag_NoElementHasFlag -f $Flag

            throw (New-AssertionError -Message $message -Because $Because -InvocationInfo $MyInvocation)
        }
    }
    else
    {
        # Single value case (not an array or empty array)
        $actualIntValue = ConvertTo-BitwiseFlagValue -Value $Actual -ParameterName 'Actual' -Because $Because -InvocationInfo $MyInvocation
        $hasFlagSet = Test-BitwiseFlagSet -Value $actualIntValue -Flag $flagValue

        if (-not $hasFlagSet)
        {
            $message = $script:localizedData.Assert_BitwiseFlag_FlagNotSet -f $Flag, $Actual

            throw (New-AssertionError -Message $message -Because $Because -InvocationInfo $MyInvocation)
        }
    }
}
