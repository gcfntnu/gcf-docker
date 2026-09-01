FROM gcfntnu/python-base-conda:3.12

ENV CELL_TYPE_MAPPER_VER=v1.7.4

RUN conda install --yes git && \
    conda clean -afy

RUN pip install --no-cache-dir \
    "cell_type_mapper @ git+https://github.com/AllenInstitute/cell_type_mapper@${CELL_TYPE_MAPPER_VER}"