FROM gcfntnu/python-base-conda:3.12
ARG SAMBAMBA_VER=1.0.1
ENV DEBIAN_FRONTEND=noninteractive

# Optional: strip defaults from system condarc to avoid surprises
RUN conda config --system --remove-key default_channels || true && \
    conda config --system --set channel_priority strict

# Key fix: use ONLY conda-forge/bioconda for this transaction
RUN conda install -y \
      -c conda-forge -c bioconda --override-channels \
      sambamba=${SAMBAMBA_VER} samtools pysam pandas \
 && conda clean -afy
