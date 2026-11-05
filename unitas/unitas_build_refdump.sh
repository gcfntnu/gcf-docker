#!/usr/bin/env bash
# Build UNITAS_refdump_<species> from primary sources, without the defunct smallRNAgroup server.
#
# Downloaded (pinned per run):  Ensembl ncRNA + cDNA (cdna.all), GtRNAdb tRNAs, miRBase mature +
#                               hairpin (current release).
# Reused from an existing dump: piRNA clusters (piRclDB), tRF-1, tRNA leaders, SILVA SSU/LSU.
#                               These were only ever served by the smallRNAgroup server.
#
# The sources are placed in a local mirror of the old server layout and processed by unitas' own
# -refdump code (unitas.pl -mirror), so the files are formatted exactly as UNITAS expects.
# Before that, unitas_normalize_hairpin.awk strips a record's own species prefix from the miRBase
# hairpin names (hsa-miR-13167 -> miR-13167); the renamed names are listed in
# gcf_hairpin_renamed.tsv in the dump.
#
# Usage: unitas_build_refdump.sh --species NAME --static-dir DIR --ensembl-release N --outdir DIR
#                                [--mirbase-release X] [--workdir DIR] [--keep-raw]
#   --species          homo_sapiens | mus_musculus | rattus_norvegicus
#   --static-dir       existing UNITAS_refdump_<species> to take the static files from
#   --ensembl-release  Ensembl release to download, e.g. 116
#   --outdir           writes UNITAS_refdump_<species>/ and UNITAS_refdump_<species>.tar.gz here
#   --mirbase-release  release label for db_versions.info (default: read from www.mirbase.org)
#   --keep-raw         keep the raw downloads (ensembl_ncRNA, ensembl_cDNA, miRBase_hairpin) in
#                      the dump; UNITAS only reads them while building the dump
set -euo pipefail

species= static= ensembl= outdir= mirbase_release= workdir= keep_raw=0
while (( $# )); do
    case $1 in
        --species) species=$2; shift 2 ;;
        --static-dir) static=$2; shift 2 ;;
        --ensembl-release) ensembl=$2; shift 2 ;;
        --outdir) outdir=$2; shift 2 ;;
        --mirbase-release) mirbase_release=$2; shift 2 ;;
        --workdir) workdir=$2; shift 2 ;;
        --keep-raw) keep_raw=1; shift ;;
        -h|--help) sed -n '2,24p' "$0"; exit 0 ;;
        *) echo "unitas_build_refdump: unknown argument $1" >&2; exit 2 ;;
    esac
done
die() { echo "unitas_build_refdump: $*" >&2; exit 1; }
normalize_awk=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/unitas_normalize_hairpin.awk
[[ -r $normalize_awk ]] || die "missing $normalize_awk"
for name in species static ensembl outdir; do
    [[ -n ${!name} ]] || die "--${name/ensembl/ensembl-release} is required (see --help)"
done
[[ $ensembl =~ ^[0-9]+$ ]] || die "--ensembl-release must be a number, got $ensembl"

# Ensembl species name and assembly, GtRNAdb genome. GtRNAdb has no rat GRCr8 (rn8) build; rn7 is
# the newest.
case $species in
    homo_sapiens)      ens_name=Homo_sapiens;      ens_asm=GRCh38; gtrnadb=Hsapi38/hg38 ;;
    mus_musculus)      ens_name=Mus_musculus;      ens_asm=GRCm39; gtrnadb=Mmusc39/mm39 ;;
    rattus_norvegicus) ens_name=Rattus_norvegicus; ens_asm=GRCr8;  gtrnadb=Rnorv7/rn7 ;;
    *) die "unsupported species $species (homo_sapiens, mus_musculus, rattus_norvegicus)" ;;
esac

for f in piRclDB tRF-1.fas tRNA_leader.fas SILVA_rRNA.SSU SILVA_rRNA.LSU db_versions.info; do
    [[ -s $static/$f ]] || die "static dump $static has no $f"
done
static_version() {  # value of a db_versions.info line, without "Release " and " (dd.mm.yyyy)"
    sed -n "s/^$1[^.]*\\.\\.* *//p" "$static/db_versions.info" | sed 's/ (dd\.mm\.yyyy)$//; s/^Release //' | head -1
}
pirc_date=$(static_version 'piRNA cluster database')
trf1_date=$(static_version 'tRF-1 sequence data')
leader_date=$(static_version 'tRNA-leader sequence data')
silva_release=$(static_version 'SILVA rRNA (SSU) database')
[[ -n $pirc_date && -n $trf1_date && -n $leader_date && -n $silva_release ]] \
    || die "could not read static data versions from $static/db_versions.info"

if [[ -z $mirbase_release ]]; then
    mirbase_release=$(curl -fsSL --retry 3 https://www.mirbase.org/ | grep -oE 'Version [0-9]+(\.[0-9]+)?' | head -1 | cut -d' ' -f2 || true)
    [[ -n $mirbase_release ]] || die "could not read the miRBase release from www.mirbase.org; use --mirbase-release"
fi

mkdir -p "$outdir"
outdir=$(cd "$outdir" && pwd)
static=$(cd "$static" && pwd)
if [[ -z $workdir ]]; then workdir=$(mktemp -d); trap 'rm -rf "$workdir"' EXIT; fi
mkdir -p "$workdir"
workdir=$(cd "$workdir" && pwd)
mirror=$workdir/mirror
src=$mirror/src
U=$mirror/data/UNITAS
rm -rf "$mirror" "$workdir/run"
mkdir -p "$src" "$U/URLs" "$U/tRF-1" "$U/tRNA_leader" "$U/SILVA_rRNA" "$U/SeqMap" "$workdir/run"

sources=$workdir/gcf_sources.tsv
printf 'file\turl\tsha256\tretrieved\n' > "$sources"
fetch() {  # url output [kind]; checks that FASTA downloads really are FASTA (not an error page)
    local url=$1 out=$2 kind=${3:-}
    echo "download $url"
    curl -fsSL --retry 3 -o "$out.part" "$url" || die "download failed: $url"
    case $kind in
        fasta) [[ $(head -c1 "$out.part") == '>' ]] || die "not FASTA: $url" ;;
        fasta.gz) [[ $(gzip -dc "$out.part" | head -c1) == '>' ]] || die "not gzipped FASTA: $url" ;;
    esac
    mv "$out.part" "$out"
    printf '%s\t%s\t%s\t%s\n' "$(basename "$out")" "$url" "$(sha256sum "$out" | cut -d' ' -f1)" \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$sources"
}

ens_base=https://ftp.ensembl.org/pub/release-$ensembl/fasta/$species
ncrna=$ens_name.$ens_asm.ncrna.fa.gz
cdna=$ens_name.$ens_asm.cdna.all.fa.gz
trna=$(basename "$gtrnadb")-tRNAs.fa
fetch "$ens_base/ncrna/$ncrna" "$src/$ncrna" fasta.gz
fetch "$ens_base/cdna/$cdna" "$src/$cdna" fasta.gz
fetch "https://gtrnadb.ucsc.edu/genomes/eukaryota/$gtrnadb-tRNAs.fa" "$src/$trna" fasta
for f in mature hairpin; do
    fetch "https://www.mirbase.org/download/$f.fa" "$src/$f.fa" fasta
done
# UNITAS names species hairpins from the header's name field; strip the record's own species
# prefix there so that all miRNAs are reported without it (gcfntnu/gcf-docker#8).
renamed=$workdir/gcf_hairpin_renamed.tsv
awk -v report="$renamed" -f "$normalize_awk" "$src/hairpin.fa" > "$src/hairpin.fa.normalized" 2> "$workdir/normalize.log" \
    || die "hairpin normalization failed: $(cat "$workdir/normalize.log")"
awk -v mode=check -f "$normalize_awk" "$src/hairpin.fa.normalized" > "$workdir/normalize.check" \
    || die "hairpin names still carry their own species prefix: $(head -3 "$workdir/normalize.check")"
mv "$src/hairpin.fa.normalized" "$src/hairpin.fa"
normalize_note="gcf: stripped the own species prefix from $(wc -l < "$renamed") miRBase hairpin names (gcf_hairpin_renamed.tsv)"
echo "$normalize_note"
printf '%s\t%s\t%s\t%s\n' "hairpin.fa" "gcf:unitas_normalize_hairpin.awk" \
    "$(sha256sum "$src/hairpin.fa" | cut -d' ' -f1)" "NA" >> "$sources"
for f in mature hairpin; do
    gzip -n "$src/$f.fa"
done

# Static data from the existing dump, in the layout of the old server
cp "$static/piRclDB" "$src/piRNAclusters.fasta"
cp "$static/tRF-1.fas" "$U/tRF-1/$species.tRF-1.fas"
cp "$static/tRNA_leader.fas" "$U/tRNA_leader/$species.tRNA_leader.fas"
cp "$static/SILVA_rRNA.SSU" "$U/SILVA_rRNA/SILVA_SSU_$species.fasta"
cp "$static/SILVA_rRNA.LSU" "$U/SILVA_rRNA/SILVA_LSU_$species.fasta"
printf '%s' "$trf1_date" > "$U/tRF-1/release"
printf '%s' "$leader_date" > "$U/tRNA_leader/release"
printf '%s' "$silva_release" > "$U/SILVA_rRNA/release"
printf 'NA' > "$U/SeqMap/release"
for f in piRclDB tRF-1.fas tRNA_leader.fas SILVA_rRNA.SSU SILVA_rRNA.LSU; do
    printf '%s\t%s\t%s\t%s\n' "$f" "static:$static/$f" "$(sha256sum "$static/$f" | cut -d' ' -f1)" "NA" >> "$sources"
done

# URL tables (Perl, evaluated by unitas as on the old server)
cat > "$U/URLs/gtRNAdb" <<EOF
%gtRNAdb_urls=('$species'=>'file://$src/$trna');
\$miRBase_mature='file://$src/mature.fa.gz';
\$miRBase_hairpin='file://$src/hairpin.fa.gz';
\$miRBase_release='Release $mirbase_release';
\$ensembl_release='$ensembl';
\$ensemblgenomes_release='NA';
\$piRclDB_date='$pirc_date';
EOF
echo "%piRclDB_urls=('$species'=>'file://$src/piRNAclusters.fasta');" > "$U/URLs/piRclDB"
echo "%ensembl_ncRNA=('$species'=>'file://$src/$ncrna');" > "$U/URLs/Ensembl_ncRNA"
echo "%ensembl_cDNA=('$species'=>'file://$src/$cdna');" > "$U/URLs/Ensembl_cDNA"

echo "build UNITAS_refdump_$species (Ensembl $ensembl $ens_asm, GtRNAdb $(basename "$gtrnadb"), miRBase $mirbase_release)"
log=$workdir/run/refdump.log
if ! (cd "$workdir/run" && unitas.pl -refdump -species "$species" -mirror "$mirror" > "$log" 2>&1) \
        || grep -q 'ERROR' "$log"; then
    tail -n 30 "$log" >&2
    die "unitas -refdump failed for $species (log: $log)"
fi

dump=$workdir/run/UNITAS_refdump_$species
case $species in
    homo_sapiens) org=Human code=hsa ;; mus_musculus) org=Mouse code=mmu ;; rattus_norvegicus) org=Rat code=rno ;;
esac
for f in db_versions.info ncRNA.fas cDNA.fas tRF-1.fas tRNA_leader.fas miRBase_mature piRclDB \
         "miRBase_hairpin_$org.fas" "miRBase_hairpin_non-$org.fas"; do
    [[ -s $dump/$f ]] || die "dump is missing $f"
done
# Species hairpins are named from the normalized header; none may keep the species prefix.
# (miRBase_hairpin_non-$org.fas is named from the record IDs, which always carry a prefix.)
if grep -q "^>$code-" "$dump/miRBase_hairpin_$org.fas"; then
    die "miRBase_hairpin_$org.fas has $code- names: $(grep "^>$code-" "$dump/miRBase_hairpin_$org.fas" | head -3 | tr '\n' ' ')"
fi
if (( ! keep_raw )); then
    rm -f "$dump/ensembl_ncRNA" "$dump/ensembl_cDNA" "$dump/miRBase_hairpin"
fi
cp "$sources" "$dump/gcf_sources.tsv"
cp "$renamed" "$dump/gcf_hairpin_renamed.tsv"
cp "$log" "$dump/gcf_refdump.log"
echo "$normalize_note" >> "$dump/gcf_refdump.log"

rm -rf "$outdir/UNITAS_refdump_$species" "$outdir/UNITAS_refdump_$species.tar.gz"
tar --sort=name --owner=0 --group=0 --numeric-owner --mtime='1970-01-01' \
    -C "$workdir/run" -czf "$outdir/UNITAS_refdump_$species.tar.gz" "UNITAS_refdump_$species"
mv "$dump" "$outdir/"
echo "done: $outdir/UNITAS_refdump_$species.tar.gz"
cat "$outdir/UNITAS_refdump_$species/db_versions.info"
