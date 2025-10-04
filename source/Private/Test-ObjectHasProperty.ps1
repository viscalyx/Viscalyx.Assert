<#
    .SYNOPSIS
        Tests whether an object has a specified property.

    .DESCRIPTION
        The `Test-ObjectHasProperty` function checks if the given object contains
        a property with the specified name. This function supports various object
        types including hashtables, PSCustomObjects, and .NET objects.

    .PARAMETER InputObject
        The object to test for the property.

    .PARAMETER PropertyName
        The name of the property to check for.

    .OUTPUTS
        System.Boolean

        Returns $true if the property exists, $false otherwise.

    .EXAMPLE
        Test-ObjectHasProperty -InputObject $myObject -PropertyName 'Name'

        Returns $true if $myObject has a property named 'Name', otherwise $false.
#>
function Test-ObjectHasProperty
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $InputObject,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PropertyName
    )

    $hasProperty = $false

    try
    {
        # For hashtables, check if the key exists
        if ($InputObject -is [System.Collections.IDictionary])
        {
            $hasProperty = $InputObject.ContainsKey($PropertyName)
        }
        # For PSCustomObject and other objects, try PSObject.Properties first
        elseif ($null -ne $InputObject.PSObject.Properties[$PropertyName])
        {
            $hasProperty = $true
        }
        # Use Get-Member as fallback for .NET objects
        else
        {
            $member = $InputObject | Get-Member -Name $PropertyName -MemberType Property, NoteProperty, ScriptProperty -ErrorAction SilentlyContinue
            if ($null -ne $member)
            {
                $hasProperty = $true
            }
            else
            {
                # Final check with direct property access for edge cases
                try
                {
                    $null = $InputObject.$PropertyName
                    # If we got here without exception, the property exists
                    # But we need to make sure it's not just returning $null for non-existent properties
                    $actualMember = $InputObject.PSObject.Members | Where-Object { $_.Name -eq $PropertyName }
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

    return $hasProperty
}
