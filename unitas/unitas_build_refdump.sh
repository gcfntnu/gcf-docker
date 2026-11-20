#!/usr/bin/env bash
# Build UNITAS_refdump_<species> from primary sources, without the defunct smallRNAgroup server.
#
# Downloaded (pinned per run):  Ensembl ncRNA + cDNA (cdna.all), GtRNAdb tRNAs, and the miRNAs:
#                               miRBase mature + hairpin, or MirGeneDB mature + star + precursors
#                               (--mirna-db). miRBase comes from the release-specific download
#                               (--mirbase-release); MirGeneDB from the current files, checked
#                               against --mirgenedb-release.
#                               piRNA clusters from piRNAclusterDB (www.pirnaclusterdb.org; the
#                               files are unchanged since the 2022 dumps), dated by download as
#                               UNITAS does.
#                               SILVA 132 SSURef/LSURef rRNA, md5-checked against SILVA's files and
#                               selected by the species' NCBI taxid (unitas_silva_species.awk):
#                               the records of the old server's SILVA files. Later SILVA releases
#                               do not fit (see the awk header).
# Reused from an existing dump: tRF-1 and tRNA leaders, which were only ever served by the
#                               smallRNAgroup server.
#
# The sources are placed in a local mirror of the old server layout and processed by unitas' own
# -refdump code (unitas.pl -mirror), so the files are formatted exactly as UNITAS expects.
# Before that, unitas_normalize_hairpin.awk strips a record's own species prefix from the miRBase
# hairpin names (hsa-miR-13167 -> miR-13167); the renamed names are listed in
# gcf_hairpin_renamed.tsv in the dump.
# The image's unitas.pl (unitas-1.8.0-6.patch) names Ensembl ncRNA records without a gene symbol by
# the transcript ID (lncRNA|ENST...-ENSG..., formerly with the FASTA '>') and a gene's further
# transcripts <symbol>-<gene>_(n) (formerly <symbol>-(n), which merged transcripts of genes sharing a
# symbol); the dump is rejected if either old form appears (gcfntnu/gcf-docker#56). The static
# tRF-1 and tRNA-leader names lose any '>' after their first character (rat: tRF-1_>#297).
#
# With --mirna-db mirgenedb, MirGeneDB takes miRBase's place: unitas_mirgenedb2mirbase.awk writes
# the MirGeneDB FASTA of all species in miRBase's header layout (mature and star sequences as the
# mature file, precursors as the hairpin file), so UNITAS reads them unchanged. It reports MirGeneDB
# genes without the species code, one name per arm (Let-7-P1b-5p, Let-7-P1b-3p; see the awk header
# for why not Let-7-P1b_3p*). The dump keeps the species' MirGeneDB
# GFF as gcf_mirgenedb.gff3 for annotation. UNITAS still labels the database "miRBase" in
# db_versions.info; gcf_mirna_db.tsv in the dump records which database was used.
#
# Usage: unitas_build_refdump.sh --species NAME --static-dir DIR --ensembl-release N --outdir DIR
#                                [--mirna-db mirbase|mirgenedb] [--mirbase-release X]
#                                [--mirgenedb-release X] [--workdir DIR] [--keep-raw]
#   --species          homo_sapiens | mus_musculus | rattus_norvegicus
#   --static-dir       existing UNITAS_refdump_<species> to take tRF-1 and tRNA leaders from
#   --ensembl-release  Ensembl release to download, e.g. 116
#   --outdir           writes UNITAS_refdump_<species>/ and UNITAS_refdump_<species>.tar.gz here
#   --mirna-db         miRNA database: mirbase (default) or mirgenedb
#   --mirbase-release  miRBase release to download, e.g. 23.1; required with --mirna-db mirbase
#                      (www.mirbase.org/download_version_files/<release>/)
#   --mirgenedb-release  MirGeneDB release, checked against the downloaded GFF
#                      (default: read from mirgenedb.org)
#   --keep-raw         keep the raw downloads (ensembl_ncRNA, ensembl_cDNA, miRBase_hairpin) in
#                      the dump; UNITAS only reads them while building the dump
set -euo pipefail

species= static= ensembl= outdir= mirbase_release= workdir= keep_raw=0 mirna_db=mirbase mirgenedb_release=
while (( $# )); do
    case $1 in
        --species) species=$2; shift 2 ;;
        --static-dir) static=$2; shift 2 ;;
        --ensembl-release) ensembl=$2; shift 2 ;;
        --outdir) outdir=$2; shift 2 ;;
        --mirna-db) mirna_db=$2; shift 2 ;;
        --mirbase-release) mirbase_release=$2; shift 2 ;;
        --mirgenedb-release) mirgenedb_release=$2; shift 2 ;;
        --workdir) workdir=$2; shift 2 ;;
        --keep-raw) keep_raw=1; shift ;;
        -h|--help) sed -n '2,51p' "$0"; exit 0 ;;
        *) echo "unitas_build_refdump: unknown argument $1" >&2; exit 2 ;;
    esac
done
die() { echo "unitas_build_refdump: $*" >&2; exit 1; }
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
normalize_awk=$here/unitas_normalize_hairpin.awk
silva_awk=$here/unitas_silva_species.awk
[[ -r $silva_awk ]] || die "missing $silva_awk"
mirgenedb_awk=$here/unitas_mirgenedb2mirbase.awk
mirgenedb_species=$here/mirgenedb_species.tsv
case $mirna_db in
    mirbase) [[ -r $normalize_awk ]] || die "missing $normalize_awk" ;;
    mirgenedb) for f in "$mirgenedb_awk" "$mirgenedb_species"; do [[ -r $f ]] || die "missing $f"; done ;;
    *) die "--mirna-db must be mirbase or mirgenedb, got $mirna_db" ;;
esac
for name in species static ensembl outdir; do
    [[ -n ${!name} ]] || die "--${name/ensembl/ensembl-release} is required (see --help)"
done
[[ $ensembl =~ ^[0-9]+$ ]] || die "--ensembl-release must be a number, got $ensembl"

# Ensembl species name and assembly, GtRNAdb genome, NCBI taxid (for SILVA). GtRNAdb has no rat
# GRCr8 (rn8) build; rn7 is the newest.
case $species in
    homo_sapiens)      ens_name=Homo_sapiens;      ens_asm=GRCh38; gtrnadb=Hsapi38/hg38; org=Human; code=hsa; taxid=9606 ;;
    mus_musculus)      ens_name=Mus_musculus;      ens_asm=GRCm39; gtrnadb=Mmusc39/mm39; org=Mouse; code=mmu; taxid=10090 ;;
    rattus_norvegicus) ens_name=Rattus_norvegicus; ens_asm=GRCr8;  gtrnadb=Rnorv7/rn7;   org=Rat;   code=rno; taxid=10116 ;;
    *) die "unsupported species $species (homo_sapiens, mus_musculus, rattus_norvegicus)" ;;
esac

for f in tRF-1.fas tRNA_leader.fas db_versions.info; do
    [[ -s $static/$f ]] || die "static dump $static has no $f"
done
static_version() {  # value of a db_versions.info line, without "Release " and " (dd.mm.yyyy)"
    sed -n "s/^$1[^.]*\\.\\.* *//p" "$static/db_versions.info" | sed 's/ (dd\.mm\.yyyy)$//; s/^Release //' | head -1
}
trf1_date=$(static_version 'tRF-1 sequence data')
leader_date=$(static_version 'tRNA-leader sequence data')
[[ -n $trf1_date && -n $leader_date ]] || die "could not read static data versions from $static/db_versions.info"
silva_release=132

# miRBase: always a pinned release. The unversioned download serves whatever is current, so a
# dump labelled with one release could contain another.
if [[ $mirna_db == mirbase ]]; then
    [[ -n $mirbase_release ]] || die "--mirbase-release is required with --mirna-db mirbase (e.g. 23.1)"
    [[ $mirbase_release =~ ^[0-9]+(\.[0-9]+)?$ ]] || die "--mirbase-release must look like 23.1, got $mirbase_release"
fi
if [[ $mirna_db == mirgenedb && -z $mirgenedb_release ]]; then
    mirgenedb_release=$(curl -fsSL --retry 3 https://mirgenedb.org/ | grep -oE 'MirGeneDB [0-9]+(\.[0-9]+)?' | head -1 | cut -d' ' -f2 || true)
    [[ -n $mirgenedb_release ]] || die "could not read the MirGeneDB release from mirgenedb.org; use --mirgenedb-release"
fi
case $mirna_db in
    mirbase) mirna_label="miRBase $mirbase_release" mirna_release_field="Release $mirbase_release" ;;
    mirgenedb) mirna_label="MirGeneDB $mirgenedb_release" mirna_release_field="MirGeneDB $mirgenedb_release" ;;
esac

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
fetch_md5() {  # url output [kind]: fetch, then check against the <url>.md5 that SILVA publishes
    local want
    fetch "$@"
    want=$(curl -fsSL --retry 3 "$1.md5" | cut -d' ' -f1) || die "download failed: $1.md5"
    [[ $(md5sum "$2" | cut -d' ' -f1) == "$want" ]] || die "md5 differs from $1.md5"
}

ens_base=https://ftp.ensembl.org/pub/release-$ensembl/fasta/$species
ncrna=$ens_name.$ens_asm.ncrna.fa.gz
cdna=$ens_name.$ens_asm.cdna.all.fa.gz
trna=$(basename "$gtrnadb")-tRNAs.fa
fetch "$ens_base/ncrna/$ncrna" "$src/$ncrna" fasta.gz
fetch "$ens_base/cdna/$cdna" "$src/$cdna" fasta.gz
fetch "https://gtrnadb.ucsc.edu/genomes/eukaryota/$gtrnadb-tRNAs.fa" "$src/$trna" fasta
renamed=$workdir/gcf_hairpin_renamed.tsv
if [[ $mirna_db == mirbase ]]; then
    for f in mature hairpin; do
        fetch "https://www.mirbase.org/download_version_files/$mirbase_release/$f.fa" "$src/$f.fa" fasta
    done
    # UNITAS names species hairpins from the header's name field; strip the record's own species
    # prefix there so that all miRNAs are reported without it (gcfntnu/gcf-docker#8).
    awk -v report="$renamed" -f "$normalize_awk" "$src/hairpin.fa" > "$src/hairpin.fa.normalized" 2> "$workdir/normalize.log" \
        || die "hairpin normalization failed: $(cat "$workdir/normalize.log")"
    awk -v mode=check -f "$normalize_awk" "$src/hairpin.fa.normalized" > "$workdir/normalize.check" \
        || die "hairpin names still carry their own species prefix: $(head -3 "$workdir/normalize.check")"
    mv "$src/hairpin.fa.normalized" "$src/hairpin.fa"
    normalize_note="gcf: stripped the own species prefix from $(wc -l < "$renamed") miRBase hairpin names (gcf_hairpin_renamed.tsv)"
    echo "$normalize_note"
    printf '%s\t%s\t%s\t%s\n' "hairpin.fa" "gcf:unitas_normalize_hairpin.awk" \
        "$(sha256sum "$src/hairpin.fa" | cut -d' ' -f1)" "NA" >> "$sources"
else
    # MirGeneDB: all species, so that UNITAS can label hits to other species as with miRBase.
    mgdb=https://mirgenedb.org
    for q in mat star pre; do
        fetch "$mgdb/fasta/ALL?$q=1" "$src/mirgenedb_$q.fa" fasta
    done
    fetch "$mgdb/gff/$code?all=1&sort=pos" "$src/mirgenedb_$code.gff3"
    head -n 1 "$src/mirgenedb_$code.gff3" | grep -qx '##gff-version 3' || die "MirGeneDB GFF for $code is not GFF3"
    grep -qE "^# microRNAs:[[:space:]]+MirGeneDB v$mirgenedb_release\$" "$src/mirgenedb_$code.gff3" \
        || die "MirGeneDB GFF for $code is not MirGeneDB $mirgenedb_release: $(grep -m1 '^# microRNAs' "$src/mirgenedb_$code.gff3")"
    conv() {  # kind output inputs...
        local kind=$1 out=$2; shift 2
        awk -v kind="$kind" -v species="$mirgenedb_species" -f "$mirgenedb_awk" "$@" > "$out" 2> "$workdir/mirgenedb_$kind.log" \
            || die "MirGeneDB $kind conversion failed: $(cat "$workdir/mirgenedb_$kind.log")"
        printf '%s\t%s\t%s\t%s\n' "$(basename "$out")" "gcf:unitas_mirgenedb2mirbase.awk" \
            "$(sha256sum "$out" | cut -d' ' -f1)" "NA" >> "$sources"
    }
    conv mature "$src/mature.fa" "$src/mirgenedb_mat.fa" "$src/mirgenedb_star.fa"
    conv hairpin "$src/hairpin.fa" "$src/mirgenedb_pre.fa"
    n_mature=$(grep -ci "^>$code-" "$src/mature.fa" || true)
    n_hairpin=$(grep -ci "^>$code-" "$src/hairpin.fa" || true)
    (( n_mature > 0 && n_hairpin > 0 )) || die "MirGeneDB has no $code miRNAs (mature $n_mature, precursors $n_hairpin)"
    : > "$renamed"
    normalize_note="gcf: MirGeneDB $mirgenedb_release, $n_mature $code mature/star and $n_hairpin precursor sequences (all species: $(grep -c '^>' "$src/mature.fa") and $(grep -c '^>' "$src/hairpin.fa"))"
    echo "$normalize_note"
fi
for f in mature hairpin; do
    gzip -n "$src/$f.fa"
done

# piRNA clusters (unitas formats them into piRclDB)
fetch "https://www.pirnaclusterdb.org/data/FASTA/$ens_name.piRNAclusters.fasta" "$src/piRNAclusters.fasta" fasta
pirc_date=$(date -u +%d.%m.%Y)

# SILVA rRNA: the species' SSU and LSU Ref entries, in the old server's file layout
silva=https://ftp.arb-silva.de/release_$silva_release/Exports
for unit in SSU LSU; do
    fasta=$src/SILVA_${silva_release}_${unit}Ref_tax_silva.fasta.gz
    taxmap=$src/taxmap_embl_${unit,,}_ref_$silva_release.txt.gz
    fetch_md5 "$silva/$(basename "$fasta")" "$fasta" fasta.gz
    fetch_md5 "$silva/taxonomy/$(basename "$taxmap")" "$taxmap"
    out=$U/SILVA_rRNA/SILVA_${unit}_$species.fasta
    awk -v taxid="$taxid" -v unit="$unit" -f "$silva_awk" <(gzip -dc "$taxmap") <(gzip -dc "$fasta") \
        > "$out" 2> "$workdir/silva_$unit.log" || die "SILVA $unit selection failed: $(cat "$workdir/silva_$unit.log")"
    cat "$workdir/silva_$unit.log"
    printf '%s\t%s\t%s\t%s\n' "SILVA_rRNA.$unit" "gcf:unitas_silva_species.awk taxid $taxid" \
        "$(sha256sum "$out" | cut -d' ' -f1)" "NA" >> "$sources"
    rm -f "$fasta"
done

# Static data from the existing dump, in the layout of the old server. The rat files name most
# records with a '>' inside (tRNA|tRF-1_>#297); every '>' after the first character of a header is
# removed, as for the Ensembl names (gcfntnu/gcf-docker#56), and counted in gcf_sources.tsv.
strip_gt() { awk '/^>/ { h = substr($0, 2); gsub(/>/, "", h); $0 = ">" h } { print }' "$1"; }
strip_gt "$static/tRF-1.fas" > "$U/tRF-1/$species.tRF-1.fas"
strip_gt "$static/tRNA_leader.fas" > "$U/tRNA_leader/$species.tRNA_leader.fas"
printf '%s' "$trf1_date" > "$U/tRF-1/release"
printf '%s' "$leader_date" > "$U/tRNA_leader/release"
printf '%s' "$silva_release" > "$U/SILVA_rRNA/release"
printf 'NA' > "$U/SeqMap/release"
for f in tRF-1.fas tRNA_leader.fas; do
    printf '%s\t%s\t%s\t%s\n' "$f" "static:$static/$f" "$(sha256sum "$static/$f" | cut -d' ' -f1)" "NA" >> "$sources"
    n=$(grep -c '^>.\+>' "$static/$f" || true)
    if (( n > 0 )); then
        out=$U/${f%.fas}/$species.$f
        printf '%s\t%s\t%s\t%s\n' "$f" "gcf:removed '>' inside $n names" "$(sha256sum "$out" | cut -d' ' -f1)" "NA" >> "$sources"
        echo "gcf: removed '>' inside $n $f names"
    fi
done

# URL tables (Perl, evaluated by unitas as on the old server)
cat > "$U/URLs/gtRNAdb" <<EOF
%gtRNAdb_urls=('$species'=>'file://$src/$trna');
\$miRBase_mature='file://$src/mature.fa.gz';
\$miRBase_hairpin='file://$src/hairpin.fa.gz';
\$miRBase_release='$mirna_release_field';
\$ensembl_release='$ensembl';
\$ensemblgenomes_release='NA';
\$piRclDB_date='$pirc_date';
EOF
echo "%piRclDB_urls=('$species'=>'file://$src/piRNAclusters.fasta');" > "$U/URLs/piRclDB"
echo "%ensembl_ncRNA=('$species'=>'file://$src/$ncrna');" > "$U/URLs/Ensembl_ncRNA"
echo "%ensembl_cDNA=('$species'=>'file://$src/$cdna');" > "$U/URLs/Ensembl_cDNA"

echo "build UNITAS_refdump_$species (Ensembl $ensembl $ens_asm, GtRNAdb $(basename "$gtrnadb"), $mirna_label)"
log=$workdir/run/refdump.log
if ! (cd "$workdir/run" && unitas.pl -refdump -species "$species" -mirror "$mirror" > "$log" 2>&1) \
        || grep -q 'ERROR' "$log"; then
    tail -n 30 "$log" >&2
    die "unitas -refdump failed for $species (log: $log)"
fi

dump=$workdir/run/UNITAS_refdump_$species
for f in db_versions.info ncRNA.fas cDNA.fas tRF-1.fas tRNA_leader.fas miRBase_mature piRclDB \
         "miRBase_hairpin_$org.fas" "miRBase_hairpin_non-$org.fas"; do
    [[ -s $dump/$f ]] || die "dump is missing $f"
done
# Species hairpins are named from the normalized header; none may keep the species prefix.
# (miRBase_hairpin_non-$org.fas is named from the record IDs, which always carry a prefix.)
if grep -qi "^>$code-" "$dump/miRBase_hairpin_$org.fas"; then
    die "miRBase_hairpin_$org.fas has $code- names: $(grep -i "^>$code-" "$dump/miRBase_hairpin_$org.fas" | head -3 | tr '\n' ' ')"
fi
# Names (gcfntnu/gcf-docker#56): no '>' inside a header, and no <symbol>-(n) name without the gene ID.
bad=$(grep -h '^>.*>' "$dump/ncRNA.fas" "$dump/cDNA.fas" | head -3 | tr '\n' ' ' || true)
[[ -z $bad ]] || die "headers with '>' after the first character (unitas.pl without unitas-1.8.0-6.patch?): $bad"
bad=$(grep -E -- '-\([0-9]+\)$' "$dump/ncRNA.fas" | head -3 | tr '\n' ' ' || true)
[[ -z $bad ]] || die "ncRNA.fas names without the gene ID, <symbol>-(n) (unitas.pl without unitas-1.8.0-6.patch?): $bad"
if (( ! keep_raw )); then
    rm -f "$dump/ensembl_ncRNA" "$dump/ensembl_cDNA" "$dump/miRBase_hairpin"
fi
cp "$sources" "$dump/gcf_sources.tsv"
if [[ $mirna_db == mirbase ]]; then
    cp "$renamed" "$dump/gcf_hairpin_renamed.tsv"
else
    cp "$src/mirgenedb_$code.gff3" "$dump/gcf_mirgenedb.gff3"
fi
printf 'database\trelease\n%s\t%s\n' "$mirna_db" "${mirbase_release}${mirgenedb_release}" > "$dump/gcf_mirna_db.tsv"
cp "$log" "$dump/gcf_refdump.log"
echo "$normalize_note" >> "$dump/gcf_refdump.log"

rm -rf "$outdir/UNITAS_refdump_$species" "$outdir/UNITAS_refdump_$species.tar.gz"
tar --sort=name --owner=0 --group=0 --numeric-owner --mtime='1970-01-01' \
    -C "$workdir/run" -czf "$outdir/UNITAS_refdump_$species.tar.gz" "UNITAS_refdump_$species"
mv "$dump" "$outdir/"
echo "done: $outdir/UNITAS_refdump_$species.tar.gz"
cat "$outdir/UNITAS_refdump_$species/db_versions.info"
