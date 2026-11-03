# GCF MultiQC candidate image

Image: **`gcfntnu/gcf-multiqc:1.35-gcf0.1.0-rc4`** (Linux amd64).

This replaces the reporting engine with upstream MultiQC 1.35 and a separate
`gcf-multiqc==0.1.0rc4` extension. The published candidate is identified by
`sha256:2c356684c03d24c11e63be5724d4f107c253eccd8be98c236952bd3df5435878`.
The proposed suite adoption selects that digest through the existing
`gcf-workflows/docker.config` mapping; publishing an image alone does not switch
either BFQ or project reporting to it. See [the adoption handoff](ADOPTION.md)
and [the rc4 validation record](VALIDATION-RC4.md).

Fresh seven-fixture integration acceptance passed, including all eight project
and seven sequencing reports. See the validation record for source checks,
classified legacy differences and coverage bounds.

The rc4 candidate preserves literal General Statistics text and sums BCL Convert
sample/lane metrics across multiple index rows. These defects were found during
functional comparisons with copied reference inputs. The candidate also retains
both FastQC paired mates and uses consistent lane labels across combined runs.

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

## Build for evaluation

To evaluate another local rebuild, use a
new local tag so rebuilding cannot overwrite the published candidate:

```bash
docker build --platform linux/amd64 \
  -t gcf-multiqc:review-1 .
docker run --rm --network none gcf-multiqc:review-1 multiqc --version
docker image inspect gcf-multiqc:review-1 \
  --format '{{.Id}} {{index .Config.Labels "org.opencontainers.image.revision"}}'
```

The already-published artifact can be evaluated without rebuilding. A new local
build is a separate artifact: Debian package repositories are not frozen, so
it need not reproduce the published digest. Record which artifact was tested.
The workflow PR continues to select the published digest until a separately
reviewed update selects another accepted image.

Publication is a later deliberate step. Choose a new release tag, keep package
and image version labels consistent, and record the registry digest before
updating the workflow mapping. The existing `build_tag_push_gcfntnu.sh` convention
builds the supplied tag plus `latest` and immediately pushes them; do not use it
for a build-only review. Do not overwrite published release tags. `latest` is not
the suite's proposed selection, and the old `gcfntnu/multiqc` image remains
available for rollback.

## Reporting-only validation

Use copied inputs and a new output directory. For example:

```bash
mkdir -p reports
docker run --rm --network none --user "$(id -u):$(id -g)" \
  -v "$PWD/copied-logs:/inputs:ro" -v "$PWD/reports:/output" \
  gcfntnu/gcf-multiqc:1.35-gcf0.1.0-rc4 \
  multiqc --strict --no-version-check --no-ai --no-megaqc-upload \
  -m fastp -m fastqc_rnaseq -m custom_content -o /output /inputs
```

The plugin repository holds synthetic tests for the ported modules, all seven
historical workflow report profiles, native sequencing-QC parsers and flat-image
export. Run those tests against the built image's installed package, using an
ephemeral test dependency directory, mounted read-only fixtures, no network and
an invocation-owned output directory. A read-only container also needs a private
writable `/tmp` mount for the bundled flat-image renderer. Do not copy the test corpus into the image.

The active acceptance set includes Parse and the current report families.
QIIME2 and legacy Cell Ranger mkfastq are deprecated for acceptance; STARsolo has
low priority. Their existing adapters remain installed for compatibility.

No scientific workflow, production configuration or GCF-suite integration test
belongs to the image build step. Later acceptance must compare the same copied
inputs and configuration with both engines, verify the server's Apptainer
wrapper, and review the suite adoption before merging or deployment. Existing
reports and reduced input examples from different datasets are not a matched
comparison pair. Keep private inputs, reports and evidence outside Git and image
build contexts.
