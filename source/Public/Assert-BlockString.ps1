<#
    .SYNOPSIS
        Asserts that a string, here-string, or array of strings matches the expected
        value.

    .DESCRIPTION
        The `Assert-BlockString` command compares a string, here-string, or array of
        strings against an expected string, here-string, or array of strings. If
        they are not identical, it throws an error that includes the hex output.
        The comparison is case-sensitive. It is commonly used in unit testing
        scenarios to verify the correctness of string outputs at the byte level.

    .PARAMETER Actual
        The actual string, here-string, or array of strings to be compared with
        the expected value. This parameter accepts pipeline input.

    .PARAMETER Expected
        The expected string, here-string, or array of strings that the actual value
        should match.

    .PARAMETER Because
        An optional reason or explanation for the assertion.

    .PARAMETER Highlight
        An optional ANSI color code to highlight the difference between the expected
        and actual strings. The default value is '31m' (red text).

    .PARAMETER NoHexOutput
        Specifies whether to omit the hex columns and output only the character groups.

    .EXAMPLE
        PS> Assert-BlockString -Actual 'hello', 'world' -Expected 'Hello', 'World'

        This example asserts that the array of strings 'hello' and 'world' matches
        the expected array of strings 'Hello' and 'World'. If the assertion fails,
        an error is thrown.

    .EXAMPLE
        PS> 'hello', 'world' | Assert-BlockString -Expected 'Hello', 'World'

        This example demonstrates the usage of pipeline input. A string array containing
        'hello' and 'world' are piped to `Assert-BlockString` and compared with the
        expected string array containing 'Hello' and 'World'. If the assertion fails,
        an error is thrown.

    .NOTES
        TODO: Is it possible to rename the command to `Should-BeBlockString`? Pester
        handles commands with the `Should` verb; however, it is unclear if this issue
        can be resolved here. See:
        https://github.com/pester/Pester/commit/c8bc9679bed19c8fbc4229caa01dd083f2d03d4f#diff-b7592dd925696de2521c9b12b966d65519d502045462f002c343caa7c0986936
        and
        https://github.com/pester/Pester/commit/c8bc9679bed19c8fbc4229caa01dd083f2d03d4f#diff-460f64eafc16facefbed201eb00fb151c75eadf7cc58a504a01527015fb1c7cdR17
#>
function Assert-BlockString
{
    [Alias('Should-BeBlockString')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseProcessBlockForPipelineCommand', '')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '')]
    param
    (
        [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Actual,

        [Parameter(Position = 0, Mandatory = $true)]
        [System.Object]
        $Expected,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Because,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Highlight = '31m',

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NoHexOutput
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
            $message = $script:localizedData.Assert_BlockString_ActualInvalid
        }
        elseif (-not $isExpectedStringType)
        {
            $message = $script:localizedData.Assert_BlockString_ExpectedInvalid
        }
        else
        {
            $message = $script:localizedData.Assert_BlockString_StringsNotEqual

            if ($Because)
            {
                $message += " {0} $Because" -f $script:localizedData.Assert_BlockString_StringsNotEqual_Because
            }

            $message += "{0}`r`n " -f $script:localizedData.Assert_BlockString_Difference

            $message += Out-Difference -Reference $Expected -Difference $Actual -ReferenceLabel 'Expected:' -DifferenceLabel 'But was:' -HighlightStart:$Highlight -NoHexOutput:$NoHexOutput.IsPresent |
                ForEach-Object -Process { "`e[0m$_`r`n" }
        }

        throw [Pester.Factory]::CreateShouldErrorRecord($Message, $MyInvocation.ScriptName, $MyInvocation.ScriptLineNumber, $MyInvocation.Line.TrimEnd([System.Environment]::NewLine), $true)
    }
}
