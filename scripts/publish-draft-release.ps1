if ([string]::IsNullOrWhiteSpace($env:RELEASE_ID)) {
    throw 'Release ID must be provided.'
}

$ReleaseInfoJson = gh api "repos/$env:GITHUB_REPOSITORY/releases/$env:RELEASE_ID" | ConvertFrom-Json
$IsDraftRelease = $ReleaseInfoJson.draft

if (-not $IsDraftRelease) {
    throw "Release was already published. It is not possible to publish it again."
}

gh api --method PATCH "repos/$env:GITHUB_REPOSITORY/releases/$env:RELEASE_ID" --field 'draft=false' | Out-Null
Write-Host "Published draft release '$env:RELEASE_ID'."
