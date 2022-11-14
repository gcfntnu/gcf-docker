FROM gcfntnu/python-base-conda:4.10.3


RUN mamba install --yes subread

WORKDIR /opt
COPY MGcount /opt/MGcount
RUN cd MGcount && pip3 install .

