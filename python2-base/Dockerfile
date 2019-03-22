FROM python:2.7-slim

RUN apt-get update -qq && apt-get -y --no-install-recommends install \
    build-essential \
    git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN python2 -m pip install --no-cache-dir --upgrade pip && \
    python2 -m pip install --no-cache-dir --upgrade pandas argparse numexpr bottleneck scipy pyarrow jinja2 beautifulsoup4 lxml xlrd xlwt blosc matplotlib cython