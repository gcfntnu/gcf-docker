FROM gcfntnu/python2-base-conda:2.7


RUN conda install -y pip wheel bowtie samtools cutadapt viennarna pigz matplotlib pandas biopython numpy=1.15.1 scipy scikit-learn reportlab forgi

WORKDIR /opt
ADD https://api.github.com/repos/flatberg/miRge/git/refs/heads/master version.json
RUN git clone https://github.com/flatberg/miRge.git
RUN cd miRge && \
    rm ./dist/* && \
    python setup.py bdist_wheel && \
    pip install ./dist/mirge-2.0-py2-none-any.whl &&\
    rm -rf /opt/miRge