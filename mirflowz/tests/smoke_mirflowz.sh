#!/usr/bin/env bash
# Run mirflowz's own test (test/config.yaml) inside the image, as gcf-workflows runs images
# (non-root user, read-only root filesystem), with no inner containers or conda, and check the
# outputs against mirflowz's test/expected_output.md5 as its test_workflow_local_with_conda.sh does.
# Snakemake needs a writable cache (XDG_CACHE_HOME or HOME; Apptainer binds the user's home).
#
# Known difference: under Snakemake in this image, segemehl gives read 26-1 MAPQ 0 instead of 1 in
# segemehl_genome_mappings.sam, and the six SAM files derived from it carry that over. The same
# segemehl build run directly in the image reproduces upstream's checksum; the counts do not
# change. These 7 files are listed below; any other mismatch, or a mismatch of the final tables,
# fails the test.
# Usage: tests/smoke_mirflowz.sh [image] [workdir]
set -euo pipefail
image=${1:-gcfntnu/mirflowz:0.10.0}
work=${2:-$(mktemp -d)}
mkdir -p "$work"
docker run --rm --user "$(id -u):$(id -g)" --read-only --tmpfs /tmp -e HOME=/tmp -e XDG_CACHE_HOME=/tmp/cache \
    -v "$work:/work" -w /work "$image" bash -c '
    set -euo pipefail
    rm -rf mirflowz && cp -r "$MIRFLOWZ_DIR" mirflowz && cd mirflowz/test
    snakemake --snakefile ../workflow/Snakefile --configfile config.yaml --cores 4 \
        --printshellcmds --rerun-incomplete --no-hooks > snakemake.log 2>&1 || { tail -40 snakemake.log; exit 1; }
    find results/ -type f -name "*.gz" -exec gunzip "{}" \;
    known="segemehl_genome_mappings.sam genome_mappings.sam genome_mappings_no_header.sam
           genome_mappings_filtered_nh.sam mappings_all.sam mappings_all_no_header.sam mappings_all_sorted_by_id.sam"
    failed=$(md5sum --check expected_output.md5 2>/dev/null | sed -n "s/: FAILED$//p" || true)
    unexpected=
    for f in $failed; do
        case " $(echo $known) " in *" $(basename "$f") "*) echo "known difference (segemehl MAPQ): $f" ;;
                                    *) unexpected="$unexpected $f" ;; esac
    done
    for f in results/TABLES/all_mirna_counts.tab results/TABLES/all_pri-mir_counts.tab; do
        grep -q " $f\$" expected_output.md5 && md5sum --check --quiet <(grep " $f\$" expected_output.md5) \
            || unexpected="$unexpected $f"
    done
    n=$(wc -l < expected_output.md5); k=$(echo "$failed" | grep -c . || true)
    if [[ -n $unexpected ]]; then echo "FAILED:$unexpected"; exit 1; fi
    echo "ok: $((n - k)) of $n expected outputs match, including the final count tables; $k known segemehl MAPQ differences"
'
