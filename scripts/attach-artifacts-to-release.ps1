if ([string]::IsNullOrWhiteSpace($env:RELEASE_ID)) {
    throw 'Release ID must be provided.'
}

$ArtifactPathItem = Get-Item -Path $env:ARTIFACT_PATH.Trim() -ErrorAction SilentlyContinue
if (-not $ArtifactPathItem) {
    throw "No file or directory found at artifact path '$env:ARTIFACT_PATH'."
}

# check if the artifact path is a directory or a single file
if ($ArtifactPathItem.PSIsContainer) {
    $ResolvedArtifactPaths = @(Get-ChildItem -Path $ArtifactPathItem.FullName -File | Select-Object -ExpandProperty FullName)
}
else {
    $ResolvedArtifactPaths = @($ArtifactPathItem.FullName)
}

$ContentTypesByFileExtension = @{
    '.zip'  = 'application/zip'
    '.tar'  = 'application/x-tar'
    '.gz'   = 'application/gzip'
    '.txt'  = 'text/plain'
    '.json' = 'application/json'
    '.exe'  = 'application/vnd.microsoft.portable-executable'
}

foreach ($Artifact in $ResolvedArtifactPaths) {
    $ArtifactName = Split-Path -Path $Artifact -Leaf
    $EncodedArtifactName = [uri]::EscapeDataString($ArtifactName)
    $ArtifactFileExtension = [System.IO.Path]::GetExtension($ArtifactName).ToLowerInvariant()
    $ArtifactContentType = $ContentTypesByFileExtension[$ArtifactFileExtension]

    if (-not $ArtifactContentType) {
        $ArtifactContentType = 'application/octet-stream'
    }

    $UploadApiPath = "https://uploads.github.com/repos/$env:GITHUB_REPOSITORY/releases/$env:RELEASE_ID/assets?name=$EncodedArtifactName"
    $UploadResponse = gh api --method POST $UploadApiPath --header "Content-Type: $ArtifactContentType" --input $Artifact 2>&1

    if ($LASTEXITCODE -ne 0) {
        $UploadResponseText = $UploadResponse | Out-String

        if ($UploadResponseText -match 'already_exists') {
            Write-Host "::warning::Release asset '$ArtifactName' already exists on release '$env:RELEASE_ID'. Skipping."
            continue
        }

        Write-Host "::warning::Failed to upload release asset '$ArtifactName' to release '$env:RELEASE_ID'. GitHub response: $UploadResponseText"
    }
}
