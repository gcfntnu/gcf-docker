FROM qiime2/core:2020.8

RUN conda update conda

RUN /bin/bash -c "source activate /opt/conda/envs/qiime2-2020.8 && \
    conda config --add channels defaults && \
    conda config --add channels bioconda && \
    conda config --add channels conda-forge && \
    conda install mamba && \
    mamba update --all"

RUN /bin/bash -c "source activate /opt/conda/envs/qiime2-2020.8 && mamba install -y r-argparse seqkit cutadapt deicode"

RUN /bin/bash -c "source activate /opt/conda/envs/qiime2-2020.8 && mamba install -y -c conda-forge -c bioconda -c qiime2 -c defaults q2-longitudinal qiime2 q2cli q2templates q2-types q2-longitudinal q2-feature-classifier xmltodict"

COPY install_qiime2R.sh .
RUN /bin/bash -c "source activate /opt/conda/envs/qiime2-2020.8 && ./install_qiime2R.sh"

COPY install_picrust2.sh .
RUN /bin/bash -c "source activate /opt/conda/envs/qiime2-2020.8 && ./install_picrust2.sh"

RUN pip install git+https://github.com/bokulich-lab/RESCRIPt.git