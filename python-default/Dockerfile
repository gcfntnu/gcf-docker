FROM gcfntnu/python-base-conda:3.12

# Default container of gcf-workflows. Python packages are pinned in env.yml; the resolved
# environment of the published build is listed in packages.txt. Publish every rebuild under a
# new tag (3.12-1, 3.12-2, ...) and never overwrite an existing one.
ENV PYTHON_DEFAULT_BUILD=3.12-1

RUN apt-get update --fix-missing && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    curl \
    gawk \
    less \
    unzip \
    p7zip-full \
    wget \
    git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY env.yml /tmp/env.yml
RUN conda env update --name base --file /tmp/env.yml && \
    rm /tmp/env.yml

RUN conda clean -afy \
    && find /opt/miniconda3/ -follow -type f -name '*.a' -delete \
    && find /opt/miniconda3/ -follow -type f -name '*.pyc' -delete \
    && find /opt/miniconda3/ -follow -type f -name '*.js.map' -delete

RUN for t in wget curl unzip 7z git; do command -v "$t" || exit 1; done && \
    ! conda list 2>&1 | grep -qi "error while loading" && \
    python -c "import pandas, numpy, polars, scipy, yaml, peppy, pyxcelframe; print('pandas', pandas.__version__, 'numpy', numpy.__version__, 'polars', polars.__version__)"
