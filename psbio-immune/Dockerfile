FROM gcfntnu/python-base-conda:3.12

ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1

# Force conda/mamba to avoid defaults/Anaconda ToS.
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
# Docker runs as root, so do this explicitly instead of running the sudo-based script.
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

# Parse 1.8.x install scripts require Python >= 3.12.8.
RUN python - <<'PY'
import sys
assert sys.version_info >= (3, 12, 8), sys.version
PY

# Keep this conda transaction small. Let pip resolve most Python deps from Parse metadata.
RUN mamba install --quiet --yes \
        -c conda-forge \
        -c bioconda \
        pip \
        "numpy>=2.0" \
        "Cython>=3.0" \
        setuptools \
        wheel \
        "numba<=0.61.2" \
        libxcrypt \
        libgomp \
        htslib \
        gsl && \
    mamba clean --all --yes

# Keep the source tree under /opt.
# Immune DBs are installed into the source tree under splitpipe/immune_dir.
COPY ParseBiosciences-Pipeline.1.8.1.zip /opt/

RUN cd /opt && \
    unzip ParseBiosciences-Pipeline.1.8.1.zip && \
    cd ParseBiosciences-Pipeline.1.8.1 && \
    bash ./install_immune_dbs.sh -I -y && \
    pip install --no-cache-dir . && \
    bash ./install_immune_dbs.sh -c

# Smoke tests: CLI, external tools, and immune DB presence.
RUN split-pipe --help >/dev/null && \
    split-pipe --explain >/dev/null && \
    samtools --version >/dev/null && \
    STAR --version >/dev/null && \
    fastqc --version >/dev/null && \
    bgzip --help >/dev/null && \
    test -d /opt/ParseBiosciences-Pipeline.1.8.1/splitpipe/immune_dir && \
    find /opt/ParseBiosciences-Pipeline.1.8.1/splitpipe/immune_dir -mindepth 1 | head -n 1 >/dev/null