FROM gcfntnu/scanpy:1.9.2

RUN mamba install -y -q jupyterlab snakemake nbformat

RUN mkdir /tmp/work

WORKDIR /tmp/work

CMD jupyter-lab --allow-root --port 9999 --no-browser 
