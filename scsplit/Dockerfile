FROM gcfntnu/python-base-conda:4.9.2

RUN mamba install --quiet --yes \
    numpy \
    scipy \
    pandas \
    pysam \
    scikit-learn \
    pyvcf \
    pip && \
    mamba clean --all

WORKDIR /opt
RUN git clone https://github.com/jon-xu/scSplit.git
RUN chmod +x scSplit/scSplit
RUN cp scSplit/scSplit /usr/local/bin