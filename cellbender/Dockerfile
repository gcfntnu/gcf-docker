FROM nvcr.io/nvidia/pytorch:22.05-py3

WORKDIR /opt
ENV DOCKER='true'
RUN git clone https://github.com/broadinstitute/CellBender.git
RUN pip install --no-cache-dir -e CellBender