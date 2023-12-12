FROM  nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH /opt/conda/bin:$PATH

RUN apt-get update --fix-missing && \
    apt-get install -y \
    git \
    wget \
    bzip2 \
    ca-certificates \
    curl git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-4.5.11-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    /opt/conda/bin/conda clean -tipsy && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc

ENV TINI_VERSION v0.16.1
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +x /usr/bin/tini

ENTRYPOINT [ "/usr/bin/tini", "--" ]
CMD [ "/bin/bash" ]

RUN conda update conda
RUN conda config --add channels defaults && \
    conda config --add channels bioconda && \
    conda config --add channels conda-forge && \
    conda update --all
RUN conda install --quiet --yes mamba && conda clean --all

RUN mamba install pytorch torchvision torchaudio torchmetrics=0.6 pytorch-cuda=11.8 pytorch-lightning=1.3.1 -c pytorch -c nvidia

RUN mamba install --yes \
pip \
jax \
jaxlib \
scvi-tools \
ConfigArgParse \
pandas \
seaborn \
tqdm \
scvi-tools \
leidenalg \
scanpy && \
mamba clean --all

RUN pip install git+https://github.com/calico/solo.git

