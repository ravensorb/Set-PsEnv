<#
.SYNOPSIS
Exports environment variable from the .env file to the current process.

.DESCRIPTION
This function looks for .env file in the current directoty, if present
it loads the environment variable mentioned in the file to the current process.

.PARAMETER envFile
The full path to an env file (defaults to .\.env)

.EXAMPLE
#.env file format
#To Assign value, use "=" operator
<variable name>=<value>
#To Prefix value to an existing env variable, use ":=" operator
<variable name>:=<value>
#To Suffix value to an existing env variable, use "=:" operator
<variable name>=:<value>
#To comment a line, use "#" at the start of the line
#This is a comment, it will be skipped when parsing
#Assign variable values with their variable name enclosed in curly braces ({}) and prefixed with a dollar-sign ($)
<variable name>=${<variable name>} # add previously declared variables from the current .env file or process

.EXAMPLE
 # This is function is called by convention in PowerShell
 # Auto exports the env variable at every prompt change
 function prompt {
    Set-PsEnv
 }
#>
function Set-PsEnv {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param(
        [string] $envFile = '.\.env'
    )


    #return if no env file
    if (!( Test-Path $envFile)) {
        Write-Verbose 'No .env file'
        return
    }

    #read the local env file
    $content = Get-Content $envFile -ErrorAction Stop
    Write-Verbose 'Parsed .env file'

    #load the content to environment
    foreach ($line in $content) {

        if ([string]::IsNullOrWhiteSpace($line)) {
            Write-Verbose 'Skipping empty line'
            continue
        }

        #ignore comments
        if ($line.StartsWith('#')) {
            Write-Verbose "Skipping comment: $line"
            continue
        }

        #check to see if line has an embedded comment and if so remove it
        if ($line -like '*#*') {
            $line = ($line -split '#')[0].Tim()
        }

        #get the operator
        if ($line -like '*:=*') {
            Write-Verbose 'Prefix'
            $kvp = $line -split ':=', 2
            $key = $kvp[0].Trim()
            $value = '{0};{1}' -f (Get-PsEnv $kvp[1].Trim()), [System.Environment]::GetEnvironmentVariable($key)
        }
        elseif ($line -like '*=:*') {
            Write-Verbose 'Suffix'
            $kvp = $line -split '=:', 2
            $key = $kvp[0].Trim()
            $value = '{1};{0}' -f (Get-PsEnv $kvp[1].Trim()), [System.Environment]::GetEnvironmentVariable($key)
        }
        elseif ($line -like '*=*') {
            Write-Verbose 'Assign'
            $kvp = $line -split '=', 2
            $key = $kvp[0].Trim()
            $value = Get-PsEnv $kvp[1].Trim()
        }
        else {
            Write-Verbose 'No operator: skipping'
            continue
        }


        Write-Verbose "$key=$value"


        if ($PSCmdlet.ShouldProcess("environment variable $key", "set value $value")) {
            [Environment]::SetEnvironmentVariable($key, $value, 'Process') | Out-Null
        }
    }
}


<#
.SYNOPSIS
get environment variable from the current process

.DESCRIPTION
retrieve the value of the environment variable from the current process.
It will parse strings enclosed in curly braces ({}) and prefixed with a dollar-sign ($), if needed.
If the variable is not set or found, it will return an empty string

.PARAMETER value
The name of the environment variable to retrieve

.EXAMPLE
Get-PsEnv PSModulePath

.EXAMPLE
Get-PsEnv ${PSModulePath}

.NOTES
General notes
#>
function Get-PsEnv {
    param (
        [string]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [AllowEmptyString()]
        [AllowNull()]
        $value
    )

    # search for ${EnvVarName} in the string
    while ($value -match '\${(?<EnvVarName>[^}]*)}') {
        Write-Verbose "Replacing $($Matches[0])"
        # replace ${EnvVarName} with the value of the environment variable
        $value = $value.Replace($Matches[0], [Environment]::GetEnvironmentVariable($Matches.EnvVarName))
    }
    return $value
}

Export-ModuleMember -Function @('Set-PsEnv')