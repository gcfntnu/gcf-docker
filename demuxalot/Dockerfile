FROM gcfntnu/python-base-conda:23.10.0-1

#COPY env.yml .
#RUN conda env update --name base --prune --file env.yml

RUN pip install --no-cache-dir git+https://github.com/herophilus/demuxalot.git
RUN pip install --no-cache-dir argparse matplotlib

RUN conda clean -afy \
    && find /opt/conda/ -follow -type f -name '*.a' -delete \
    && find /opt/conda/ -follow -type f -name '*.pyc' -delete \
    && find /opt/conda/ -follow -type f -name '*.js.map' -delete

