FROM gcfntnu/python-base-conda:4.8.2

COPY assembly_qc.yaml /tmp/env.yaml

RUN mamba env update \
    -f /tmp/env.yaml && \
    mamba clean --all


