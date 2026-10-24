param(
    [Parameter(Mandatory = $true)]
    [string]$Module
)

$ErrorActionPreference = "Stop"

if (Test-Path ".\mvnw.cmd") {
    & .\mvnw.cmd -pl $Module -am test "-DskipITs"
} elseif (Get-Command mvn -ErrorAction SilentlyContinue) {
    & mvn -pl $Module -am test "-DskipITs"
} else {
    Write-Error "Neither .\mvnw.cmd nor mvn was found."
}
