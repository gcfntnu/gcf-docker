FROM ghcr.io/scverse/rapids-singlecell-cu12:v0.17.0

ENV CONDA_PREFIX=/opt/conda
ENV PATH=/opt/conda/bin:$PATH

RUN /opt/conda/bin/python -m pip install --no-cache-dir \
    celltypist==1.7.1 \  
    pyarrow \
    dask \
    distributed \
    psutil