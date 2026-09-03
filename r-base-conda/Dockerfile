FROM gcfntnu/python-base-conda:3.12

ENV R_VER=4.5.3
ENV R_HOME=/opt/miniconda3/lib/R

RUN apt-get update && \
    apt-get install --yes --no-install-recommends libgomp1 && \
    rm -rf /var/lib/apt/lists/*

RUN conda install --quiet --yes \
    r-base=${R_VER} \
    r-biocmanager && \
    conda clean --all --yes
