FROM gcfntnu/python-base-conda:3.11

COPY env.yml .

# REMEMBER TO PIN PYTHON VER IN ENV FILE ON UPDATE!
RUN conda env update --name base --file env.yml

RUN apt-get update && \
    apt-get install --yes --no-install-recommends libgomp1 && \
    rm -rf /var/lib/apt/lists/*

RUN conda clean -afy \
    && find /opt/miniconda3/ -follow -type f -name '*.a' -delete \
    && find /opt/miniconda3/ -follow -type f -name '*.pyc' -delete \
    && find /opt/miniconda3/ -follow -type f -name '*.js.map' -delete

