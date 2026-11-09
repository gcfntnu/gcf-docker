#!/bin/bash
# Build, tag and push the image of the current directory as gcfntnu/<directory>:<tag> and :latest,
# then the same for each directory listed in dependencies.txt. Pushes only these two tags, never
# other local tags of the image. See the gcf-docker README.
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

run "${DOCKER[@]}" build -t "gcfntnu/$REPO:$TAG" -t "gcfntnu/$REPO:latest" --no-cache --progress=plain . 2>&1 | tee build.log
run "${DOCKER[@]}" push "gcfntnu/$REPO:$TAG"
run "${DOCKER[@]}" push "gcfntnu/$REPO:latest"

if test -f dependencies.txt; then
    while read -r line || [[ -n $line ]]; do
        [[ -n $line ]] || continue
        run "${DOCKER[@]}" build "../$line" -t "gcfntnu/$line:$TAG" -t "gcfntnu/$line:latest" --no-cache --progress=plain 2>&1 \
            | tee docker_dependencies_build.log
        run "${DOCKER[@]}" push "gcfntnu/$line:$TAG"
        run "${DOCKER[@]}" push "gcfntnu/$line:latest"
    done < dependencies.txt
fi
