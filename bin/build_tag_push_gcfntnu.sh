#!/bin/bash
# Build, tag and push the image of the current directory as gcfntnu/<directory>:<tag>, then the same
# for each directory listed in dependencies.txt. Pushes only that tag: never :latest or other local
# tags of the image. See the gcf-docker README.
#
# Runs plain `docker`, as a member of the docker group, and pushes with your own `docker login`.
# Set DOCKER to use another command, e.g. DOCKER="sudo docker" (sudo then uses root's login).
set -euo pipefail

if [ "$#" -lt 1 ] ;
then
    echo -e "Tag required as positional argument. Usage:\n" \
    "build_tag_push_gcfntnu.sh tag"
    exit 1
fi

TAG=$1
REPO=$(basename "$(pwd)")
read -r -a DOCKER <<< "${DOCKER:-docker}"

run() {  # print the command exactly as it is run, then run it
    echo "$*"
    "$@"
}

run "${DOCKER[@]}" build -t "gcfntnu/$REPO:$TAG" --no-cache --progress=plain . 2>&1 | tee build.log
run "${DOCKER[@]}" push "gcfntnu/$REPO:$TAG"

if test -f dependencies.txt; then
    while read -r line || [[ -n $line ]]; do
        [[ -n $line ]] || continue
        run "${DOCKER[@]}" build "../$line" -t "gcfntnu/$line:$TAG" --no-cache --progress=plain 2>&1 \
            | tee docker_dependencies_build.log
        run "${DOCKER[@]}" push "gcfntnu/$line:$TAG"
    done < dependencies.txt
fi
