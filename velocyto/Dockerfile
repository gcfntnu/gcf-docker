FROM gcfntnu/python-base-conda:4.10.3

RUN mamba install --quiet --yes \
 loompy \
 scanpy \

 velocyto.py=0.17.17 \
 scvelo &&\
 mamba clean --all

# Install dependencies using pip
# RUN pip install -U --no-deps velocyto scvelo

