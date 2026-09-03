FROM gcfntnu/python-base-conda:3.12

ENV SCANPY_VER=1.12.3

RUN apt-get update && apt-get install --yes --no-install-recommends g++ cmake make && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir "scanpy[bbknn,dask,dask-ml,harmony,leiden,louvain,magic,paga,plotting,scanorama,scrublet,skmisc]==${SCANPY_VER}" scvelo
RUN python -c "import scanpy as sc, scvelo; assert sc.__version__ == \"1.12.3\"; print(sc.__version__, scvelo.__version__)"