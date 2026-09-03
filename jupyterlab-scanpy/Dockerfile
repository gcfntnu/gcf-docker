FROM gcfntnu/scanpy:latest

RUN conda install -y -q jupyterlab pip notebook snakemake nbformat ipykernel r-irkernel papermill jupyterlab_code_formatter

RUN mkdir /tmp/work

WORKDIR /tmp/work

CMD jupyter-lab --allow-root --port 8888 --no-browser 
