FROM gcfntnu/python-base-conda:3.7

ENV SCANPY_VER 1.4.4

RUN conda install --quiet --yes \
    scanpy=$SCANPY_VER \
    argparse \
    pip \
    dask \
    dca \
    pypairs \
    numba \
    multicore-tsne \
    cython \
    joblib \
    pandas=0.23.4 \
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
    r-rgl \
    r-biocmanager \
    rpy2 \
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
    scrublet

RUN pip install git+https://github.com/theislab/anndata2ri
RUN pip install git+https://github.com/theislab/scvelo