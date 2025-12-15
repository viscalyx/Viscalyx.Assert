<#
    .SYNOPSIS
        Processes pipeline input for assertion commands.

    .DESCRIPTION
        The `Get-ProcessedPipelineInput` function collects pipeline input and
        handles single-element array unwrapping when the -Each parameter is not
        specified. This is used by assertion commands to normalize pipeline input.

    .PARAMETER InvocationInfo
        The invocation info from the calling command, used to check if pipeline
        input is expected.

    .PARAMETER Each
        When specified, prevents unwrapping of single-element arrays.

    .INPUTS
        System.Object

        Accepts any object via the pipeline.

    .OUTPUTS
        System.Object

        Returns the processed pipeline input.

    .EXAMPLE
        $result = Get-ProcessedPipelineInput -InvocationInfo $MyInvocation -Each

        Processes pipeline input without unwrapping single-element arrays.
#>
function Get-ProcessedPipelineInput
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.InvocationInfo]
        $InvocationInfo,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Each
    )

    $hasPipelineInput = $InvocationInfo.ExpectingInput

    if ($hasPipelineInput)
    {
        $result = @($local:Input)

        # If there's no pipeline input collected (already bound to parameter), return null
        if ($result.Count -eq 0)
        {
            return $null
        }

        # If we're not using -Each and we have a single-element array, unwrap it
        if (-not $Each.IsPresent -and $result.Count -eq 1)
        {
            $result = $result[0]
        }

        return $result
    }

    return $null
}
