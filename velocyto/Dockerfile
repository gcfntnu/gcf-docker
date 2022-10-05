FROM gcfntnu/python-base-conda:4.9.2

RUN mamba install --quiet --yes \
 loompy \
 scanpy \
 velocyto.py \
 samtools \
 scvelo &&\
 mamba clean --all

# Install dependencies using pip
# RUN pip install -U --no-deps velocyto scvelo
