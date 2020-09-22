FROM gcfntnu/python-base-conda:4.8.2

ENV SCANPY_VER 1.6.0

RUN mamba install --quiet --yes \
    scanpy=$SCANPY_VER \
    anndata \
    anndata2ri \
    phate \
    cellrank \
    scvi \
    vpolo \
    rpy2 \
    r-argparse \
    pip \
    dask \
    dca \
    deicode \
    python-annoy \
    scprep \
    scrublet \
    pypairs \
    numba \
    cython \
    joblib \
    pandas \
    scipy \
    matplotlib \
    scikit-learn \
    scikit-image \
    ipykernel \
    gsl \
    tzlocal \
    simplegeneric \
    natsort \
    h5py \
    tqdm \
    patsy \
    llvmlite \
    numba \
    networkx \
    joblib \
    numexpr \
    pytables \
    seaborn \
    cmake \
    statsmodels \
    python-igraph \
    louvain \
    leidenalg \
    bbknn \
    loompy \
    zappy \
    bioservices \
    r-essentials \
    bioconductor-genomeinfodb \
    bioconductor-genomeinfodbdata \
    r-rgl \
    r-seurat \
    r-loom \
    bioconductor-deseq2 \
    bioconductor-vsn \
    loompy \
    r-biocmanager \
    bioconductor-scran \
    bioconductor-dropletutils && \
    mamba clean -ai

RUN pip --no-cache-dir install \
    fa2 \
    magic-impute 

RUN pip install git+https://github.com/DmitryUlyanov/Multicore-TSNE.git
RUN pip install git+https://github.com/theislab/diffxpy

#RUN mamba install --quiet --yes -c conda-forge rust setuptools-rust
#RUN pip install git+https://github.com/k3yavi/vpolo.git

#RUN pip install git+https://github.com/theislab/scanpy
#RUN pip install git+https://github.com/theislab/anndata2ri
#RUN pip install git+https://github.com/theislab/scvelo
#RUN pip install git+https://github.com/theislab/cellrank
#RUN R --slave -e "BiocManager::install('GenomeInfoDb')"