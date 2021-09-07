FROM gcfntnu/python-base-conda:4.8.2

RUN conda install --yes --quiet -c bioconda cvxopt datrie fasttree iqtree mafft opencv pandas psutil python=3.6* nodejs=10 raxml vcftools git pip 

RUN pip install awscli nextstrain-augur nextstrain-cli rethinkdb==2.3.0.post6 snakemake==5.26.1
ENV NPM_CONFIG_PREFIX=/root/.npm-global
RUN npm install --global auspice

