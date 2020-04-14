FROM qiime2/core:2019.10

RUN conda update conda

RUN /bin/bash -c "source activate /opt/conda/envs/qiime2-2019.10 && \
    conda config --add channels defaults && \
    conda config --add channels bioconda && \
    conda config --add channels conda-forge && \
    conda update --all"


RUN /bin/bash -c "source activate /opt/conda/envs/qiime2-2019.10 && conda install --force-reinstall biom-format"

RUN /bin/bash -c "source activate /opt/conda/envs/qiime2-2019.10 && conda install q2-longitudinal=2019.10"

RUN /bin/bash -c "source activate /opt/conda/envs/qiime2-2019.10 && conda install r-argparse"

COPY install_qiime2R.sh .
RUN /bin/bash -c "source activate /opt/conda/envs/qiime2-2019.10 && ./install_qiime2R.sh"

COPY install_picrust2.sh .
RUN /bin/bash -c "source activate /opt/conda/envs/qiime2-2019.10 && ./install_picrust2.sh"

RUN /bin/bash -c "source activate /opt/conda/envs/qiime2-2019.10 && conda install seqkit cutadapt deicode r-jsonlite"