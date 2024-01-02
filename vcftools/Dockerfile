FROM gcfntnu/python-base-conda:23.10.0-1


RUN mamba install -y python=3.9 pandas samtools bcftools tabix vcftools

RUN conda clean -afy \
    && find /opt/conda/ -follow -type f -name '*.a' -delete \
    && find /opt/conda/ -follow -type f -name '*.pyc' -delete \
    && find /opt/conda/ -follow -type f -name '*.js.map' -delete