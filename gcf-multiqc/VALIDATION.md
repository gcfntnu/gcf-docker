# GCF MultiQC implementation checkpoint

**2 November 2026 — published candidate, ready for report acceptance.**

The first replacement is implemented as unmodified upstream MultiQC 1.35 plus
the separately maintained `gcf-multiqc` extension. The candidate image has been
built, tested and pushed. GCF-suite repositories, their selected image, and the
old MultiQC fork remain unchanged.

## Published artifact

| Item | Value |
| --- | --- |
| Versioned image | `gcfntnu/gcf-multiqc:1.35-gcf0.1.0-rc1` |
| Additional tag | `gcfntnu/gcf-multiqc:latest` |
| Platform | Linux amd64 |
| Engine / extension | MultiQC 1.35 / gcf-multiqc 0.1.0rc1 |
| Python / Plotly | 3.11.18 / 6.0.1 |
| Runtime plugin source | `54877b7335635005af113a1a0cd10a9f7fbdfe12` |
| Docker recipe revision | `d9ea199e3ec502a605ee4056a11f8381c53f24d0` |
| Validation tests revision | `568af70b46cb0b0e92bc9325da42be364801a169` |

Both published tags identify this manifest:

```text
sha256:5b69b8bdb2b8d055b190386110c55dcddc99e1e30b6ee846477a703b5c8dd39d
```

Use the versioned tag or digest for evaluation. `latest` follows the requested
build-helper convention and currently denotes this candidate. No tag in the
old `gcfntnu/multiqc` image repository was changed.

The validation revision adds a PCA/UMAP regression and clarifies documentation
after the runtime source revision; the installed implementation is unchanged.

## Implemented behavior

The extension supports the existing selections for RNA-seq, microbiome,
single-cell, small-RNA, default, WGS and metagenome reporting. It ports Parse,
STARsolo, Cell Ranger count/mkfastq, QIIME2 and Unitas; uses upstream parsers for
FastQC, fastp, STAR and Bracken where possible; and preserves GCF custom-content
sample identities and PCA/UMAP conventions.

Legacy selectors work by default. Native upstream meanings can be restored
with `gcf_compatibility: false`, while explicit GCF aliases remain available.
The container retains `multiqc` on PATH and `/opt/images/logo_ntnu.png`, with
no forced entry point.

The implementation corrects per-sample Unitas denominators, distinguishes STAR
splice events from reads, rejects duplicate identities, and makes malformed
ordination input fail promptly. Kraken observations and Bracken estimates stay
separate. PCA, UMAP and QIIME ordination display interpretable group legends.
The inactive legacy template and `fastv` module were not ported.

## Verification results

- **102 tests passed inside the final image**, as a non-root user with Docker
  networking disabled. Fixtures were mounted read only and outputs went to an
  invocation-owned directory. The full run completed in 83.90 seconds.
- Tests render actual HTML with strict validation and assert numeric exports,
  sample identities, units, missing values, aliases and malformed-input behavior.
  They include all seven copied public workflow templates, native BCL Convert,
  bcl2fastq and InterOp, flat-image export, and simultaneous PCA/UMAP rendering.
- A separate installed-wheel suite passed before the final browser refinements;
  affected refinements were tested again and are covered by the final image run.
  Ruff lint/format, dependency consistency and whitespace checks passed.
- Offline Chrome checks exercised representative single-cell, microbiome,
  small-RNA and metagenome reports, including dataset tabs and numeric tooltips.
  No JavaScript errors or external requests were observed. The missing scatter
  legends found during review were fixed and checked again in the browser.
  UMAP was verified through the installed CLI, not independently in the browser.
- The base image digest, source archive checksum and Python wheel hashes are
  pinned. A separate build stage keeps the source archive and fixtures out of
  published image layers. The installed package includes license and attribution.

Two image/export prerequisites were found and fixed during verification:
Plotly must remain below 6.1 for MultiQC 1.35's bundled Kaleido exporter, and the
slim Python image needs process tools, shared libraries and fonts.

Installed Debian additions: `procps 2:4.0.4-9`, `libnss3 2:3.110-1+deb13u5`,
`libnspr4 2:4.36-1`, `libexpat1 2.9.0-1~deb13u1`, and
`fonts-dejavu-core 2.37-8`. These package repositories are not covered by the
Python wheel lock.

## Boundary of this checkpoint

This is a working reporting candidate against synthetic/public inputs. No real
project logs were used, no scientific workflow or GCF-suite integration test
was run, and no deployment or production image selection was changed.
Existing logs from the gcf-work test setup are a possible later acceptance
corpus, rather than a prerequisite for this first implementation.

Next, copy representative saved logs into a local acceptance directory and
render old and candidate reports from the same inputs and existing YAML. Compare
sample sets, required sections, metrics, units, metadata joins and plots, allowing
for the documented correctness fixes. Then verify the existing Apptainer wrapper
on a suitable server. Only after that acceptance should a separate gcf-workflows
change select the new image; retain the old image for rollback.

The recommended future strategy remains upstream MultiQC plus a small GCF
extension, with engine updates gated by these tests and the acceptance corpus.
Keep the fork available during migration, then retire it as an active dependency
when report parity is accepted.

The detailed compatibility contract and source baselines are in the
[plugin README](https://github.com/gcfntnu/gcf-multiqc/blob/568af70b46cb0b0e92bc9325da42be364801a169/README.md)
and [migration plan](https://github.com/gcfntnu/gcf-multiqc/blob/568af70b46cb0b0e92bc9325da42be364801a169/docs/migration-checkpoint.md).
