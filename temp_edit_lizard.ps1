Write-Host 'start'
$path = 'scripts/enemies/lizard.gd'
$content = Get-Content $path -Raw
Write-Host ($content.Length)
