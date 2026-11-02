# GCF MultiQC candidate image

Image: **`gcfntnu/gcf-multiqc:1.35-gcf0.1.0-rc1`** (Linux amd64).

This replaces the reporting engine with upstream MultiQC 1.35 and a separate
`gcf-multiqc==0.1.0rc1` extension. It is a candidate for later GCF acceptance;
publishing it does not change the image selected by the suite.

The Dockerfile pins the Python base digest, plugin commit and source archive
checksum. `requirements.lock` pins runtime and build-backend versions with
wheel hashes. Plotly 6.0.1 is deliberate: MultiQC 1.35's bundled Kaleido 0.2.1
cannot export flat figures with Plotly >=6.1. The lock is specific to Python
3.11/Linux amd64; resolve and test a separate lock before building another
architecture. Source lives in
[gcfntnu/gcf-multiqc](https://github.com/gcfntnu/gcf-multiqc/tree/implementation/upstream-1.35).

The image also installs `procps`, NSS/NSPR, Expat and DejaVu fonts for MultiQC's
flat-report renderer. These Debian packages come from the base distribution's
repositories; the release validation records their installed versions. The
Python wheel lock is not a lock of the Debian package repositories.

The command `multiqc` is on PATH, the existing logo remains at
`/opt/images/logo_ntnu.png`, and no forced entry point interferes with the
suite's Apptainer wrapper. This directory contains only public build inputs.
The allowlist in `.dockerignore` excludes local logs, outputs and private data.

## Build and publish

From this directory:

```bash
docker build --platform linux/amd64 \
  -t gcfntnu/gcf-multiqc:1.35-gcf0.1.0-rc1 \
  -t gcfntnu/gcf-multiqc:latest .
docker run --rm --network none gcfntnu/gcf-multiqc:1.35-gcf0.1.0-rc1 multiqc --version
# Validate reports before publishing; see below.
docker push gcfntnu/gcf-multiqc:1.35-gcf0.1.0-rc1
docker push gcfntnu/gcf-multiqc:latest
```

This follows `build_tag_push_gcfntnu.sh` naming/tagging behavior, while pushing
only the two tags produced by this build. `latest` denotes the latest candidate
in this new repository until a stable release is accepted; use the explicit
version tag or digest for reproducible evaluation. No legacy `gcfntnu/multiqc`
tag is changed.

## Reporting-only validation

Use copied inputs and a new output directory. For example:

```bash
mkdir -p reports
docker run --rm --network none --user "$(id -u):$(id -g)" \
  -v "$PWD/copied-logs:/inputs:ro" -v "$PWD/reports:/output" \
  gcfntnu/gcf-multiqc:1.35-gcf0.1.0-rc1 \
  multiqc --strict --no-version-check --no-ai --no-megaqc-upload \
  -m fastp -m fastqc_rnaseq -m custom_content -o /output /inputs
```

The plugin repository holds synthetic tests for every ported module, all seven
current workflow report profiles, native sequencing-QC parsers and flat-image
export. Run those tests against the built image's installed package, using an
ephemeral test dependency directory, mounted read-only fixtures, no network and
an invocation-owned output directory. Do not copy the test corpus into the image.

No scientific workflow, production configuration or GCF-suite integration test
belongs to this build step. Later acceptance must compare copied real inputs,
verify the server's Apptainer wrapper and separately review the workflow-owned
image-reference change. See the plugin's migration checkpoint for that plan.
