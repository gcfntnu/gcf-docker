FROM gcfntnu/python-base-conda:3.7

ENV SCANPY_VER 1.4.4

RUN conda install --quiet --yes \
    scanpy \
    argparse \
    pip \
    dask \
    dca \
    pypairs \
    numba \
    multicore-tsne \
    cython \
    joblib \
    pandas \
    scipy \
    matplotlib \
    scikit-learn \
    scikit-image \
    jupyter \
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
    r-biocmanager \
    bioconductor-scran \
    bioconductor-dropletutils && \
    conda clean -tipsy

RUN pip --no-cache-dir install \
    phate \
    fa2 \
    magic-impute \
    vpolo \
    annoy \
    scprep \
    scrublet \
    rpy2

RUN pip install git+https://github.com/theislab/scanpy
RUN pip install git+https://github.com/theislab/anndata2ri
RUN pip install git+https://github.com/theislab/scvelo
RUN pip install git+https://github.com/theislab/cellrank
RUN R --slave -e "BiocManager::install('GenomeInfoDb')"