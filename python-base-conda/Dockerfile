FROM continuumio/miniconda3:23.10.0-1

ENV PYTHON_VER=3.9 \
    PYTHONDONTWRITEBYTECODE=1

RUN conda config --system --add channels defaults && \
    conda config --system --add channels bioconda && \
    conda config --system --add channels conda-forge && \
    conda config --system --set channel_priority strict

RUN conda install --yes \
        python=${PYTHON_VER} \
        pip && \
    conda clean --all --yes