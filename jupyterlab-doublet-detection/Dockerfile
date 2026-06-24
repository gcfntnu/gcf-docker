FROM gcfntnu/doublet-detection:latest

RUN conda install -y -q jupyterlab pip notebook snakemake nbformat ipykernel r-irkernel matplotlib seaborn adjusttext upsetplot

RUN pip install marsilea mpl_fontkit

RUN mkdir /tmp/work

WORKDIR /tmp/work

CMD jupyter-lab --allow-root --port 8888 --no-browser 
