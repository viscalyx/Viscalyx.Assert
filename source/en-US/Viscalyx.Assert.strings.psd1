<#
    .SYNOPSIS
        The localized resource strings in English (en-US). This file should only
        contain localized strings for private functions, public command, and
        classes (that are not a DSC resource).
#>

ConvertFrom-StringData @'
    ## New localized strings for Assert-BlockString
    Assert_BlockString_ActualInvalid = The Actual value must be of type string or string[], but it was not.
    Assert_BlockString_ExpectedInvalid = The Expected value must be of type string or string[], but it was not.
    Assert_BlockString_StringsNotEqual = Expected the strings to be equal
    # This string is intentionally lower-cased to match the casing of the Pester error message.
    Assert_BlockString_StringsNotEqual_Because = because
    Assert_BlockString_Difference = , but they were not. Difference is highlighted:
'@
