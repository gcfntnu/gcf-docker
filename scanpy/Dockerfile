FROM gcfntnu/python-base-conda:4.10.3

ENV SCANPY_VER 1.9.1

RUN mamba install --quiet --yes \
    scanpy=$SCANPY_VER \
    anndata \
    anndata2ri \
    scvelo \
    phate \
    cellrank \
    scvi \
    rpy2 \
    r-argparse \
    pip \
    dask=2022.10.0 \
    python-annoy \
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
    tensorflow \
    tensorflow-probability \
    bioconductor-deseq2 \
    bioconductor-vsn \
    loompy \
    llvmlite \
    setuptools_scm \
    scikit-misc \
    r-biocmanager \
    bioconductor-scran \
    bioconductor-dropletutils \
    bioconductor-fishpond \
    vpolo \
    pyroe 


#mamba clean -ai

#RUN pip --no-cache-dir install \
#    fa2 \
#    magic-impute 

#RUN pip install git+https://github.com/DmitryUlyanov/Multicore-TSNE.git

#RUN mamba install --quiet --yes -c conda-forge rust setuptools-rust
#RUN pip install git+https://github.com/k3yavi/vpolo.git

#RUN pip install git+https://github.com/theislab/scanpy
RUN pip install llvmlite==0.37 --ignore-installed
RUN pip install  git+https://github.com/theislab/batchglm@v0.7.4
RUN pip install git+https://github.com/theislab/diffxpy@v0.7.4
#RUN pip install git+https://github.com/theislab/anndata2ri
#RUN pip install git+https://github.com/theislab/scvelo
#RUN pip install git+https://github.com/theislab/cellrank

#RUN pip install git+https://github.com/KrishnaswamyLab/MAGIC.git#subdirectory=python
#RUN pip --no-cache-dir install dca

RUN R --slave -e "BiocManager::install('GenomeInfoDb', force=TRUE)"

ENV OMPI_MCA_opal_cuda_support true