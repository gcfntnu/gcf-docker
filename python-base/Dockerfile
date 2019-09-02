FROM python:3.7-slim

RUN apt-get update -qq && apt-get -y --no-install-recommends install \
    build-essential \
    git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --no-cache-dir --upgrade pip && \
    python3 -m pip install --no-cache-dir --upgrade pandas pyyaml argparse numexpr bottleneck scipy pyarrow jinja2 beautifulsoup4 lxml xlrd xlwt blosc matplotlib cython