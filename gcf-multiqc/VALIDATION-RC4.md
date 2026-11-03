# GCF MultiQC rc4 validation

2 November 2026. The rc4 reporting image is published and deployed to an isolated
suite test installation. The fresh seven-fixture integration run and all fifteen
fresh reports passed acceptance. Production adoption remains pending.

## Artifact

| Item | Value |
| --- | --- |
| Versioned image | `gcfntnu/gcf-multiqc:1.35-gcf0.1.0-rc4` |
| Additional tag | `gcfntnu/gcf-multiqc:latest` |
| Registry digest | `sha256:2c356684c03d24c11e63be5724d4f107c253eccd8be98c236952bd3df5435878` |
| Platform | Linux amd64 |
| Engine / extension | MultiQC 1.35 / gcf-multiqc 0.1.0rc4 |
| Runtime source | `4625e75315f5c89475af5ce70313642f4154ce40` |
| Source archive SHA256 | `24fb1d53dfb14b98e37cdb6e13fd06ce8b2271279038ab3aea34f1f4b1127b41` |
| Recipe commit | `00251a6c12629426f330d063b14f0ef8f5391475` |
| Plotly | 6.0.1 |

The Python dependency lock and base digest are unchanged from rc1. The immutable
rc1, rc2 and rc3 tags remain available for historical comparison; `latest` selects rc4.
The workflow PR pins the rc4 registry digest. BFQ integration images use the
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

- [Plugin issue #5](https://github.com/gcfntnu/gcf-multiqc/issues/5): combined
  sequencing runs that reuse lane numbers need consistent run/lane labels for
  every sample. Labels now use all runs when detecting collisions. Single-run
  reports retain short lane labels.
- [Plugin issue #6](https://github.com/gcfntnu/gcf-multiqc/issues/6): GCF filename
  cleaning collapsed paired FastQC mates, so file discovery order decided which
  mate survived. The adapter now preserves both R1/R2 records and plots. Other
  modules keep their sample-level metadata joins, and FastQC adds no duplicate
  General Statistics columns. This defect was also present in the legacy fork.

Upstream MultiQC files remain unmodified. Compatibility adapters are selected
through the existing supported hooks; explicit native opt-out is retained.

## Completed reporting checks

- All **119 plugin tests passed inside the built image** as non-root, with
  networking disabled and a read-only container filesystem. Test inputs were
  mounted read-only; temporary dependencies and outputs were external to the image.
  This includes strict report rendering, numeric exports, all seven public
  workflow profiles and flat-image export.
- The isolated source environment also passed all 119 tests, Ruff lint/format,
  dependency checks and package builds.
- Sixteen copied-input reports passed: eight project reports plus seven
  sequencing reports and one additional Parse report. Legacy and rc4 engines
  rendered the same inputs. Required sections, source metrics and metadata passed
  content gates. Intentional numerical/identity corrections are recorded explicitly.
- The earlier sequencing/Parse comparisons verified **20,594 common exported
  cells** against the legacy reports. Independent
  checks verified 1,170 plotted sample totals, 378 unknown-barcode plotted values,
  and 69 Parse metrics across three library summaries. All checked BCL Convert
  sample/lane counts now agree with their input rows.
- Modern BCL Convert quality means were checked independently as weighted
  averages. Differences from the legacy summed averages are corrections.
  InterOp unit changes retain their scale and labels. Cosmetic numeric formatting
  and equivalent null/empty export representations are classified separately
  from missing measurements. Unavailable sample assignments remain unavailable.
- Eleven reports passed offline browser checks, including PCA dataset tabs,
  embedded ordination figures and the corrected counts-per-lane tab. There were
  no JavaScript/console errors, unexpected network requests or failed images.
- All **35 FastQC archives** retain distinct identities. **630 basic/status
  fields** and **171 overrepresentation table values** agree with source inputs.
  General Statistics and every non-FastQC project export/plot model remained
  unchanged from rc2.
- Project-source checks independently cover Parse metrics, current Cell Ranger
  metrics, Unitas categories/histograms, STAR, fastp, Salmon, taxonomy counts/plots
  and WGS coverage/fraction values. The private acceptance record gives per-case
  counts and bounds; it does not claim exhaustive per-base FastQC verification.
- Original reference-corpus checksums remained unchanged. Raw inputs, rendered
  operational reports and detailed comparison evidence remain private.

## Suite acceptance

The coordinated [BFQ PR](https://github.com/gcfntnu/gcf-bfq/pull/174) and
[workflow PR](https://github.com/gcfntnu/gcf-workflows/pull/222) select the tested
artifact while preserving configuration authority and report paths.
BFQ's full local gate passed 1,060 tests, seven guarded synthetic scenarios,
offline wheel packaging and installed editable/wheel command checks.
Workflow validation passed 20 focused checks on the rc4 digest.
The server bootstrap and GPU checks passed, and Apptainer confirmed MultiQC 1.35
with GCF 0.1.0rc4 from the pinned image.

The final fresh rc4 run passed all **seven fixtures on attempt 1**. Processing
through finalization took **52m44s**. Small RNA, RNA-seq, WGS, metagenome,
two-project default reporting, Parse and current 10x all completed. Scientific
checks, archives, FASTQ/archive checksums, provenance snapshots, native BCL read
oracles, Parse acceptance, single-cell matrices and state-preserving restart
checks passed. Configured test SMTP acceptance was verified; mailbox receipt was
not independently observed. The test daemon stopped after acceptance.

All **eight fresh project reports** passed matched-input legacy/rc4 rendering,
source checks and offline browser checks. Server rc4 reports and local rc4
replays have equal raw exports, General Statistics, section sets and serialized
plot models. Legacy differences are classified against independent inputs.
Shared legacy comparisons cover 865 export cells, 304 displayed table cells and
33,667 plotted values. Source checks include all 35 FastQC archives, 630
basic/status fields, 1,197 FastQC plot values and 171 overrepresentation values;
69 Parse metrics; 40 Cell Ranger metrics; nine STAR libraries; 824 Unitas plot
values; 2,215 taxonomy counts and 1,006 taxonomy plot values; and 84 WGS
coverage/fraction values. Browsers rendered **87 native charts, 24 tables,
three PCA views and five embedded ordination views** without errors.

All **seven fresh sequencing reports** passed source/content checks, module
selection, wrapper mapping and committed-source provenance checks. Independent
comparisons cover 4,446 bcl2fastq export/chart count values and 175 InterOp summary
values, plus native BCL Convert sample/lane data and charts. All 24 expected
samples are represented; the two unavailable WGS assignments remain unavailable.
Zero-assignment cases are covered synthetically; these fresh fixtures contain
no expected zero-count sample.

The earlier rc2 scientific/operational run also passed seven fixtures, but later
project comparisons exposed its FastQC mate loss. That blocked rc2 functional
acceptance and prompted the corrected rc4 build and fresh complete run.

QIIME2 and legacy mkfastq are deprecated for this migration's acceptance scope;
STARsolo has low priority. The five optional fixtures were not exercised in
this integration. These checks do not establish coverage of all optional
scientific routes or all historical producer versions. Saved full-run Parse HTML
and reduced Parse CSVs from different datasets are not treated as matched oracles.
Production promotion, production deployment and mailbox receipt remain separate from
successful report generation and SMTP acceptance.

## Functional differences and future strategy

Report layout and HTML bytes can change. Acceptance instead checks sample/mate
identities, sections, metadata joins, source metrics, units, plots and browser
behavior. STAR Aligned reads means unique plus multimapped reads, excluding
too-many-loci reads. Splice counts describe events and exported ratios retain
precision rather than the fork's two-decimal rounding. Unitas fractions use
each sample's own total.

Taxonomy plots use root-clade plus unclassified fragments for the total. The
legacy direct-assignment sum can undercount redistributed Bracken reports,
affecting Other and derived percentages. Taxon counts remain tied to source
reports; equally scored taxa can change which five appear in a top-five view.
The native report omits the redundant Root tab while retaining root-clade counts
in exported data. Where enabled, the Unclassified view represents classified
root counts as Other; stacked totals still include classified and unclassified
fragments. Fastp's filtered-read plot adds Low Complexity when supplied by the
producer; absent metrics remain unavailable.
FastQC curves use the native range-start x position for binned measurements;
the legacy template used the range midpoint. The underlying bin values agree
with the source archives.

The recommended destination is upstream MultiQC plus this independently
versioned extension. Once the coordinated PRs and test evidence are reviewed,
retire the fork as an active development dependency while retaining its image
for rollback. Keep upstream, extension and reporting image pinned together. Run
these rendering/export/source checks for each engine upgrade, and add synthetic
regressions for new producer formats. Generally useful fixes can be submitted
upstream independently; their acceptance need not delay GCF's own releases.

The tested replacement is ready for coordinated PR review. The PRs remain open. Merge review, stable release,
production promotion and production deployment remain explicit next steps.
