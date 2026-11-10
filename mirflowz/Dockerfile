# segemehl 0.3.4 as mirflowz's rules pin it (quay.io/biocontainers/segemehl:0.3.4--hf7d323f_8).
# The current bioconda build (h3e6c209_13) gives a different MAPQ for one read of mirflowz's
# test data, so test/expected_output.md5 only matches with this build.
FROM quay.io/biocontainers/segemehl:0.3.4--hf7d323f_8@sha256:987c37d4bb73c71bf68cc44d1d091b53f7bdca298489ff975530eebac49503d3 AS segemehl

FROM mambaorg/micromamba:2.0.5

# mirflowz v0.10.0 (https://github.com/zavolanlab/mirflowz, MIT) with every tool its rules call,
# for running it as one nested Snakemake call inside a gcf-workflows rule (no inner containers or
# conda): snakemake -s $MIRFLOWZ_DIR/workflow/Snakefile --configfile ... --cores N --no-hooks
# The config must set scripts_dir: $MIRFLOWZ_DIR/scripts/ (mirflowz's default ../scripts/ is
# relative to the run directory).
#
# Tools: env.yml (pinned to mirflowz's versions); packages.txt lists the resolved environment.
# segemehl comes from mirflowz's own segemehl container (first stage below).
# cufflinks 2.2.1 (only for gffread) needs Python <= 3.6, so it has its own environment and
# gffread is linked onto PATH.
#
# Image tag: <mirflowz version>[-<n>], e.g. 0.10.0; never overwrite a published tag.
ENV MIRFLOWZ_VERSION=0.10.0
ENV MIRFLOWZ_BUILD=0.10.0
ARG MIRFLOWZ_SHA256=a67187b9b926817421e9016086d683b4c7ae632c0c7a7aa7023c5c982fc81080

COPY --chown=$MAMBA_USER:$MAMBA_USER env.yml /tmp/env.yml
RUN micromamba install -y -n base -f /tmp/env.yml && \
    micromamba create -y -n cufflinks -c conda-forge -c bioconda --override-channels cufflinks=2.2.1 && \
    micromamba clean --all --yes && rm /tmp/env.yml

USER root
COPY --from=segemehl /usr/local /opt/segemehl
RUN ln -s /opt/conda/envs/cufflinks/bin/gffread /usr/local/bin/gffread && \
    ln -s /opt/segemehl/bin/segemehl.x /usr/local/bin/segemehl.x && \
    /opt/conda/bin/python -c "import urllib.request, hashlib, tarfile, io; \
data = urllib.request.urlopen('https://github.com/zavolanlab/mirflowz/archive/refs/tags/v${MIRFLOWZ_VERSION}.tar.gz').read(); \
assert hashlib.sha256(data).hexdigest() == '${MIRFLOWZ_SHA256}', 'mirflowz archive checksum differs'; \
tarfile.open(fileobj=io.BytesIO(data)).extractall('/opt')" && \
    mv /opt/mirflowz-${MIRFLOWZ_VERSION} /opt/mirflowz && chmod -R a+rX /opt/mirflowz
USER $MAMBA_USER

# Snakemake calls the tools directly (no entrypoint under Apptainer), so the environment is on PATH.
ENV MIRFLOWZ_DIR=/opt/mirflowz
ENV PATH=/opt/conda/bin:$PATH

# Build checks: every tool the rules call, and a dry run of the mirflowz test workflow.
RUN for t in snakemake segemehl.x oligomap cutadapt fastx_collapser fastq_to_fasta fastq_quality_filter fasta_formatter \
             bedtools samtools bgzip gffread perl Rscript python zcat; do command -v $t > /dev/null || { echo "missing $t"; exit 1; }; done && \
    python -c "import pysam, gffutils, Bio, pandas, pulp" && \
    Rscript -e 'suppressMessages({library(rtracklayer); library(optparse); library(tidyverse)})' && \
    cp -r /opt/mirflowz /tmp/m && cd /tmp/m/test && \
    snakemake -s /opt/mirflowz/workflow/Snakefile --configfile config.yaml \
        --config scripts_dir=/opt/mirflowz/scripts/ --cores 1 --no-hooks -n --quiet && \
    cd / && rm -rf /tmp/m
