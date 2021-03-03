FROM gcfntnu/scanpy:1.7.0

RUN mamba install -y -q jupyterlab

RUN mkdir /tmp/work

WORKDIR /tmp/work

CMD jupyter-lab --allow-root --port 9999 --no-browser 
