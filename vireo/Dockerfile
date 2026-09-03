FROM gcfntnu/python-base-conda:3.12

RUN pip install --no-cache-dir \
    git+https://github.com/gcfntnu/vireo.git@67c2467 \
    threadpoolctl

RUN conda clean -afy \
    && find "$(conda info --base)/" -follow -type f -name '*.a' -delete \
    && find "$(conda info --base)/" -follow -type f -name '*.pyc' -delete \
    && find "$(conda info --base)/" -follow -type f -name '*.js.map' -delete

RUN vireo --help >/dev/null