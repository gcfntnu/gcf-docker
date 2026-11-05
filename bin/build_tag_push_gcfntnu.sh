#!/bin/bash
set -euo pipefail

if [ "$#" -lt 1 ] ;
then
    echo -e "Tag required as positional argument. Usage:\n" \
    "build_tag_push_gcfntnu.sh tag"
    exit 1
fi

TAG=$1
REPO=$(basename $(pwd))

echo "sudo docker build . -t gcfntnu/$REPO:$TAG -t gcfntnu/$REPO:latest --progress=plain"
sudo docker build -t gcfntnu/$REPO:$TAG -t gcfntnu/$REPO:latest --no-cache --progress=plain .  2>&1 | tee build.log
echo "sudo docker push --all-tags gcfntnu/$REPO" 
sudo docker push --all-tags gcfntnu/$REPO


if test -f dependencies.txt; then
    cat dependencies.txt | while read line || [[ -n $line ]];
    do
       echo "sudo docker build ../$line -t $line:$TAG -t $line:latest --progress=plain"
       sudo docker build ../$line -t gcfntnu/$line:$TAG -t gcfntnu/$line:latest --no-cache --progress=plain  2>&1 | tee docker_dependencies_build.log
       echo "sudo docker push --all-tags gcfntnu/$line"
       sudo docker push --all-tags gcfntnu/$line
    done
fi
