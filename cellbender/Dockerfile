FROM us.gcr.io/broad-dsde-methods/cellbender:0.3.2

WORKDIR /opt
# fix https://github.com/broadinstitute/CellBender/issues/296
# https://github.com/lukabor/CellBender/commit/4334e8966217c3591bf7c545f31ab979cdc6590d

RUN pip install --no-cache-dir -U git+https://github.com/broadinstitute/CellBender.git@4334e8966217c3591bf7c545f31ab979cdc6590d

RUN pip install --no-cache-di pandas numpy scipy scanpy anndata