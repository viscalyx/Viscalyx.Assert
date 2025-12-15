<#
    .SYNOPSIS
        The localized resource strings in English (en-US). This file should only
        contain localized strings for private functions, public command, and
        classes (that are not a DSC resource).
#>

ConvertFrom-StringData @'
    ## Common localized strings
    # This string is intentionally lower-cased to match the casing of the Pester error message.
    Common_WordBecause = because
    # These strings are intentionally lower-cased.
    Common_WordActual = actual
    Common_WordExpected = expected

    ## New localized strings for Assert-BlockString
    Assert_BlockString_ActualInvalid = The Actual value must be of type string or string[], but it was not.
    Assert_BlockString_ExpectedInvalid = The Expected value must be of type string or string[], but it was not.
    Assert_BlockString_StringsNotEqual = Expected the strings to be equal
    Assert_BlockString_Difference = , but they were not. Difference is highlighted:

    ## New localized strings for Assert-ObjectProperty
    Assert_ObjectProperty_ActualIsNull = Expected the actual value not to be null, but it was null.
    Assert_ObjectProperty_PropertyNotFound = Expected the object to have property '{0}', but the property was not found.
    Assert_ObjectProperty_ValueMismatch = Expected property '{0}' to have value '{1}', but the actual value was '{2}'.
    Assert_ObjectProperty_TypeMismatch = Expected property '{0}' to have type '{1}', but the actual type was '{2}'.

    ## New localized strings for Assert-ObjectMethod
    Assert_ObjectMethod_ActualIsNull = Expected the actual value not to be null, but it was null.
    Assert_ObjectMethod_MethodNotFound = Expected the object to have method '{0}', but the method was not found.

    ## New localized strings for Test-ObjectType
    Test_ObjectType_GetTypeFailed = Failed to get type information for the {0} value. The object may not support the GetType() method. Use the -NoTypeCheck parameter to skip strict type checking. (TOT0001)

    ## New localized strings for Assert-BitwiseFlag
    Assert_BitwiseFlag_InvalidType = Expected parameter {0} to be a bitwise-compatible type (integer or enum), but the type was '{1}'.
    Assert_BitwiseFlag_FlagNotSet = Expected the value to have flag '{0}' set, but it was not set on '{1}'.
    Assert_BitwiseFlag_FlagShouldNotBeSet = Expected the value NOT to have flag '{0}' set, but it was set on '{1}'.
    Assert_BitwiseFlag_NoElementHasFlag = Expected at least one element to have flag '{0}' set, but none of the elements had the flag set.
    Assert_BitwiseFlag_AllElementsHaveFlag = Expected at least one element NOT to have flag '{0}' set, but all elements had the flag set.
'@
