if ([string]::IsNullOrWhiteSpace($env:RELEASE_ID)) {
    throw 'Release ID must be provided.'
}

$ReleaseInfoJson = gh api "repos/$env:GITHUB_REPOSITORY/releases/$env:RELEASE_ID" | ConvertFrom-Json
$IsDraftRelease = $ReleaseInfoJson.draft
$IsImmutableRelease = $ReleaseInfoJson.immutable

if (-not $IsDraftRelease -and $IsImmutableRelease) {
    throw "Release '$env:RELEASE_ID' is published and immutable. Assets cannot be attached to it."
}

$AssetPathItem = Get-Item -Path $env:ASSET_PATH.Trim() -ErrorAction SilentlyContinue
if (-not $AssetPathItem) {
    throw "No file or directory found at asset path '$env:ASSET_PATH'."
}

# Check if the asset path is a directory or a single file.
if ($AssetPathItem.PSIsContainer) {
    $ResolvedAssetPaths = @(Get-ChildItem -Path $AssetPathItem.FullName -File | Select-Object -ExpandProperty FullName)
}
else {
    $ResolvedAssetPaths = @($AssetPathItem.FullName)
}

$ContentTypesByFileExtension = @{
    '.zip'  = 'application/zip'
    '.tar'  = 'application/x-tar'
    '.gz'   = 'application/gzip'
    '.txt'  = 'text/plain'
    '.json' = 'application/json'
    '.exe'  = 'application/vnd.microsoft.portable-executable'
}

foreach ($Asset in $ResolvedAssetPaths) {
    $AssetName = Split-Path -Path $Asset -Leaf
    $EncodedAssetName = [uri]::EscapeDataString($AssetName)
    $AssetFileExtension = [System.IO.Path]::GetExtension($AssetName).ToLowerInvariant()
    $AssetContentType = $ContentTypesByFileExtension[$AssetFileExtension]

    if (-not $AssetContentType) {
        $AssetContentType = 'application/octet-stream'
    }

    $UploadApiPath = "https://uploads.github.com/repos/$env:GITHUB_REPOSITORY/releases/$env:RELEASE_ID/assets?name=$EncodedAssetName"
    $UploadResponse = gh api --method POST $UploadApiPath --header "Content-Type: $AssetContentType" --input $Asset 2>&1

    if ($LASTEXITCODE -ne 0) {
        $UploadResponseText = $UploadResponse | Out-String

        if ($UploadResponseText -match 'already_exists') {
            Write-Host "::warning::Release asset '$AssetName' already exists on release '$env:RELEASE_ID'. Skipping."
            continue
        }

        throw "Failed to upload release asset '$AssetName' to release '$env:RELEASE_ID'. GitHub response: $UploadResponseText"
    }
}
