# MultiQC issue-7 candidate validation

9 November 2026. This candidate packages
[gcf-multiqc PR 8](https://github.com/gcfntnu/gcf-multiqc/pull/8), which hides the
GCF fastp overrepresented-sequence chart and top-sequences table. The local
reporting-only replay below passed. Historical rc4 operational acceptance does
not establish wider operational acceptance of this candidate.

## Artifact

| Item | Value |
| --- | --- |
| Candidate tag | `gcfntnu/gcf-multiqc:1.35-gcf0.1.0-rc4-issue7` |
| Registry digest | `sha256:d6acc3ebe9eb23323cfd37ef730c988f0ae2c0d51d7629b04ebe7bbd614778ab` |
| Tested image ID | `sha256:f4152429ca0d016a1e695fddcaebcd1229162169b420b2ee3b23cb8e5168eecc` |
| Platform | Linux amd64 |
| Plugin source | `90d3e253f2f837c6779b3c77aa5422f5a9bae117` |
| Source archive SHA256 | `e3301c982dd7a86f6cdefee52d53106739d82c4a6f2c93e5b2245ca5a2bff630` |
| Engine / extension / Plotly | MultiQC 1.35 / gcf-multiqc 0.1.0rc4 / Plotly 6.0.1 |
| Python | 3.11.18 |
| Image-recipe base | `1cb352e6d910ad0bcb0e50aca17aaa6b83715c00` (`master`) |

The Python base digest and `requirements.lock` are unchanged. The installed
runtime source differs from the previous rc4 source only in the GCF fastp
adapter. Its installed file SHA256 is
`0fdaa9f7f8959677ce7f534662ea413462a7145319c0004490779a917f3d3c5d`,
matching the reviewed plugin source. No source checkout was mounted on the
image's import path during testing.

## Checks performed

- Built locally with `docker build --platform linux/amd64 --progress=plain -t
  gcfntnu/gcf-multiqc:1.35-gcf0.1.0-rc4-issue7 gcf-multiqc` from the recipe
  repository root. The source archive checksum was enforced by BuildKit.
- `python -m pip check` passed inside the built image. Installed engine, plugin,
  Plotly, adapter path/hash and OCI source/version labels were verified.
- All **123 plugin reporting tests passed inside the built image** in 137.54 s.
  Tests ran as a non-root user, with no network, a read-only container filesystem,
  read-only synthetic fixtures and writable invocation-owned results and `/tmp`.
  The image's installed plugin and runtime dependencies supplied reporting code.
- Test-only pytest 8.4.2, pluggy 1.6.0 and iniconfig 2.1.0 were mounted externally;
  they are not installed in or published with the image. Runtime dependencies
  from the image lock were not replaced.
- The suite includes the seven public workflow report profiles, real flat-image
  rendering, and all four GCF/native overrepresentation visibility cases. Other
  fastp plots, raw motif counts, FastQC sections and source-input bytes remain
  covered by the regression checks.
- `git diff --check` passed. Build logs, installed-package inventory and test
  outputs remain in the checkout's ignored `.dev/` directory, outside the image
  build context. This record contains no operational inputs or project evidence.

The image was published only under its new candidate tag. Existing release tags
and `latest` were not changed. A rebuild needs a distinct tag and a new receipt;
the tested artifact is identified by the registry digest above.

## Handoff

This work is tracked in [gcf-docker issue 34](https://github.com/gcfntnu/gcf-docker/issues/34).
[gcf-workflows issue 318](https://github.com/gcfntnu/gcf-workflows/issues/318)
coordinates an isolated branch selecting this digest in `docker.config`.
After manual acceptance, merge the plugin, image-recipe and workflow-selection
PRs in that order. Production promotion and deployment remain separate steps.

Manual acceptance can render copied project QC logs into a new output directory
and review the retained QC sections, statistics and raw exports. The local replay
below completed this reporting-only check on existing output.
No scientific workflow execution, production configuration change or operational
report regeneration was performed as part of these image checks.

## Local existing-output replay

The published candidate was exercised locally on copied existing QC outputs,
using the original report configuration and module selection, with strict error
checking and interactive charts. The image ran as non-root with no network,
read-only inputs/root filesystem and separate local output and cache directories.
BFQ and scientific workflows were not started.

SHA-256 verified the input copy and confirmed its bytes remained unchanged after
rendering. All retained General Statistics values/headers, raw module exports
and serialized plot models match the original delivered report exactly. The
only removed plot models are `fastp_overrepresented_sequences_plot` and
`fastp_top_overrepresented_sequences_table`. Fastp raw records and FastQC read
counts were additionally checked directly against the copied producer inputs.

Offline Chrome rendered the retained charts and exercised the fastp R1/R2
before/after filtering tabs. It reported no JavaScript errors, console errors,
failed requests or broken images. Fastp's two displays and navigation links
are absent; the FastQC overrepresentation sections remain available.

This reporting-only replay passed. It does not exercise BFQ orchestration or
the server's Apptainer wrapper. Original server output remains untouched; inputs,
generated reports, screenshots and detailed evidence remain private.
