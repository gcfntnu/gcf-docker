FROM gcfntnu/python-base-conda:23.10.0-1

COPY env.yml .
RUN conda env update --name base --prune --file env.yml

RUN conda clean -afy \
    && find /opt/conda/ -follow -type f -name '*.a' -delete \
    && find /opt/conda/ -follow -type f -name '*.pyc' -delete \
    && find /opt/conda/ -follow -type f -name '*.js.map' -delete

