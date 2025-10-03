<#
    .SYNOPSIS
        Asserts that an object contains a specified method.

    .DESCRIPTION
        The `Assert-ObjectMethod` command verifies that an object contains a
        specified method. This is commonly used in unit testing scenarios to
        verify object structure and ensure that required methods are available
        on objects before attempting to invoke them.

    .PARAMETER Method
        The name of the method to assert exists on the object.

    .PARAMETER Actual
        The object to be inspected for the method. This parameter accepts
        pipeline input.

    .PARAMETER Because
        An optional reason or explanation for the assertion.

    .INPUTS
        System.Object
            Accepts any object via the pipeline for method inspection.

    .OUTPUTS
        None
            This command does not return any output on success.

    .EXAMPLE
        PS> Assert-ObjectMethod -Actual $myObject -Method 'ToString'

        This example asserts that the object in `$myObject` has a method named
        'ToString'. If the method does not exist, an error is thrown.

    .EXAMPLE
        PS> $myObject | Assert-ObjectMethod -Method 'GetHashCode'

        This example demonstrates pipeline usage. The object `$myObject` is piped
        to `Assert-ObjectMethod` and checked for a method named 'GetHashCode'.

    .EXAMPLE
        PS> Assert-ObjectMethod -Method 'Connect' -Actual $connection -Because 'the connection object should support Connect method'

        This example asserts that `$connection` has a method named 'Connect',
        providing a reason for the assertion.

    .EXAMPLE
        PS> $collection | Assert-ObjectMethod -Method 'Add'

        This example verifies that a collection object has an 'Add' method,
        which is useful when you need to ensure you can add items to a collection.
#>
function Assert-ObjectMethod
{
    [Alias('Should-HaveMethod')]
    [CmdletBinding()]
    [OutputType()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseProcessBlockForPipelineCommand', '')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '')]
    param
    (
        [Parameter(Position = 0, Mandatory = $true)]
        [System.String]
        $Method,

        [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
        $Actual,

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
        $message = $script:localizedData.Assert_ObjectMethod_ActualIsNull

        if ($Because)
        {
            $message += " {0} $Because" -f $script:localizedData.Assert_ObjectMethod_Because
        }

        throw [Pester.Factory]::CreateShouldErrorRecord($message, $MyInvocation.ScriptName, $MyInvocation.ScriptLineNumber, $MyInvocation.Line.TrimEnd([System.Environment]::NewLine), $true)
    }

    # Check if the method exists on the object
    $hasMethod = $false
    try
    {
        # Use Get-Member to check for method existence
        $member = $Actual | Get-Member -Name $Method -MemberType Method, ScriptMethod -ErrorAction SilentlyContinue
        if ($null -ne $member)
        {
            $hasMethod = $true
        }
        else
        {
            # For dynamic objects and PSCustomObject, also check PSObject.Methods
            $methodMember = $Actual.PSObject.Methods[$Method]
            if ($null -ne $methodMember)
            {
                $hasMethod = $true
            }
            else
            {
                # Final check: try to get the method directly for edge cases
                try
                {
                    $methodInfo = $Actual.GetType().GetMethod($Method)
                    if ($null -ne $methodInfo)
                    {
                        $hasMethod = $true
                    }
                }
                catch
                {
                    # If reflection fails, the method doesn't exist
                    $hasMethod = $false
                }
            }
        }
    }
    catch
    {
        $hasMethod = $false
    }

    if (-not $hasMethod)
    {
        $message = $script:localizedData.Assert_ObjectMethod_MethodNotFound -f $Method

        if ($Because)
        {
            $message += " {0} $Because" -f $script:localizedData.Assert_ObjectMethod_Because
        }

        throw [Pester.Factory]::CreateShouldErrorRecord($message, $MyInvocation.ScriptName, $MyInvocation.ScriptLineNumber, $MyInvocation.Line.TrimEnd([System.Environment]::NewLine), $true)
    }
}
