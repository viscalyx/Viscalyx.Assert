<#
    .SYNOPSIS
        Asserts that a string, here-string or array of strings matches the expected
        string, here-string or array of strings.

    .DESCRIPTION
        The `Assert-BlockString` command compares a string, here-string or array
        of strings with the expected string, here-string or array of strings and
        throws an error that includes the hex output if they are not equal. The
        comparison is case sensitive. It is commonly used in unit testing scenarios
        to verify the correctness of string outputs on byte level.

    .PARAMETER Actual
        The actual string, here-string or array of strings to be compared with the
        expected value. This parameter accepts pipeline input.

    .PARAMETER Expected
        The expected string, here-string or array of strings that the actual value
        should match.

    .PARAMETER Because
        An optional reason or explanation for the assertion.

    .PARAMETER Highlight
        An optional ANSI color code to highlight the difference between the expected
        and actual strings. The default value is '31m' (red text).

    .EXAMPLE
        PS> Assert-BlockString -Actual 'hello', 'world' -Expected 'Hello', 'World'

        This example asserts that the array of strings 'hello' and 'world' matches
        the expected array of strings 'Hello' and 'World'. If the assertion fails,
        an error is thrown.

    .EXAMPLE
        PS> 'hello', 'world' | Assert-BlockString -Expected 'Hello', 'World'

        This example demonstrates the usage of pipeline input. The block of strings
        'Hello' and 'World' is piped to `Assert-BlockString` and compared with the
        expected strings 'Hello' and 'World'. If the assertion fails, an error is
        thrown.

    .NOTES
        TODO: Is it possible to rename command to `Should-BeBlockString`. Pester handles Should verb with, not sure it possible to resolve here:
        https://github.com/pester/Pester/commit/c8bc9679bed19c8fbc4229caa01dd083f2d03d4f#diff-b7592dd925696de2521c9b12b966d65519d502045462f002c343caa7c0986936
        and
        https://github.com/pester/Pester/commit/c8bc9679bed19c8fbc4229caa01dd083f2d03d4f#diff-460f64eafc16facefbed201eb00fb151c75eadf7cc58a504a01527015fb1c7cdR17
#>
function Assert-BlockString
{
    [Alias('Should-BeBlockString')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseProcessBlockForPipelineCommand', '')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '')]
    param
    (
        [Parameter(Position = 1, ValueFromPipeline = $true)]
        $Actual,

        [Parameter(Position = 0, Mandatory = $true)]
        $Expected,

        [Parameter()]
        [System.String]
        $Because,

        [Parameter()]
        [System.String]
        $Highlight = '31m'
    )

    $hasPipelineInput = $MyInvocation.ExpectingInput

    if ($hasPipelineInput)
    {
        $Actual = @($local:Input)
    }

    # Verify if $Actual is a string or string array
    $isActualStringType = $Actual -is [System.String] -or ($Actual -is [System.Array] -and ($Actual.Count -eq 0 -or ($Actual.Count -gt 0 -and $Actual[0] -is [System.String])))

    $isExpectedStringType = $Expected -is [System.String] -or ($Expected -is [System.Array] -and ($Expected.Count -eq 0 -or ($Expected.Count -gt 0 -and $Expected[0] -is [System.String])))

    $stringsAreEqual = $isActualStringType -and $isExpectedStringType -and (-join $Actual) -ceq (-join $Expected)

    if (-not $stringsAreEqual)
    {
        if (-not $isActualStringType)
        {
            $message = 'The Actual value must be of type string or string[], but it was not.'
        }
        elseif (-not $isExpectedStringType)
        {
            $message = 'The Expected value must be of type string or string[], but it was not.'
        }
        else
        {
            $message = 'Expected the strings to be equal'

            if ($Because)
            {
                $message += " because $Because"
            }

            $message += ", but they were not. Difference is highlighted:`r`n "

            $message += Out-Difference -Reference $Expected -Difference $Actual -ReferenceLabel 'Expected:' -DifferenceLabel 'But was:' -HighlightStart:$Highlight |
                ForEach-Object -Process { "`e[0m$_`r`n" }
        }

        throw [Pester.Factory]::CreateShouldErrorRecord($Message, $MyInvocation.ScriptName, $MyInvocation.ScriptLineNumber, $MyInvocation.Line.TrimEnd([System.Environment]::NewLine), $true)
    }
}
