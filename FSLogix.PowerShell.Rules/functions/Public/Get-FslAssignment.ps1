function Get-FslAssignment {
    [CmdletBinding()]

    Param (
        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [System.String]$Path
    )

    BEGIN {
        Set-StrictMode -Version Latest
    } # Begin
    PROCESS {
        if (-not (Test-Path $Path)) {
            Write-Error "$Path not found."
            exit
        }

        #Grab txt file contents apart from first line
        $lines = Get-Content -Path $Path | Select-Object -Skip 1

        foreach ($line in $lines) {

            #If line matches tab separated data with 5 columns.
            if ( $line -match "([^\t]*\t){5}" ) {
                #Create a powershell object from the columns
                $lineObj = $line | ConvertFrom-String -Delimiter `t -PropertyNames FlagsDec, IdString, DistinguishedName, FriendlyName, AssignedTime, UnAssignedTime
                #ConvertFrom-String converts the hex value in flag to decimal, need to convert back to a hex string. Add in the comment and output it.
                $assignment = $lineObj | Select-Object -Property  IdString, DistinguishedName, FriendlyName, AssignedTime, UnAssignedTime, @{n = 'Flags'; e = { '0x' + "{0:X8}" -f $lineObj.FlagsDec } }

                $poshFlags = $assignment.Flags | ConvertFrom-FslAssignmentCode

                if ($poshFlags.PSObject.Properties -contains 'java') {
                    Write-Error 'Please use the cmdlet Get-FslJavaAssignment to get assignments for java files'
                    exit
                }

                $output = [PSCustomObject]@{
                    PSTypeName          = "FSLogix.Assignment"
                    RuleSetApplies      = switch ( $true ) {
                        $poshFlags.Remove { $false }
                        $poshFlags.Apply { $true }
                    }
                    UserName            = if ( $poshFlags.User ) { $assignment.IdString } else { $null }
                    GroupName           = if ( $poshFlags.Group ) { $assignment.FriendlyName } else { $null }
                    ADDistinguisedName  = if ( $poshFlags.Group ) { $assignment.DistinguishedName } else { $null }
                    WellKnownSID        = if ( $poshFlags.Group ) { $assignment.IdString } else { $null }
                    ProcessName         = if ( $poshFlags.Process ) { $assignment.IdString } else { $null }
                    IncludeChildProcess = if ( $poshFlags.Process ) { $poshFlags.ApplyToProcessChildren } else { $null }
                    IPAddress           = if ( $poshFlags.Network ) { $assignment.IdString } else { $null }
                    ComputerName        = if ( $poshFlags.Computer ) { $assignment.IdString } else { $null }
                    OU                  = if ( $poshFlags.ADDistinguishedName ) { $assignment.IdString } else { $null }
                    EnvironmentVariable = if ( $poshFlags.EnvironmentVariable ) { $assignment.IdString } else { $null }
                    AssignedTime        = if ( $poshFlags.EnvironmentVariable ) {
                        if ($assignment.AssignedTime -ne 0) {
                            [DateTime]::FromFileTime($assignment.AssignedTime)
                        }
                        else {
                            0
                        }
                    }
                    else { 0 }
                    UnAssignedTime      = if ( $poshFlags.EnvironmentVariable ) {
                        if ($assignment.UnAssignedTime -ne 0) {
                            [DateTime]::FromFileTime($assignment.UnAssignedTime)
                        }
                        else {
                            0
                        }
                    }
                    else { 0 }
                }

                Write-Output $output
            } #if
        } #foreach
    } #Process
    END { } #End
}  #function Get-FslAssignment