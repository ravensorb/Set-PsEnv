<#
.Synopsis
Exports environment variable from the .env file to the current process.

.Description
This function looks for .env file in the current directoty, if present
it loads the environment variable mentioned in the file to the current process.

.Parameter
envFile  The full path to an env file (defaults to .\.env)

.Example
 Set-PsEnv
 
 .Example
 Set-PsEnv -envFile .env.staging
 
 .Example
 #.env file format
 #To Assign value, use "=" operator
 <variable name>=<value>
 #To Prefix value to an existing env variable, use ":=" operator
 <variable name>:=<value>
 #To Suffix value to an existing env variable, use "=:" operator
 <variable name>=:<value>
 #To comment a line, use "#" at the start of the line
 #This is a comment, it will be skipped when parsing

.Example
 # This is function is called by convention in PowerShell
 # Auto exports the env variable at every prompt change
 function prompt {
     Set-PsEnv
 }
#>
function Set-PsEnv {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param(
       [string] $envFile = ".\.env"
    )

    #return if no env file
    if (!( Test-Path $envFile)) {
        Write-Verbose "No .env file"
        return
    }

    #read the local env file
    $content = Get-Content $envFile -ErrorAction Stop
    Write-Verbose "Parsed .env file"

    #load the content to environment
    foreach ($line in $content) {

        if([string]::IsNullOrWhiteSpace($line)){
            Write-Verbose "Skipping empty line"
            continue
        }

        #ignore comments
        if($line.StartsWith("#")){
            Write-Verbose "Skipping comment: $line"
            continue
        }

        #check to see if line has an embedded comment and if so remove it
        if ($line -like "*#*"){
            $line = ($line -split "#")[0].Tim()
        }

        #get the operator
        if($line -like "*:=*"){
            Write-Verbose "Prefix"
            $kvp = $line -split ":=",2            
            $key = $kvp[0].Trim()
            $value = "{0};{1}" -f  $kvp[1].Trim(),[System.Environment]::GetEnvironmentVariable($key)
        }
        elseif ($line -like "*=:*"){
            Write-Verbose "Suffix"
            $kvp = $line -split "=:",2            
            $key = $kvp[0].Trim()
            $value = "{1};{0}" -f  $kvp[1].Trim(),[System.Environment]::GetEnvironmentVariable($key)
        }
        else {
            Write-Verbose "Assign"
            $kvp = $line -split "=",2            
            $key = $kvp[0].Trim()
            $value = $kvp[1].Trim()
        }
        
        Write-Verbose "$key=$value"
        
        if ($PSCmdlet.ShouldProcess("environment variable $key", "set value $value")) {            
            [Environment]::SetEnvironmentVariable($key, $value, "Process") | Out-Null
        }
    }
}

Export-ModuleMember -Function @('Set-PsEnv')
