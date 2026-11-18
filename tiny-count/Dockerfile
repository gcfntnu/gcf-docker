FROM mambaorg/micromamba:2.0.5

# tiny-count 1.6.0 (https://github.com/MontgomeryLab/tinyRNA, GPL-3.0; Tate, Brown and Montgomery,
# Bioinformatics Advances 3:vbad065, 2023), the counter of the tinyRNA pipeline, from bioconda, unmodified.
# The full tinyRNA pipeline (fastp, cwltool) is not included.
#
# gcf-workflows runs the smallrna tinyrna route in this image (gcf-workflows#373): its own filtered reads are
# collapsed with tiny-collapse (FASTA names <n>_count=<reads>), aligned end to end with Bowtie 1 reporting all
# alignments of a read together (SAM straight from Bowtie, whose @PG tiny-count accepts as keeping
# multimapping alignments adjacent), and counted by tiny-count against the miRBase GFF with a Features Sheet.
#
# HTSeq, pandas and numpy are pinned to upstream's tested versions (conda/environment_3.10.yml): the bioconda
# recipe leaves them open, and with HTSeq 2.1 tiny-count fails on every GFF (also in the biocontainer
# quay.io/biocontainers/tiny-count:1.6.0--py310hd766df8_0). Two things callers must handle: tiny-count exits 0
# after an error (check its outputs), and its Paths File must contain every key, also those only the full
# pipeline uses (tests/smoke_tiny_count.sh shows a complete one).
#
# Tools: env.yml; packages.txt lists the resolved environment.
# Image tag: <tiny-count version>-<n>, e.g. 1.6.0-1; never overwrite a published tag.
ENV TINY_COUNT_VERSION=1.6.0

COPY --chown=$MAMBA_USER:$MAMBA_USER env.yml /tmp/env.yml
RUN micromamba install -y -n base -f /tmp/env.yml && micromamba clean --all --yes && rm /tmp/env.yml

# Snakemake calls the tools directly (no entrypoint under Apptainer), so the environment is on PATH.
ENV PATH=/opt/conda/bin:$PATH

# Build checks: the version and every tool the route calls.
# The version comes from the conda package: upstream's v1.6.0 setup.py still says 1.5.0.
RUN ls /opt/conda/conda-meta/tiny-count-1.6.0-*.json > /dev/null && \
    for t in tiny-count tiny-collapse bowtie bowtie-build samtools; do command -v $t > /dev/null || { echo "missing $t"; exit 1; }; done && \
    tiny-count -h > /dev/null && tiny-collapse -h > /dev/null && bowtie --version | head -1 | grep -q "1.3.1"
