#!/usr/bin/env bash
# unitas.pl in gcfntnu/unitas:1.9.2-<n>: run upstream UNITAS 1.9.2 with the image's SeqMap.
#
# UNITAS 1.9.2 runs ./seqmap.exe from the working directory and, when it is missing, downloads the
# SeqMap source and compiles it there. Link the image's build (SeqMap 1.0.13) in first so runs stay
# offline; a seqmap.exe already in the working directory is left alone.
set -euo pipefail

if [[ ! -e seqmap.exe ]]; then
    ln -s /opt/unitas/seqmap.exe seqmap.exe 2>/dev/null \
        || echo "unitas.pl: could not link /opt/unitas/seqmap.exe into $PWD" >&2
fi
exec perl /opt/unitas/unitas_1.9.2.pl "$@"
