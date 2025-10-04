<#
    .SYNOPSIS
        Asserts that an object contains a specified property.

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

    .PARAMETER Each
        When specified and the input is an array, asserts that each element in
        the array has the specified property (and optionally the specified value).
        Without this parameter, the assertion checks the array object itself.

    .PARAMETER NoTypeCheck
        When specified, allows PowerShell type coercion when comparing values
        (e.g., allows 123 to equal '123'). By default, value comparisons use
        strict type checking where types must match exactly. This parameter
        only applies when using the Value parameter.

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

    .EXAMPLE
        PS> $arrayOfObjects | Assert-ObjectProperty -Property 'Name' -Each

        This example asserts that each object in the piped array has a property
        named 'Name'. The `-Each` parameter enables element-by-element checking.

    .EXAMPLE
        Assert-ObjectProperty -Actual $myObject -Property 'Value' -Value 123 -NoTypeCheck

        This example uses lenient type checking, so if the Value property contains
        the string '123', it will be considered equal to the number 123.
#>
function Assert-ObjectProperty
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples are syntactically correct. The rule does not seem to understand that there is pipeline input.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseProcessBlockForPipelineCommand', '')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '')]
    [CmdletBinding(DefaultParameterSetName = 'AssertProperty')]
    [Alias('Should-HaveProperty')]
    [OutputType()]
    param
    (
        [Parameter(ParameterSetName = 'AssertProperty', Position = 0, Mandatory = $true)]
        [Parameter(ParameterSetName = 'AssertValue', Position = 0, Mandatory = $true)]
        [System.String]
        $Property,

        [Parameter(ParameterSetName = 'AssertProperty', Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'AssertValue', Position = 2, Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Actual,

        [Parameter(ParameterSetName = 'AssertValue', Position = 1, Mandatory = $true)]
        [AllowNull()]
        [System.Object]
        $Value,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Because,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Each,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NoTypeCheck
    )

    $hasPipelineInput = $MyInvocation.ExpectingInput

    if ($hasPipelineInput)
    {
        $Actual = @($local:Input)

        # If we're not using -Each and we have a single-element array, unwrap it
        # This handles the case where a single hashtable or object is piped
        if (-not $Each.IsPresent -and $Actual.Count -eq 1)
        {
            $Actual = $Actual[0]
        }
    }

    # If Each is specified and we have an array, iterate through each element
    if ($Each.IsPresent -and $hasPipelineInput -and $Actual -is [System.Array] -and $Actual.Count -gt 0)
    {
        foreach ($currentObject in $Actual)
        {
            # Check if the current object is null
            if ($null -eq $currentObject)
            {
                $message = $script:localizedData.Assert_ObjectProperty_ActualIsNull
                throw (New-AssertionError -Message $message -Because $Because -InvocationInfo $MyInvocation)
            }

            # Check if the property exists on the current object
            $hasProperty = Test-ObjectHasProperty -InputObject $currentObject -PropertyName $Property

            if (-not $hasProperty)
            {
                $message = $script:localizedData.Assert_ObjectProperty_PropertyNotFound -f $Property
                throw (New-AssertionError -Message $message -Because $Because -InvocationInfo $MyInvocation)
            }

            # If we're in the AssertValue parameter set, also check the value
            if ($PSCmdlet.ParameterSetName -eq 'AssertValue')
            {
                $actualValue = $currentObject.$Property

                # Check type compatibility first (unless NoTypeCheck is specified)
                if (-not $NoTypeCheck.IsPresent)
                {
                    $typesMatch = Test-ObjectType -ActualValue $actualValue -ExpectedValue $Value

                    if (-not $typesMatch)
                    {
                        $actualType = Get-TypeName -Value $actualValue
                        $expectedType = Get-TypeName -Value $Value
                        $message = $script:localizedData.Assert_ObjectProperty_TypeMismatch -f $Property, $expectedType, $actualType
                        throw (New-AssertionError -Message $message -Because $Because -InvocationInfo $MyInvocation)
                    }
                }

                # Then check value equality
                $valuesAreEqual = Test-ValueEquality -ActualValue $actualValue -ExpectedValue $Value

                if (-not $valuesAreEqual)
                {
                    $message = $script:localizedData.Assert_ObjectProperty_ValueMismatch -f $Property, $Value, $actualValue
                    throw (New-AssertionError -Message $message -Because $Because -InvocationInfo $MyInvocation)
                }
            }
        }
    }
    else
    {
        # Single object case (not an array or empty array)
        # Check if the actual value is null
        if ($null -eq $Actual)
        {
            $message = $script:localizedData.Assert_ObjectProperty_ActualIsNull
            throw (New-AssertionError -Message $message -Because $Because -InvocationInfo $MyInvocation)
        }

        # Check if the property exists on the object
        $hasProperty = Test-ObjectHasProperty -InputObject $Actual -PropertyName $Property

        if (-not $hasProperty)
        {
            $message = $script:localizedData.Assert_ObjectProperty_PropertyNotFound -f $Property
            throw (New-AssertionError -Message $message -Because $Because -InvocationInfo $MyInvocation)
        }

        # If we're in the AssertValue parameter set, also check the value
        if ($PSCmdlet.ParameterSetName -eq 'AssertValue')
        {
            $actualValue = $Actual.$Property

            # Check type compatibility first (unless NoTypeCheck is specified)
            if (-not $NoTypeCheck.IsPresent)
            {
                $typesMatch = Test-ObjectType -ActualValue $actualValue -ExpectedValue $Value

                if (-not $typesMatch)
                {
                    $actualType = Get-TypeName -Value $actualValue
                    $expectedType = Get-TypeName -Value $Value
                    $message = $script:localizedData.Assert_ObjectProperty_TypeMismatch -f $Property, $expectedType, $actualType
                    throw (New-AssertionError -Message $message -Because $Because -InvocationInfo $MyInvocation)
                }
            }

            # Then check value equality
            $valuesAreEqual = Test-ValueEquality -ActualValue $actualValue -ExpectedValue $Value

            if (-not $valuesAreEqual)
            {
                $message = $script:localizedData.Assert_ObjectProperty_ValueMismatch -f $Property, $Value, $actualValue
                throw (New-AssertionError -Message $message -Because $Because -InvocationInfo $MyInvocation)
            }
        }
    }
}
