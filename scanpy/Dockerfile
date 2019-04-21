FROM gcfntnu/python-base-conda:3.7

ENV SCANPY_VER 1.4

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
    r-essentials \
    r-rgl \
    r-biocmanager \
    r-scran \
    bioconductor-dropletutils \
    conda clean -tipsy

RUN pip --no-cache-dir install \
    phate \
    fa2 \
    bbknn \
    magic-impute \
    leidenalg \
    vpolo \
    annoy \
    scprep \
    zappy \
    bioservices

RUN pip install git+https://github.com/flying-sheep/anndata2ri
