<#
    The choice of encoding method depends on your specific requirements and the context in which you are working. Here are some common encoding methods and their typical use cases:

    UTF-8:

    Use Case: This is the most commonly used encoding on the web and is compatible with ASCII. It is efficient for text that primarily uses characters from the ASCII set but can also represent any Unicode character.
    Pros: Compact for ASCII characters, widely supported.
    Cons: Variable-length encoding can be less efficient for characters outside the ASCII range.
    ASCII:

    Use Case: Suitable for text that only contains characters in the ASCII set (0-127).
    Pros: Very compact for ASCII characters.
    Cons: Cannot represent characters outside the ASCII range.
    Unicode (UTF-16):

    Use Case: Often used in Windows environments and for text that contains a large number of non-ASCII characters.
    Pros: Fixed-length for most common characters, widely supported.
    Cons: Less efficient for ASCII-only text compared to UTF-8.
    UTF-32:

    Use Case: Used when fixed-length encoding is required, and memory usage is not a concern.
    Pros: Fixed-length encoding makes it easy to index characters.
    Cons: Uses more memory compared to UTF-8 and UTF-16.

    Given these considerations, UTF-8 is generally a good default choice due to its efficiency and wide support.
#>
# $string = "Your string here"

# # Convert the string to a byte array using UTF-8 encoding
# $byteArray = [System.Text.Encoding]::UTF8.GetBytes($string)

# # Create a ByteCollection from the byte array
# $byteCollection = [Microsoft.PowerShell.Commands.ByteCollection]::new($byteArray)

# # Convert the byte array to a hexadecimal string
# $hexString = -join ($byteArray | ForEach-Object { "{0:X2} " -f $_ })

# # Output the ByteCollection and the hexadecimal string to verify
# $byteCollection
# $hexString

# [System.BitConverter]::ToString($byteArray) -replace '-', ' '

#Tags = @('testing', 'tdd', 'bdd', 'assertion', 'assert', 'pester')

# Pester handles Should verb with:
# https://github.com/pester/Pester/commit/c8bc9679bed19c8fbc4229caa01dd083f2d03d4f#diff-b7592dd925696de2521c9b12b966d65519d502045462f002c343caa7c0986936
# and
# https://github.com/pester/Pester/commit/c8bc9679bed19c8fbc4229caa01dd083f2d03d4f#diff-460f64eafc16facefbed201eb00fb151c75eadf7cc58a504a01527015fb1c7cdR17
function Assert-BlockString # Should-BeBlockString
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseProcessBlockForPipelineCommand', '')]
    param (
        [Parameter(Position = 1, ValueFromPipeline = $true)]
        $Actual,

        [Parameter(Position = 0, Mandatory = $true)]
        [System.String[]]
        $Expected,

        [Parameter()]
        [System.String]
        $Because,

        [Parameter()]
        [System.String]
        $DifferenceAnsi = '30;31m'
    )

    $hasPipelineInput = $MyInvocation.ExpectingInput

    if ($hasPipelineInput)
    {
        $Actual = @($local:Input)
    }

    # Verify if $Actual is a string or string array
    $isStringType = $Actual -is [System.String] -or ($Actual -is [System.Array] -and $Actual[0] -is [System.String])

    $stringsAreEqual = $isStringType -and (-join $Actual) -eq (-join $Expected)

    if (-not $stringsAreEqual) {
        if (-not $isStringType)
        {
            $message = "Expected to actual value to be of type string or string[], but it was not."
        }
        else
        {
            $message = 'Expect the strings to be equal'

            if ($Because)
            {
                $message += " because $Because"
            }

            $message += ", but they were not. Difference is highlighted:`r`n"

            $message += Out-Diff -Reference $Expected -Difference $Actual -ReferenceLabel 'Expected' -DifferenceLabel 'Actual' -DifferenceAnsi:$DifferenceAnsi -PassThru |
                ForEach-Object { "`e[0m$_`r`n" }
        }

        throw [Pester.Factory]::CreateShouldErrorRecord($Message, $MyInvocation.ScriptName, $MyInvocation.ScriptLineNumber, $MyInvocation.Line.TrimEnd([System.Environment]::NewLine), $true)
    }
}
