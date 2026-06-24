FROM gcfntnu/python-base-conda:3.11

COPY env.yml .

# REMEMBER TO PIN PYTHON VER IN ENV FILE ON UPDATE!
RUN mamba env update --name base --yes  --file env.yml

RUN conda clean -afy \
    && find /opt/conda/ -follow -type f -name '*.a' -delete \
    && find /opt/conda/ -follow -type f -name '*.pyc' -delete \
    && find /opt/conda/ -follow -type f -name '*.js.map' -delete

