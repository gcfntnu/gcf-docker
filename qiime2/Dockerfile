FROM qiime2/core:2019.10

RUN conda update conda

RUN /bin/bash -c "source activate /opt/conda/envs/qiime2-2019.10 && \
    conda config --add channels defaults && \
    conda config --add channels bioconda && \
    conda config --add channels conda-forge && \
    conda install mamba && \
    mamba update --all"

RUN /bin/bash -c "source activate /opt/conda/envs/qiime2-2019.10 && mamba install -y r-argparse seqkit cutadapt deicode"

RUN /bin/bash -c "source activate /opt/conda/envs/qiime2-2019.10 && mamba install -y q2-longitudinal=2019.10"

COPY install_qiime2R.sh .
RUN /bin/bash -c "source activate /opt/conda/envs/qiime2-2019.10 && ./install_qiime2R.sh"

COPY install_picrust2.sh .
RUN /bin/bash -c "source activate /opt/conda/envs/qiime2-2019.10 && ./install_picrust2.sh"

