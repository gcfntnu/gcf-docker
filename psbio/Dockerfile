FROM gcfntnu/python-base-conda:3.12

ARG SPLITPIPE_VER=1.8.1
ARG INSTALL_IMMUNE_DBS=false

ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1

RUN cat > /opt/conda/.condarc <<'EOF'
channels:
  - conda-forge
  - bioconda
channel_priority: strict
default_channels: []
show_channel_urls: true
auto_update_conda: false
EOF

# System dependencies corresponding to Parse install_dependencies.sh.
# Docker has root, so do this explicitly instead of running the sudo-based script.
RUN apt-get update --fix-missing && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        gawk \
        pigz \
        less \
        unzip \
        p7zip-full \
        samtools \
        rna-star \
        fastqc \
        tabix \
        zlib1g-dev \
        libbz2-dev \
        libcurl4-openssl-dev \
        libssl-dev \
        libxml2-dev \
        curl \
        ca-certificates \
        git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


# Heavy Python/scientific deps through conda/mamba where possible.
# Parse 1.8.1 requires Python >=3.12.8 according to both install scripts.
RUN python - <<'PY'
import sys
assert sys.version_info >= (3, 12, 8), sys.version
PY

RUN mamba install --quiet --yes \
        pip \
        #"numpy>=2.0" \
        #"Cython>=3.0" \
        setuptools \
        wheel \
        pandas \
        scipy \
        matplotlib \
        scanpy \
        anndata \
        #"numba<=0.61.2" \
        h5py \
        natsort \
        tqdm \
        networkx \
        joblib \
        python-igraph \
        leidenalg \
        louvain \
        bbknn \
        pysam \
        jinja2 \
        psutil \
        python-calamine \
        python-annoy \
        indexed_gzip \
        scikit-misc \
        dask \
        gsl \
        tzlocal \
        simplegeneric \
        libxcrypt \
        libxml2 \
        libgomp \
        htslib && \
    mamba clean --all --yes

COPY ParseBiosciences-Pipeline.${SPLITPIPE_VER}.zip /tmp/

RUN cd /tmp && \
    unzip ParseBiosciences-Pipeline.${SPLITPIPE_VER}.zip && \
    cd ParseBiosciences-Pipeline.${SPLITPIPE_VER} && \
    pip install --no-cache-dir . && \
    cd / && \
    rm -rf /tmp/ParseBiosciences-Pipeline.${SPLITPIPE_VER} \
           /tmp/ParseBiosciences-Pipeline.${SPLITPIPE_VER}.zip

# Fail-fast smoke tests.

RUN split-pipe >/tmp/splitpipe.check.txt && \
    split-pipe --help >/dev/null && \
    split-pipe --explain >/dev/null && \
    samtools --version >/dev/null && \
    STAR --version >/dev/null && \
    fastqc --version >/dev/null && \
    bgzip --help >/dev/null