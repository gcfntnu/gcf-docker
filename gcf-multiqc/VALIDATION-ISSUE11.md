# MultiQC issue-11 candidate validation

16 November 2026. This candidate packages gcf-multiqc `main` at the merge of
[gcf-multiqc PR 12](https://github.com/gcfntnu/gcf-multiqc/pull/12)
([issue 11](https://github.com/gcfntnu/gcf-multiqc/issues/11)):

- **UNITAS:** misc_RNA (labelled "misc_RNA (Y RNA, 7SK, 7SL, …)") and lncRNA (also the older `lincRNA`) are categories instead of "other".
- **`gcf_smallrna_cutadapt`:** names `gcf_three_prime_artefacts`, the third pass of the gcf-workflows small-RNA cutadapt route ([gcf-workflows#360](https://github.com/gcfntnu/gcf-workflows/pull/360)).

Everything else is unchanged from the issue-9 candidate.

## Artifact

| Item | Value |
| --- | --- |
| Candidate tag | `gcfntnu/gcf-multiqc:1.35-gcf0.1.0-rc4-issue11` |
| Registry digest | `sha256:298e4559cfbf7ebc0d2cb0b524234e06777981db1cc7f3758b7cc33c93009357` |
| Tested image ID | `sha256:6be43d0c332af4ee7ae2ca16de25cf7670e31b55355aee3fe85f7ef2b9c2c9db` |
| Platform | Linux amd64 |
| Plugin source | `fca419bbb1d5812f04129710741b2bb7a9209f6f` |
| Source archive SHA256 | `d3a7afc40ae4be1c7432b26d7eba165b5dc91b8fd3f6d5f5cbf084a819efc69d` |
| Engine / extension / Plotly | MultiQC 1.35 / gcf-multiqc 0.1.0rc4 / Plotly 6.0.1 |
| Python | 3.11.18 |
| Image-recipe base | `a540a85077e1e79e9c108de846bae24ef32823cc` (`master`) |

The Python base digest and `requirements.lock` are unchanged. The installed files are equal to the pinned source:

- `gcf_multiqc/modules/unitas.py`: SHA256 `16c8325b12806e03ed2898b57d6f65176a9fc998e1ea65970a9459973451c98c`;
- `gcf_multiqc/modules/smallrna_cutadapt.py`: SHA256 `351d43d3b15ddbbe157d7f8e494bd6c9ff5539b70d06d13f30df937bcbf4aa48`.

## Checks performed

- **Build:** locally with `docker build --platform linux/amd64 --progress=plain -t
  gcfntnu/gcf-multiqc:1.35-gcf0.1.0-rc4-issue11 gcf-multiqc` from the recipe repository root. BuildKit enforced the source archive checksum, which was the same on two independent downloads.
- **Contents:** `python -m pip check` passed inside the image. Engine, plugin and Plotly versions, hooks, module hashes and the OCI revision/version labels were verified.
- **Plugin tests:** all **145 plugin tests passed inside the built image** (132 s). The pinned archive's `tests/` were mounted read-only; the image ran as a non-root user, with no network, a read-only root filesystem and an invocation-owned writable `/tmp`. Test-only pytest 8.4.2, pluggy 1.7.0 and iniconfig 2.3.1 were mounted externally.
- **Render:** the image (non-root, no network, read-only root filesystem, no `--strict`) rendered, with `-m gcf_smallrna_cutadapt -m unitas`, four public plasma libraries (GEO GSE94582) through the gcf-workflows cutadapt route's three passes and UNITAS. Exit 0.
  - **cutadapt:** filtered reads named, including *5′ adapter artefacts* (1,337–258,172 per library) and *Untrimmed 3′ adapter or primer sequence* (1,443–18,472), with nothing uncategorised.
  - **UNITAS:** misc_RNA (562,644–1,404,737 reads) and lncRNA (3,161–13,184) are their own categories with length plots; "other" is 1,542–3,640 reads per library.

The image was published only under its new candidate tag. Existing tags and `latest` were not changed.

## Handoff

Tracked in [gcf-docker issue 45](https://github.com/gcfntnu/gcf-docker/issues/45).
A separate gcf-workflows PR selects this digest in `docker.config`. Production
promotion and server integration remain separate steps.
