# MultiQC issue-9 candidate validation

16 November 2026. This candidate packages gcf-multiqc `main` at the merge of
[gcf-multiqc PR 10](https://github.com/gcfntnu/gcf-multiqc/pull/10)
([issue 9](https://github.com/gcfntnu/gcf-multiqc/issues/9)). It adds
`gcf_smallrna_cutadapt`, a module selected explicitly for the merged cutadapt
reports of the gcf-workflows small-RNA cutadapt filter route
([gcf-workflows#350](https://github.com/gcfntnu/gcf-workflows/issues/350)). Native
`cutadapt` and every other report selection are unchanged from the issue-7
candidate.

## Artifact

| Item | Value |
| --- | --- |
| Candidate tag | `gcfntnu/gcf-multiqc:1.35-gcf0.1.0-rc4-issue9` |
| Registry digest | `sha256:58df7c7fadc670cdb41deab8b9e208f59282eabaa87177936ce4981d1a885f8a` |
| Tested image ID | `sha256:8c90000c455162fefba164c107bcd91f46d070ce54623a466f705959b9006d0f` |
| Platform | Linux amd64 |
| Plugin source | `665c4a3c02c14f619cc73852c3d8c1cdfbd53c17` |
| Source archive SHA256 | `be08a385294c79e11ad6ea8a1f41aecf02ebffd524e2005e0d5466cd6502e33f` |
| Engine / extension / Plotly | MultiQC 1.35 / gcf-multiqc 0.1.0rc4 / Plotly 6.0.1 |
| Python | 3.11.18 |
| Image-recipe base | `6d5501bb67b2f0d454451d66731c00482eb41093` (`master`) |

The Python base digest and `requirements.lock` are unchanged. The installed
`gcf_multiqc/modules/smallrna_cutadapt.py` has SHA256
`01ee98ef856bb8870db73cce88728ebb7c24b765d3778b80cabb30fe3522b193`, equal to the
pinned source. The image registers the modules `gcf_cellranger_mkfastq`,
`gcf_fastp`, `gcf_smallrna_cutadapt`, `gcf_star` and `unitas` among others, and the hooks
`before_config`, `config_loaded`, `before_modules` and `after_modules`.

## Checks performed

- Built locally with `docker build --platform linux/amd64 --progress=plain -t
  gcfntnu/gcf-multiqc:1.35-gcf0.1.0-rc4-issue9 gcf-multiqc` from the recipe
  repository root; BuildKit enforced the source archive checksum (the same on two
  independent downloads).
- `python -m pip check` passed inside the image; engine, plugin and Plotly
  versions, entry points, module hash and the OCI revision/version labels were
  verified.
- All **142 plugin tests passed inside the built image** (129 s), from the pinned
  archive's `tests/` mounted read-only, as a non-root user with no network, a
  read-only root filesystem and an invocation-owned writable `/tmp`. Test-only
  pytest 8.4.2, pluggy 1.7.0 and iniconfig 2.3.1 were mounted externally and are
  not part of the image. The suite includes the seven workflow report profiles
  (the smallrna one selecting `gcf_smallrna_cutadapt`), flat-image rendering, and
  the module's merged-report, rejection and non-strict failure cases.
- Rendered the delivered merged cutadapt reports of four public plasma libraries
  (GEO GSE94582, gcf-workflows cutadapt route) with `-m gcf_smallrna_cutadapt`
  and without `--strict`, as the workflow invokes it, non-root, no network, on a
  read-only root filesystem: exit 0; General Statistics 2,000,000 reads, 34.1–92.4%
  passing filter, 97.9–99.8% 3′ adapter; filtered reads named, with *5′ adapter
  artefacts* 1,337–258,172 per library and nothing uncategorised.

The image was published only under its new candidate tag. Existing tags and
`latest` were not changed.

## Handoff

Tracked in [gcf-docker issue 43](https://github.com/gcfntnu/gcf-docker/issues/43).
A separate gcf-workflows PR selects this digest in `docker.config` and switches
the smallrna module list from `cutadapt` to `gcf_smallrna_cutadapt`. Production
promotion and server integration remain separate steps.
