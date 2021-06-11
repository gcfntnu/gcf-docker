#!/bin/bash

sudo docker run -v $(pwd):/tmp/work --net=host gcfntnu/gcf-bio:1.0
