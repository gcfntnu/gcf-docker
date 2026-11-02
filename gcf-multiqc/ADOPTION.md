# MultiQC suite adoption handoff

This change set prepares reviewable PRs for replacing the legacy GCF MultiQC
container. It does not merge the PRs, build new images, run server integration,
change an operational installation or deploy the replacement.

## Components and ownership

| Component | Review / issue | Responsibility |
| --- | --- | --- |
| Reporting engine and extensions | [gcf-multiqc PR 1](https://github.com/gcfntnu/gcf-multiqc/pull/1), [issue 2](https://github.com/gcfntnu/gcf-multiqc/issues/2) | Unmodified MultiQC 1.35 plus GCF compatibility adapters and synthetic rendering checks. |
| Reporting image | [gcf-docker PR 1](https://github.com/gcfntnu/gcf-docker/pull/1), [issue 2](https://github.com/gcfntnu/gcf-docker/issues/2) | Pinned image recipe, dependencies, logo and command convention. |
| Workflow selection | [gcf-workflows PR 222](https://github.com/gcfntnu/gcf-workflows/pull/222), [issue 221](https://github.com/gcfntnu/gcf-workflows/issues/221) | Select the candidate through `docker.config`, preserving report commands and project overrides. |
| BFQ reporting boundary | [gcf-bfq PR 174](https://github.com/gcfntnu/gcf-bfq/pull/174), [issue 173](https://github.com/gcfntnu/gcf-bfq/issues/173) | Installed wrapper/configuration coverage, compatible sequencing-report configuration and later build/evaluation instructions. |

The workflow and BFQ issue branches start at their current `bfq-dev` branches
and target `bfq-dev`. The extension and image work continue their existing PRs;
their published artifact is already available for evaluation. No `gcf-tools`
change or second BFQ-owned image version setting is required.

## Reviewed source and local checks

The 2 November 2026 implementation checkpoint uses these source revisions:

| Component | Base | Reviewed head / baseline |
| --- | --- | --- |
| BFQ | `2b1fbc51f625c128e9aa5a083f1c5fe1abb06068` (`bfq-dev`) | `38a6ef921520d679a8e3aa3207e8aca916152756` |
| Workflows | `26fafe406d856b49beead1ecce251cc943e56e63` (`bfq-dev`) | `2f682991267929c828dcb4c77bb56ed45559538a` |
| Plugin | `99958aafa9bb7a49be5d034d33a05ffa7108c6c6` (`main`) | `2b3b0bb74655f76857a0ef2e0413df0a0c7f86a7` |
| Image recipe | `28e66251ec003b0f0d65526d2fa6b8cc03ed92b3` (`master`) | Existing PR 1; recipe unchanged from `87a633d25f6cca6dddae9ddae37942aead69c16c` |
| gcf-tools | No change | `1daa9822084bc3a3df4b94102c13c6352fa57ecd`, the normal BFQ development baseline |

BFQ's `check fast` and `check all` passed all 1,060 tests. The full gate also
passed seven guarded synthetic scenarios, offline wheel packaging/install and
installed-command checks. MultiQC wrapper checks use fake Apptainer, including
SMTP protection, image authority, argument forwarding and failure propagation.
The small BFQ runtime fix selects custom content once for separate conversion
passes; native demultiplexer selection and zero/unavailable counts are preserved.

Workflow validation passed 20 focused tests and seven normal profile reporting
dry-runs. The tests cover command/output contracts and explicit project overrides.
They use Snakemake 8.1.1, PyYAML 6.0 and pulp 2.7.0.
Plugin validation passed 107 synthetic tests with MultiQC 1.35 and Plotly 6.0.1,
plus lint, formatting and dependency checks. GitHub CI passed for the workflow
and plugin heads above. Private reference reports were not rendered.

These results support the source-review checkpoint. They do not establish
operational numerical/visual parity or server/container behavior. No image was
built or published during this adoption phase; the earlier published-image
validation remains a separate historical receipt.

## Exact reporting artifact

The proposed workflow mapping is:

```yaml
docker:
  multiqc: gcfntnu/gcf-multiqc@sha256:5b69b8bdb2b8d055b190386110c55dcddc99e1e30b6ee846477a703b5c8dd39d
```

That digest was published as `1.35-gcf0.1.0-rc1` for Linux amd64. Its installed
plugin source is `54877b7335635005af113a1a0cd10a9f7fbdfe12`; engine version is
1.35 and extension version is 0.1.0rc1. Later test/documentation changes in the
plugin PR do not change that installed runtime. The historical image validation
is recorded in [VALIDATION.md](VALIDATION.md).

The proposed mapping deliberately selects the existing digest. A local rebuild
from this recipe is a separate artifact and must be identified separately;
the Debian package repositories are not frozen. A newly accepted build requires
its own tag/digest and a reviewed workflow mapping update. Do not overwrite rc1
or make the suite follow `latest`.

## Which configuration controls each invocation

BFQ's installed `multiqc` command remains its Apptainer wrapper. It reads the
workflow image mapping through the existing `GCF_WORKFLOWS_DOCKER_CONFIG`
override or the documented installed default. Installing the reporting engine
into BFQ's Python environment would shadow that wrapper and is not part of this
migration.

Project reporting runs through Snakemake's shared `multiqc_report` rule and the
project's workflow/configuration. The workflow's Docker defaults fill missing
keys; an explicit project `docker.multiqc` value retains precedence. The BFQ
wrapper's environment override does not change that Snakemake selection.

An existing retained analysis workdir can contain both an older copied workflow
checkout and an explicit image override. Updating only the installed workflow
checkout does not switch such a workdir. Record and inspect the effective
configuration before later evaluation; do not overwrite curated project
configuration or modify operational state to force a new engine.

## Build and test checkpoint

1. Review the linked PRs and their exact head commits. Local unit/configuration
   checks and synthetic rendering demonstrate the implementation contracts;
   their success is not a server acceptance result.
2. For the reporting image, either use the published digest or follow the
   [local evaluation build](README.md#build-for-evaluation) using a separate
   tag. The latter build is optional when evaluating the published artifact.
3. For the BFQ test image, use the BFQ issue branch and explicitly select the
   workflow issue branch/full revision through `dockerfile-test` build
   arguments. The [BFQ evaluation guide](https://github.com/gcfntnu/gcf-bfq/blob/issues/173-multiqc-adoption/docs/multiqc-adoption.md)
   contains the build-only procedure and existing configuration overrides.
   BFQ's normal build helper immediately pushes, so it is not a build-only
   command. Record BFQ, workflow, tools and base-image revisions for evaluation.
4. After that checkpoint is approved, perform reporting-only comparisons from
   the same copied input logs and configuration, writing old and new outputs to
   separate directories. Do not compare an original full-run report against
   inputs reduced for a different fixture. Keep operational references and
   report evidence private, outside repositories and build contexts.
5. Verify both the server's Apptainer wrapper and the project report path. A
   BFQ rerun from reporting preserves existing project analysis reports; it does
   not itself demonstrate the new engine on those reports. Use the separately
   arranged project-report evaluation described by the workflow/BFQ guides.
6. Evaluate the evidence before merging, promoting production branches or
   deploying. Rollback consists of selecting the previous image through the
   same configuration authority. Retain the old image and reference outputs.

The required acceptance set covers active report families, Parse, Cell Ranger
count, FastQC/fastp, STAR, Unitas, Kraken/Bracken, custom-content metadata and
PCA/UMAP, plus native sequencing QC. QIIME2 and legacy mkfastq are deprecated
for acceptance; STARsolo is low priority. Existing adapters remain installed.
Check numerical values and units, exact sample identities, sections, metadata
joins, zero/missing values and plot behavior. Treat the documented Unitas and
STAR corrections as intentional differences, not parity failures.

The authoritative image selection and project configuration checks are described
in the [workflow MultiQC guide](https://github.com/gcfntnu/gcf-workflows/blob/issues/221-multiqc-adoption/misc/multiqc/README.md).
