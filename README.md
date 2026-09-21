## Attach Assets to Release

This composite GitHub Action attaches one or more files to an existing GitHub
release. It uses the GitHub CLI to upload release assets.

### Calling the action

```yaml
name: Attach release assets

on:
  push:
    branches:
      - main

permissions:
  contents: write

jobs:
  attach-assets:
    runs-on: ubuntu-latest
    steps:
      - name: Attach assets to release
        uses: glueckkanja/action-attach-assets-to-release@sha-ref # v0.0.0
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          release_id: 1234567
          asset_path: ./release-assets-file-or-dir
```

### Permissions

- contents: write -> so that it is possible to upload release files

### Inputs

- `github_token` _(string, required)_ – GitHub token with write access to repository contents and releases
- `release_id` _(string, required)_ – ID of the existing release to which assets are uploaded. Usually provided by the previous versioning action.
- `asset_path` _(string, required)_ – Path to one file or a directory containing files to attach
- `publish_draft_release` _(string, optional, default `"false"`)_ – If set to `"true"` and the release is a draft, the release is published (draft flag removed) after the assets have been uploaded

### Supported Content Types

The action selects the upload content type from the file extension:

| Extension | Content type                                    |
| --------- | ----------------------------------------------- |
| `.zip`    | `application/zip`                               |
| `.tar`    | `application/x-tar`                             |
| `.gz`     | `application/gzip`                              |
| `.txt`    | `text/plain`                                    |
| `.json`   | `application/json`                              |
| `.exe`    | `application/vnd.microsoft.portable-executable` |

All other extensions use `application/octet-stream`.

### Duplicate and Upload Errors

If an asset with the same name already exists on the release, the action emits
a warning and skips that asset. Other upload failures also produce warnings,
the script continues processing the remaining files.
