FROM continuumio/miniconda3:4.9.2

RUN apt-get update --fix-missing && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    gawk \
    unzip \
    p7zip-full \
    git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN conda update conda
RUN conda config --add channels defaults && \
    conda config --add channels bioconda && \
    conda config --add channels conda-forge && \
    conda update --all

RUN conda install --quiet --yes mamba  && conda clean --all

RUN mamba install -y pandas pyyaml openpyxl jinja2 scipy lxml html5lib matplotlib pytables pyreadstat tabulate zlib blosc fsspec numba pyarrow fastparquet gcsfs s3fs beautifulsoup4 bottleneck numexpr pyqt snakemake 
