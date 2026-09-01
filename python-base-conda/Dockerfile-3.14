ARG MINICONDA_VERSION=26.5.3
FROM anaconda/miniconda:${MINICONDA_VERSION}

ENV PYTHON_VER=3.14 \
    PYTHONDONTWRITEBYTECODE=1

RUN conda config --system --remove-key channels && \
    conda config --system --add channels defaults && \
    conda config --system --add channels bioconda && \
    conda config --system --add channels conda-forge && \
    conda config --system --set channel_priority strict

RUN conda tos accept --channel https://repo.anaconda.com/pkgs/main && \
    conda tos accept --channel https://repo.anaconda.com/pkgs/r

RUN conda install --yes \
        python=${PYTHON_VER} \
        pip && \
    conda clean --all --yes