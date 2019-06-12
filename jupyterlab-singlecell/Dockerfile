FROM gcfntnu/jupyterlab-base:test2

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
    bioconductor-scran \
    bioconductor-dropletutils && \
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

RUN R --slave -e "install.packages(c('gam', 'RColorBrewer'), repos='https://cloud.r-project.org')"
RUN R --slave -e "BiocManager::install(c('scran','MAST','monocle','ComplexHeatmap','slingshot'), version = '3.8')"


RUN pip install --no-cache-dir anndata scanpy gprofiler
RUN pip install --no-cache-dir https://bitbucket.org/rpy2/rpy2/get/RELEASE_2_9_6b.tar.gz
RUN pip install --no-cache-dir git+https://github.com/flying-sheep/anndata2ri