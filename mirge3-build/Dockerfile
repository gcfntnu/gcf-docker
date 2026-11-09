FROM mambaorg/micromamba:2.0.5

# Builds miRge3 0.1.4 libraries (miRBase and MirGeneDB) from public sources:
#   build_mirge3_lib.sh --species homo_sapiens|mus_musculus|rattus_norvegicus --outdir DIR ...
# See the header of build_mirge3_lib.sh for sources and choices, and mirge3_lib.py for the file
# formats. Quantification stays on the miRge3 0.1.4 biocontainer, whose bowtie (1.3.1) builds the
# indexes here. miRge-build 0.0.1 is installed with pip --no-deps (its conda package pins bowtie
# 1.2.3) for reference; the builder calls bowtie-build directly so the genome index is built once
# for both databases.
#
# A local build tool, not published to Docker Hub: build it here (docker build -t
# gcfntnu/mirge3-build:<version> .), build the libraries with it, and publish the libraries to the
# release store. MIRGE3_BUILD is recorded in each library's gcf_manifest.tsv.
ENV MIRGE3_BUILD=1.0.0

COPY --chown=$MAMBA_USER:$MAMBA_USER env.yml /tmp/env.yml
RUN micromamba install -y -n base -f /tmp/env.yml && \
    micromamba clean --all --yes && rm /tmp/env.yml
ARG MAMBA_DOCKERFILE_ACTIVATE=1
RUN pip install --no-cache-dir --no-deps miRge-build==0.0.1

USER root
COPY build_mirge3_lib.sh mirge3_lib.py /opt/mirge3-build/
COPY tests /opt/mirge3-build/tests
RUN chmod 755 /opt/mirge3-build/*.sh /opt/mirge3-build/*.py && ln -s /opt/mirge3-build/build_mirge3_lib.sh /usr/local/bin/
USER $MAMBA_USER
ENV PATH=/opt/conda/bin:/opt/mirge3-build:$PATH

# Build checks: tools, unit tests, and the flank function against miRge-build's own.
RUN bowtie-build --version | head -1 | grep -q 'version 1.3.1' && \
    for t in bcftools bedtools samtools pigz curl bowtie-inspect; do command -v $t > /dev/null || exit 1; done && \
    python -I /opt/mirge3-build/tests/test_mirge3_lib.py && \
    python -c "import sys; sys.path.insert(0, '/opt/mirge3-build'); import mirge3_lib as m; \
from mirge_build.blibs.miRge_bowtie_build import miRNA_miRge_format as f; \
hp = 'TGGGATGAGGTAGTAGGTTGTATAGTTTTAGGGTCACACCC'; mir = 'TGAGGTAGTAGGTTGTATAGTT'; \
a, b = m.mirge_flanks(hp, mir); assert a + mir + b == f(hp, mir), 'flanks differ from miRge-build'"
