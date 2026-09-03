FROM gcfntnu/scanpy:1.12.3

ENV R_HOME=/opt/miniconda3/lib/R

RUN apt-get update && apt-get install --yes --no-install-recommends \
    g++ make pkg-config libcurl4-openssl-dev libssl-dev libxml2-dev libgit2-dev \
    libfontconfig1-dev libfreetype6-dev libfribidi-dev libharfbuzz-dev \
    libpng-dev libtiff-dev pandoc && \
    rm -rf /var/lib/apt/lists/*

RUN conda install --override-channels -c conda-forge -c bioconda --quiet --yes \
    r-base rpy2 r-biocmanager r-argparse r-data.table r-igraph r-remotes \
    bioconductor-genomeinfodb bioconductor-genomeinfodbdata \
    bioconductor-deseq2 bioconductor-edger bioconductor-limma \
    bioconductor-vsn bioconductor-scran bioconductor-dropletutils \
    bioconductor-singlecellexperiment bioconductor-summarizedexperiment && \
    conda clean --all --yes

RUN pip install --no-cache-dir \
    anndata2ri decoupler triku \
    git+https://gitlab.com/georgy.m/conorm.git \
    marsilea piecewise-regression robustbase \
    git+https://github.com/IlyaLab/gssnng.git

ARG SCHARD_COMMIT=f9c30c25a192175a1e6523e32f0e2047de1e8685
RUN Rscript -e "remotes::install_github(\"cellgeni/schard@${SCHARD_COMMIT}\", dependencies=FALSE, upgrade=\"never\")"

RUN python -c "import scanpy, scvelo, rpy2, anndata2ri, decoupler; print(scanpy.__version__)" && \
    Rscript -e "pkgs <- c(\"DESeq2\", \"edgeR\", \"scran\", \"schard\"); print(setNames(vapply(pkgs, requireNamespace, logical(1), quietly=TRUE), pkgs))"
