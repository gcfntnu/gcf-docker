FROM continuumio/miniconda3:23.10.0-1

# pin python version
ENV PYTHON_VER 3.9

RUN conda config --add channels defaults && \
    conda config --add channels bioconda && \
    conda config --add channels conda-forge && \
    conda update --all

RUN conda install --yes python=${PYTHON_VER} mamba  \
    && conda clean -afy \
    && find /opt/conda/ -follow -type f -name '*.a' -delete \
    && find /opt/conda/ -follow -type f -name '*.pyc' -delete \
    && find /opt/conda/ -follow -type f -name '*.js.map' -delete
