<#
    .SYNOPSIS
        Asserts that an object contains a specified property and optionally that
        the property has a specified value.

    .DESCRIPTION
        The `Assert-ObjectProperty` command verifies that an object contains a
        specified property. It can optionally also verify that the property has
        a specific value. This is commonly used in unit testing scenarios to
        verify object structure and property values.

    .PARAMETER Property
        The name of the property to assert exists on the object.

    .PARAMETER Actual
        The object to be inspected for the property. This parameter accepts
        pipeline input.

    .PARAMETER Value
        The expected value of the property. If specified, the assertion will
        check both property existence and value equality.

    .PARAMETER Because
        An optional reason or explanation for the assertion.

    .INPUTS
        System.Object
            Accepts any object via the pipeline for property inspection.

    .OUTPUTS
        None
            This command does not return any output on success.

    .EXAMPLE
        PS> Assert-ObjectProperty -Actual $myObject -Property 'Enabled'

        This example asserts that the object in `$myObject` has a property named
        'Enabled'. If the property does not exist, an error is thrown.

    .EXAMPLE
        PS> Assert-ObjectProperty -Actual $myObject -Property 'Enabled' -Value $true

        This example asserts that the object in `$myObject` has a property named
        'Enabled' with the value `$true`. If the property does not exist or the
        value does not match, an error is thrown.

    .EXAMPLE
        PS> $myObject | Assert-ObjectProperty -Property 'Status' -Value 'Running'

        This example demonstrates pipeline usage. The object `$myObject` is piped
        to `Assert-ObjectProperty` and checked for a property named 'Status' with
        the value 'Running'.

    .EXAMPLE
        PS> Assert-ObjectProperty -Property 'Count' -Actual $collection -Value 5 -Because 'the collection should contain exactly 5 items'

        This example asserts that `$collection` has a property named 'Count' with
        the value 5, providing a reason for the assertion.
#>
function Assert-ObjectProperty
{
    [Alias('Should-HaveProperty')]
    [CmdletBinding(DefaultParameterSetName = 'AssertProperty')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseProcessBlockForPipelineCommand', '')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '')]
    param
    (
        [Parameter(ParameterSetName = 'AssertProperty', Position = 0, Mandatory = $true)]
        [Parameter(ParameterSetName = 'AssertValue', Position = 0, Mandatory = $true)]
        [System.String]
        $Property,

        [Parameter(ParameterSetName = 'AssertProperty', Position = 1, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'AssertValue', Position = 2, ValueFromPipeline = $true)]
        $Actual,

        [Parameter(ParameterSetName = 'AssertValue', Position = 1, Mandatory = $true)]
        [AllowNull()]
        $Value,

        [Parameter()]
        [System.String]
        $Because
    )

    $hasPipelineInput = $MyInvocation.ExpectingInput

    if ($hasPipelineInput)
    {
        $Actual = @($local:Input)

        # If we received multiple objects via pipeline, use the last one
        if ($Actual.Count -gt 1)
        {
            $Actual = $Actual[-1]
        }
        elseif ($Actual.Count -eq 1)
        {
            $Actual = $Actual[0]
        }
    }

    # Check if the actual value is null
    if ($null -eq $Actual)
    {
        $message = $script:localizedData.Assert_ObjectProperty_ActualIsNull

        if ($Because)
        {
            $message += " {0} $Because" -f $script:localizedData.Assert_ObjectProperty_Because
        }

        throw [Pester.Factory]::CreateShouldErrorRecord($message, $MyInvocation.ScriptName, $MyInvocation.ScriptLineNumber, $MyInvocation.Line.TrimEnd([System.Environment]::NewLine), $true)
    }

    # Check if the property exists on the object
    $hasProperty = $false
    try
    {
        # For hashtables, check if the key exists
        if ($Actual -is [System.Collections.IDictionary])
        {
            $hasProperty = $Actual.ContainsKey($Property)
        }
        # For PSCustomObject and other objects, try PSObject.Properties first
        elseif ($null -ne $Actual.PSObject.Properties[$Property])
        {
            $hasProperty = $true
        }
        # Use Get-Member as fallback for .NET objects
        else
        {
            $member = $Actual | Get-Member -Name $Property -MemberType Properties, NoteProperty -ErrorAction SilentlyContinue
            if ($null -ne $member)
            {
                $hasProperty = $true
            }
            else
            {
                # Final check with direct property access for edge cases
                try
                {
                    $null = $Actual.$Property
                    # If we got here without exception, the property exists
                    # But we need to make sure it's not just returning $null for non-existent properties
                    $actualMember = $Actual.PSObject.Members | Where-Object { $_.Name -eq $Property }
                    $hasProperty = $null -ne $actualMember
                }
                catch
                {
                    $hasProperty = $false
                }
            }
        }
    }
    catch
    {
        $hasProperty = $false
    }

    if (-not $hasProperty)
    {
        $message = $script:localizedData.Assert_ObjectProperty_PropertyNotFound -f $Property

        if ($Because)
        {
            $message += " {0} $Because" -f $script:localizedData.Assert_ObjectProperty_Because
        }

        throw [Pester.Factory]::CreateShouldErrorRecord($message, $MyInvocation.ScriptName, $MyInvocation.ScriptLineNumber, $MyInvocation.Line.TrimEnd([System.Environment]::NewLine), $true)
    }

    # If we're in the AssertValue parameter set, also check the value
    if ($PSCmdlet.ParameterSetName -eq 'AssertValue')
    {
        $actualValue = $Actual.$Property

        # Use more sophisticated comparison that handles arrays and null values correctly
        $valuesAreEqual = $false
        if ($null -eq $actualValue -and $null -eq $Value)
        {
            $valuesAreEqual = $true
        }
        elseif ($actualValue -is [System.Array] -and $Value -is [System.Array])
        {
            # Use SequenceEqual for efficient structural array comparison
            $valuesAreEqual = [System.Linq.Enumerable]::SequenceEqual([System.Collections.Generic.IEnumerable[object]]$actualValue, [System.Collections.Generic.IEnumerable[object]]$Value)
        }
        else
        {
            # Use PowerShell's built-in comparison for other types
            $valuesAreEqual = $actualValue -eq $Value
        }

        if (-not $valuesAreEqual)
        {
            $message = $script:localizedData.Assert_ObjectProperty_ValueMismatch -f $Property, $Value, $actualValue

            if ($Because)
            {
                $message += " {0} $Because" -f $script:localizedData.Assert_ObjectProperty_Because
            }

            throw [Pester.Factory]::CreateShouldErrorRecord($message, $MyInvocation.ScriptName, $MyInvocation.ScriptLineNumber, $MyInvocation.Line.TrimEnd([System.Environment]::NewLine), $true)
        }
    }
}
