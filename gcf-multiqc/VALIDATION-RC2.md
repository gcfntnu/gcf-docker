# GCF MultiQC rc2 validation

2 November 2026. The rc2 reporting image is published and deployed to an isolated
suite test installation. Copied-input acceptance has passed; the fresh seven-fixture
server run is underway. Production adoption remains pending.

## Artifact

| Item | Value |
| --- | --- |
| Versioned image | `gcfntnu/gcf-multiqc:1.35-gcf0.1.0-rc2` |
| Additional tag | `gcfntnu/gcf-multiqc:latest` |
| Registry digest | `sha256:8c53227c570280641c51738a8e7308ae11cddd00a1e0cd1092e5cef7d92cc9e9` |
| Platform | Linux amd64 |
| Engine / extension | MultiQC 1.35 / gcf-multiqc 0.1.0rc2 |
| Runtime source | `df0aef569b77bd8f310c4e5dba77d2d65e03254f` |
| Source archive SHA256 | `1998bc7b742e14cd3965e7ab00a808ae0a04d92b931492ca1727300744625b25` |
| Recipe commit | `c24321c84c27d8bdf610f9ac0e4d5ed275721816` |
| Plotly | 6.0.1 |

The Python dependency lock and base digest are unchanged from rc1. The immutable
rc1 tag remains available for historical comparison; `latest` now selects rc2.
The workflow PR pins the rc2 registry digest. BFQ integration images use the
normal disposable `dev-test` tag.

## Defects found and repaired

- [Plugin issue #3](https://github.com/gcfntnu/gcf-multiqc/issues/3): custom
  General Statistics text such as `0007` was coerced to a number in the visible
  table and data exports. The adapter preserves literal text, HTML escaping and
  locale-sensitive punctuation while leaving scientific numeric columns numeric.
- [Plugin issue #4](https://github.com/gcfntnu/gcf-multiqc/issues/4): native BCL
  Convert parsing retained only the last index row in sample/lane chunks.
  The adapter accumulates those chunks, preserves weighted quality and distinct
  indices, and keeps counts-per-lane plots consistent with independent CSV sums.
  Aggregate sample totals were already correct and remain correct.

Upstream MultiQC files remain unmodified. Compatibility adapters are selected
through the existing supported hooks; explicit native opt-out is retained.

## Completed reporting checks

- All **113 plugin tests passed inside the built image** as non-root, with
  networking disabled and a read-only container filesystem. Test inputs were
  mounted read-only; temporary dependencies and outputs were external to the image.
  This includes strict report rendering, numeric exports, all seven public
  workflow profiles and flat-image export.
- The isolated source environment also passed all 113 tests, Ruff lint/format,
  dependency checks and package builds.
- Eight reports rendered from copied inputs with both legacy and rc2 engines:
  seven sequencing reports and one Parse report. All eight section sets and
  the corresponding content gates passed.
- **20,594 common exported cells** agreed with the legacy reports. Independent
  checks verified 1,170 plotted sample totals, 378 unknown-barcode plotted values,
  and 69 Parse metrics across three library summaries. All checked BCL Convert
  sample/lane counts now agree with their input rows.
- Modern BCL Convert quality means were checked independently as weighted
  averages. Differences from the legacy summed averages are corrections.
  InterOp unit changes retain their scale and labels. Cosmetic numeric formatting
  and missing-value representation are not treated as content loss.
- Three representative reports passed offline browser checks, including the
  corrected counts-per-lane tab, with no JavaScript/console errors, unexpected
  network requests or failed images.
- Original reference-corpus checksums remained unchanged. Raw inputs, rendered
  operational reports and detailed comparison evidence remain private.

## Suite acceptance

The coordinated [BFQ PR](https://github.com/gcfntnu/gcf-bfq/pull/174) and
[workflow PR](https://github.com/gcfntnu/gcf-workflows/pull/222) select the tested
artifact while preserving configuration authority and report paths.
BFQ's full local gate passed 1,060 tests, seven guarded synthetic scenarios,
offline wheel packaging and installed editable/wheel command checks.
Workflow validation passed 20 focused checks on the rc2 digest.
The server bootstrap and GPU checks passed, and Apptainer confirmed MultiQC 1.35
with GCF 0.1.0rc2 from the pinned image.

The fresh seven-fixture run covers small RNA, RNA-seq, WGS, metagenome,
multi-project default reporting, Parse and current 10x. It must complete
scientific processing, reporting, archives, checksums and notification acceptance.
Additional checks compare project report content against source logs and the
legacy engine using the same inputs. Results will be recorded here when complete.

QIIME2 and legacy mkfastq are deprecated for this migration's acceptance scope;
STARsolo has low priority. These checks do not establish coverage of all optional
scientific routes or all historical producer versions. Saved full-run Parse HTML
and reduced Parse CSVs from different datasets are not treated as matched oracles.
Production promotion, deployment and mailbox receipt remain separate from
successful report generation and SMTP acceptance.
