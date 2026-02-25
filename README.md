# mozjpeg-binaries

Prebuilt **mozjpeg** binaries for convenient installation and CI usage.

## What is this?

This repository publishes compiled builds of [mozjpeg](https://github.com/mozilla/mozjpeg), a JPEG encoder/decoder focused on producing smaller files at similar visual quality.

Use these binaries if you want to:
- avoid building mozjpeg from source locally,
- use mozjpeg in CI quickly,
- pin a known-good mozjpeg version for reproducible builds.

## Installation / Download

Binaries are provided via **GitHub Releases**.

1. Go to the Releases page:
   - `https://github.com/qdraw/mozjpeg-binaries/releases`
2. Download the archive for your platform.
3. Extract it and add the `bin/` directory to your `PATH` (or call the executables directly).

## Included tools

Typical mozjpeg builds include some or all of these:

- `cjpeg` – compress images into JPEG; is called mozjpeg in this output

Exact contents may vary by platform and release artifact.

## Basic usage

### Encode (compress) an image
```sh
mozjpeg -quality 80 -outfile output.jpg input.png
```

### Create a progressive JPEG
```sh
mozjpeg -quality 80 -progressive -outfile output.jpg input.png
```

## Versioning

Releases are tagged to track the upstream mozjpeg version (and may include a build/revision suffix when needed), for example:

- `v4.1.5`
- `v4.1.5-1` (repo build revision)

See the release notes for the upstream commit/tag and build details.

## Supported platforms

Document what you ship here (examples):
- Linux x86_64 / aarch64
- macOS x86_64 / arm64
- Windows x86_64

If you tell me what artifacts you actually publish, I’ll fill this section precisely.

## Verification

Each release may include checksums (e.g., `SHA256SUMS`) to verify downloads.

Example:
```sh
sha256sum -c SHA256SUMS
```

## License

mozjpeg is licensed upstream; see:
- upstream project: https://github.com/mozilla/mozjpeg
- license files in the upstream repository and/or in the release artifacts for details

This repository’s packaging/build scripts (if any) are licensed as indicated in this repo.

## Contributing

Issues and PRs are welcome:
- report broken links/artifacts
- request additional platforms/architectures
- suggest improvements to build/release automation (if applicable)

## Acknowledgements

- mozjpeg by Mozilla: https://github.com/mozilla/mozjpeg
