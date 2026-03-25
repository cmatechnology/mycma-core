Function Hello-World {
    param(
        [String] $Name,
        [String] $Version
    )
    $msg = "Splat Test Name: $Name Version $Version Main Branch"
    Write-Host $msg
    return $msg
    
}


