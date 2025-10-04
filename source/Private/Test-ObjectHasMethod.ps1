<#
    .SYNOPSIS
        Tests whether an object has a specified method.

    .DESCRIPTION
        The `Test-ObjectHasMethod` function checks if the given object contains
        a method with the specified name. This function supports various object
        types including PSCustomObjects and .NET objects.

    .PARAMETER InputObject
        The object to test for the method.

    .PARAMETER MethodName
        The name of the method to check for.

    .INPUTS
        None. This function does not accept pipeline input.

    .OUTPUTS
        System.Boolean

        Returns $true if the method exists, $false otherwise.

    .EXAMPLE
        Test-ObjectHasMethod -InputObject $myObject -MethodName 'ToString'

        Returns $true if $myObject has a method named 'ToString', otherwise $false.
#>
function Test-ObjectHasMethod
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
        $MethodName
    )

    $hasMethod = $false

    try
    {
        # Use Get-Member to check for method existence
        $member = $InputObject | Get-Member -Name $MethodName -MemberType Method, ScriptMethod -ErrorAction SilentlyContinue
        if ($null -ne $member)
        {
            $hasMethod = $true
        }
        else
        {
            # For dynamic objects and PSCustomObject, also check PSObject.Methods
            $methodMember = $InputObject.PSObject.Methods[$MethodName]
            if ($null -ne $methodMember)
            {
                $hasMethod = $true
            }
            else
            {
                # Final check: try to get the method directly for edge cases
                try
                {
                    $methodInfo = $InputObject.GetType().GetMethod($MethodName)
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

    return $hasMethod
}
