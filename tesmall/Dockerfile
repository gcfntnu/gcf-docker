FROM mambaorg/micromamba:2.0.5

# TEsmall 2.1.0 (https://github.com/mhammell-laboratory/TEsmall, GPL-3.0) from bioconda, with one patch:
# tesmall-2.1.0-no-trim.patch adds --no-trim. TEsmall always runs cutadapt twice on its input, a 3' trim
# with -a and a 5' trim with a hard-coded TruSeq 5' adapter (GTTCAGAGTTCTACAGTCCGACGATC). On reads that
# are already adapter-trimmed, the 5' step still removes partial matches of 3 nt or more at the read start
# (e.g. miR-23a-3p begins with ATC, the end of that adapter). With --no-trim both steps run cutadapt with
# only the -m/-M length filter, so file names and the logs TEsmall's summary reads stay the same.
#
# gcf-workflows runs TEsmall per sample with --no-trim on its own filtered reads and its own database
# (--dbfolder, with a genome name that is not one of TEsmall's built-in names, so a broken database stops
# the run instead of triggering a download).
#
# Tools: env.yml; packages.txt lists the resolved environment.
# Image tag: <TEsmall version>-<n>, e.g. 2.1.0-1; never overwrite a published tag.
ENV TESMALL_VERSION=2.1.0

COPY --chown=$MAMBA_USER:$MAMBA_USER env.yml /tmp/env.yml
COPY --chown=$MAMBA_USER:$MAMBA_USER tesmall-2.1.0-no-trim.patch /tmp/no-trim.patch
RUN micromamba install -y -n base -f /tmp/env.yml && \
    site=$(/opt/conda/bin/python -c "import os, TEsmall; print(os.path.dirname(os.path.dirname(TEsmall.__file__)))") && \
    /opt/conda/bin/patch -p1 -d "$site" --forward < /tmp/no-trim.patch && \
    micromamba remove -y -n base patch && micromamba clean --all --yes && rm /tmp/env.yml /tmp/no-trim.patch

# Snakemake calls the tools directly (no entrypoint under Apptainer), so the environment is on PATH.
ENV PATH=/opt/conda/bin:$PATH

# Build checks: the patched option, the version, and every tool TEsmall calls.
RUN TEsmall --help | grep -q -- "--no-trim" && TEsmall --version 2>&1 | grep -q "2.1.0" && \
    for t in cutadapt bowtie bowtie-build samtools bedtools; do command -v $t > /dev/null || { echo "missing $t"; exit 1; }; done && \
    python -c "import pybedtools, pandas, pysam"
