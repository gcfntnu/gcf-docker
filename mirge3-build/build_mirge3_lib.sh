#!/usr/bin/env bash
# Build a miRge3 0.1.4 library (miRBase and MirGeneDB) for one species from public sources.
#
# Usage: build_mirge3_lib.sh --species NAME --outdir DIR [--ensembl-release 116] [--mirbase-release 23.1]
#                            [--mirgenedb-release 3.0] [--old-human-lib FILE] [--workdir DIR] [--threads N]
#   --species        homo_sapiens | mus_musculus | rattus_norvegicus
#   --outdir         writes <org>/ (human, mouse, rat: miRge3's -on name) and miRge3_lib_<species>.tar.gz
#   --old-human-lib  human only: the miRge3 SourceForge human.tar.gz (2020). Its human tRNA set
#                    (mature and pre-tRNA sequences, tRNA and tRF annotation) is kept unchanged,
#                    because human_tRF_infor.csv and human_tRF_merges.csv (for --tRNA-frag) cannot
#                    be rebuilt from public sources and name tRNAs of that set.
#   --workdir        downloads and intermediate files (default: a temporary directory)
#
# Sources (each recorded with URL, SHA-256 and date in gcf_sources.tsv):
#   miRBase <release> mature/hairpin FASTA and genome GFF; MirGeneDB <release> mature, star and
#   precursor FASTA and GFF; Ensembl <release> genome (bowtie index for --AtoI), cDNA (mRNA) and
#   ncRNA (snoRNA, rRNA incl. rRNA_pseudogene, others); GtRNAdb mature tRNAs and loci (mouse, rat); UCSC RepeatMasker
#   for the assembly of each miRNA GFF; SNVs inside mature miRNAs for the A-to-I SNP variants:
#     human     dbSNP 157 COMMON (minor allele >= 1% in a 1000 Genomes population), GRCh38
#     mouse     dbSNP 150 (GRCm38), for both databases; miRBase matures are placed on GRCm38 by
#               accession through the miRBase 22.1 GFF (GRCm38), for this lookup only
#     rat       dbSNP 149 (Rnor_6.0), for both databases (their GFFs are on Rnor_6.0)
#   Spike-ins: the gcf-workflows small RNA calibrators (Cal01-Cal10).
# No liftover: each miRNA GFF is used on its own assembly; the genome index is the Ensembl one.
# Files for --novel-miRNA (genome pickles) are not built.
set -euo pipefail

species= outdir= workdir= old_human= threads=$(nproc)
ensembl=116 mirbase=23.1 mirgenedb=3.0
while (( $# )); do
    case $1 in
        --species) species=$2; shift 2 ;;
        --outdir) outdir=$2; shift 2 ;;
        --workdir) workdir=$2; shift 2 ;;
        --ensembl-release) ensembl=$2; shift 2 ;;
        --mirbase-release) mirbase=$2; shift 2 ;;
        --mirgenedb-release) mirgenedb=$2; shift 2 ;;
        --old-human-lib) old_human=$2; shift 2 ;;
        --threads) threads=$2; shift 2 ;;
        -h|--help) sed -n '2,25p' "$0"; exit 0 ;;
        *) echo "build_mirge3_lib: unknown argument $1" >&2; exit 2 ;;
    esac
done
die() { echo "build_mirge3_lib: $*" >&2; exit 1; }
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
lib_py=$here/mirge3_lib.py
[[ -n $species && -n $outdir ]] || die "--species and --outdir are required (see --help)"
[[ $ensembl =~ ^[0-9]+$ ]] || die "--ensembl-release must be a number, got $ensembl"
[[ $mirbase =~ ^[0-9]+(\.[0-9]+)?$ ]] || die "--mirbase-release must look like 23.1, got $mirbase"

ncbi=https://ftp.ncbi.nih.gov/snp
ucsc=https://hgdownload.soe.ucsc.edu/goldenPath
gtrnadb_name= mirbase_snv_release= mirbase_snv_assembly=
case $species in
    homo_sapiens)
        org=human code=hsa ens_name=Homo_sapiens ens_asm=GRCh38 dna=primary_assembly
        mirbase_rmsk=hg38 mirgenedb_rmsk=hg38
        mirbase_vcf=$ncbi/latest_release/VCF/GCF_000001405.40.gz mirbase_vcf_contigs=refseq mirbase_vcf_filter='INFO/COMMON=1'
        mirgenedb_vcf=$mirbase_vcf mirgenedb_vcf_contigs=refseq mirgenedb_vcf_filter='INFO/COMMON=1'
        [[ -n $old_human && -s $old_human ]] || die "homo_sapiens needs --old-human-lib (miRge3 SourceForge human.tar.gz)" ;;
    mus_musculus)
        org=mouse code=mmu ens_name=Mus_musculus ens_asm=GRCm39 dna=primary_assembly
        mirbase_rmsk=mm39 mirgenedb_rmsk=mm10
        mirbase_vcf=$ncbi/organisms/archive/mouse_10090/VCF/00-All.vcf.gz mirbase_vcf_contigs=ensembl mirbase_vcf_filter=
        mirbase_snv_release=22.1 mirbase_snv_assembly=GRCm38
        mirgenedb_vcf=$mirbase_vcf mirgenedb_vcf_contigs=ensembl mirgenedb_vcf_filter=
        gtrnadb_name=Mmusc39/mm39 trna_genome=ensembl ;;
    rattus_norvegicus)
        org=rat code=rno ens_name=Rattus_norvegicus ens_asm=GRCr8 dna=toplevel
        mirbase_rmsk=rn6 mirgenedb_rmsk=rn6
        mirbase_vcf=$ncbi/organisms/archive/rat_10116/VCF/00-All.vcf.gz mirbase_vcf_contigs=ensembl mirbase_vcf_filter=
        mirgenedb_vcf=$mirbase_vcf mirgenedb_vcf_contigs=ensembl mirgenedb_vcf_filter=
        gtrnadb_name=Rnorv7/rn7 trna_genome=rn7 ;;
    *) die "unsupported species $species (homo_sapiens, mus_musculus, rattus_norvegicus)" ;;
esac

mkdir -p "$outdir"
outdir=$(cd "$outdir" && pwd)
if [[ -z $workdir ]]; then workdir=$(mktemp -d); trap 'rm -rf "$workdir"' EXIT; fi
mkdir -p "$workdir"
workdir=$(cd "$workdir" && pwd)
src=$workdir/src work=$workdir/work lib=$workdir/lib/$org
rm -rf "$work" "$workdir/lib"
mkdir -p "$src" "$work" "$lib/annotation.Libs" "$lib/fasta.Libs" "$lib/index.Libs"
cd "$workdir"

sources=$work/gcf_sources.tsv
printf 'file\turl\tsha256\tretrieved\n' > "$sources"
record() { printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$(sha256sum "$3" | cut -d' ' -f1)" "$4" >> "$sources"; }
fetch() {  # url output [kind]; reuses an existing download in --workdir, always records it
    local url=$1 out=$2 kind=${3:-}
    if [[ ! -s $out ]]; then
        echo "download $url"
        curl -fsSL --retry 3 -o "$out.part" "$url" || die "download failed: $url"
        mv "$out.part" "$out"
        date -u +%Y-%m-%dT%H:%M:%SZ > "$out.retrieved"
    fi
    case $kind in
        fasta) [[ $(head -c1 "$out") == '>' ]] || die "not FASTA: $url" ;;
        fasta.gz) [[ $(gzip -dc "$out" | head -c1) == '>' ]] || die "not gzipped FASTA: $url" ;;
    esac
    record "$(basename "$out")" "$url" "$out" "$(cat "$out.retrieved")"
}
py() { python3 "$lib_py" "$@"; }

# ---- downloads --------------------------------------------------------------------------------
mb=https://www.mirbase.org
fetch "$mb/download_version_files/$mirbase/mature.fa" "$src/mirbase_mature.fa" fasta
fetch "$mb/download_version_files/$mirbase/hairpin.fa" "$src/mirbase_hairpin.fa" fasta
fetch "$mb/download_version_genome_files/$mirbase/$code.gff3" "$src/mirbase_$code.gff3"
mg=https://mirgenedb.org
for q in mat star pre; do fetch "$mg/fasta/$code?$q=1" "$src/mirgenedb_${code}_$q.fa" fasta; done
fetch "$mg/gff/$code?all=1&sort=pos" "$src/mirgenedb_$code.gff3"
grep -qE "^# microRNAs:[[:space:]]+MirGeneDB v$mirgenedb\$" "$src/mirgenedb_$code.gff3" \
    || die "MirGeneDB GFF is not MirGeneDB $mirgenedb: $(grep -m1 '^# microRNAs' "$src/mirgenedb_$code.gff3")"
ens=https://ftp.ensembl.org/pub/release-$ensembl/fasta/$species
genome=$ens_name.$ens_asm.dna.$dna.fa.gz cdna=$ens_name.$ens_asm.cdna.all.fa.gz ncrna=$ens_name.$ens_asm.ncrna.fa.gz
fetch "$ens/dna/$genome" "$src/$genome" fasta.gz
fetch "$ens/cdna/$cdna" "$src/$cdna" fasta.gz
fetch "$ens/ncrna/$ncrna" "$src/$ncrna" fasta.gz
for asm in $(printf '%s\n' "$mirbase_rmsk" "$mirgenedb_rmsk" | sort -u); do
    fetch "$ucsc/$asm/database/rmsk.txt.gz" "$src/rmsk_$asm.txt.gz"
done
if [[ -n $gtrnadb_name ]]; then
    g=https://gtrnadb.ucsc.edu/genomes/eukaryota/$gtrnadb_name
    fetch "$g-mature-tRNAs.fa" "$src/gtrnadb-mature-tRNAs.fa" fasta
    fetch "$g-tRNAs.bed" "$src/gtrnadb-tRNAs.bed"
    [[ $trna_genome == rn7 ]] && fetch "$ucsc/rn7/bigZips/rn7.fa.gz" "$src/rn7.fa.gz" fasta.gz
fi
if [[ $org == human ]]; then
    report=https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/405/GCF_000001405.40_GRCh38.p14/GCF_000001405.40_GRCh38.p14_assembly_report.txt
    fetch "$report" "$src/GRCh38.p14_assembly_report.txt"
    record "human.tar.gz" "old miRge3 SourceForge library (human tRNA set)" "$old_human" "NA"
fi

# ---- miRNAs -------------------------------------------------------------------------------------
py mirna --db miRBase --org "$org" --code "$code" --mature "$src/mirbase_mature.fa" \
    --hairpin "$src/mirbase_hairpin.fa" --gff "$src/mirbase_$code.gff3" --lib "$lib" --work "$work"
py mirna --db MirGeneDB --org "$org" --code "$code" --mature "$src/mirgenedb_${code}_mat.fa" \
    --star "$src/mirgenedb_${code}_star.fa" --hairpin "$src/mirgenedb_${code}_pre.fa" \
    --gff "$src/mirgenedb_$code.gff3" --lib "$lib" --work "$work"

snps() {  # db vcf contigs filter bed -> $work/snps_<db>.tsv (chrom pos ref alt, chrom as in the bed)
    local db=$1 vcf=$2 contigs=$3 filter=$4 bed=$5 regions=$work/regions_$1.tsv
    case $contigs in
        refseq)  # GRCh38 chrN -> NC_ accession (dbSNP), via the assembly report
            awk -F'\t' 'NR == FNR { sub(/\r$/, ""); if ($0 !~ /^#/ && $10 != "na") ucsc[$10] = $7; next }
                        ($1 in ucsc) { print ucsc[$1] "\t" $2 + 1 "\t" $3 }' \
                "$src/GRCh38.p14_assembly_report.txt" "$bed" > "$regions" ;;
        ensembl) awk -F'\t' '{ c = $1; sub(/^chr/, "", c); if (c == "M") c = "MT"; print c "\t" $2 + 1 "\t" $3 }' "$bed" > "$regions" ;;
    esac
    echo "SNVs for $db from $vcf ($(wc -l < "$regions") mature loci${filter:+, $filter})"
    bcftools query ${filter:+-i "$filter"} -R "$regions" -f '%CHROM\t%POS\t%REF\t%ALT\n' "$vcf" \
        > "$work/snps_$db.raw" 2> "$work/snps_$db.log" || { cat "$work/snps_$db.log" >&2; die "bcftools query failed: $vcf"; }
    if [[ $contigs == refseq ]]; then
        awk -F'\t' 'NR == FNR { sub(/\r$/, ""); if ($0 !~ /^#/ && $10 != "na") chr[$7] = $10; next } ($1 in chr) { $1 = chr[$1]; print }' OFS='\t' \
            "$src/GRCh38.p14_assembly_report.txt" "$work/snps_$db.raw" > "$work/snps_$db.tsv"
    else
        cp "$work/snps_$db.raw" "$work/snps_$db.tsv"
    fi
    printf 'snv_source\t%s\t%s\t%s\n' "$db" "$vcf" "${filter:-all}" >> "$work/gcf_snp_sources.tsv"
    bcftools view -h "$vcf" 2>/dev/null | grep -m2 -E '^##(dbSNP_BUILD_ID|source|reference)=' | sed "s/^/$db\t/" >> "$work/gcf_snp_sources.tsv" || true
}
: > "$work/gcf_snp_sources.tsv"
snv_bed_mirbase=$work/${org}_mature_miRBase.bed
if [[ -n $mirbase_snv_release ]]; then
    fetch "$mb/download_version_genome_files/$mirbase_snv_release/$code.gff3" "$src/mirbase${mirbase_snv_release}_$code.gff3"
    grep -qE "^# genome-build-id:[[:space:]]+$mirbase_snv_assembly\$" "$src/mirbase${mirbase_snv_release}_$code.gff3" \
        || die "miRBase $mirbase_snv_release $code GFF is not on $mirbase_snv_assembly"
    snv_bed_mirbase=$work/snv_loci_miRBase.bed
    py snv-bed --org "$org" --gff "$src/mirbase${mirbase_snv_release}_$code.gff3" --lib "$lib" --work "$work" --out "$snv_bed_mirbase"
    printf 'snv_loci\tmiRBase\tmiRBase %s GFF (%s), by accession\n' "$mirbase_snv_release" "$mirbase_snv_assembly" >> "$work/gcf_snp_sources.tsv"
fi
snps miRBase "$mirbase_vcf" "$mirbase_vcf_contigs" "$mirbase_vcf_filter" "$snv_bed_mirbase"
snps MirGeneDB "$mirgenedb_vcf" "$mirgenedb_vcf_contigs" "$mirgenedb_vcf_filter" "$work/${org}_mature_MirGeneDB.bed"
for db in miRBase MirGeneDB; do
    asm_var=${db,,}_rmsk asm=${!asm_var}
    [[ -s $work/rmsk_$asm.bed ]] || py rmsk-bed --rmsk "$src/rmsk_$asm.txt.gz" --out "$work/rmsk_$asm.bed"
    bedtools intersect -wa -wb -a "$work/${org}_mature_$db.bed" -b "$work/rmsk_$asm.bed" > "$work/repeats_$db.tsv"
    py mirna-finish --db "$db" --org "$org" --gff "$([[ $db == miRBase ]] && echo "$src/mirbase_$code.gff3" || echo "$src/mirgenedb_$code.gff3")" \
        --lib "$lib" --work "$work" --snps "$work/snps_$db.tsv" --repeats "$work/repeats_$db.tsv" \
        --snv-bed "$([[ $db == miRBase ]] && echo "$snv_bed_mirbase" || echo "$work/${org}_mature_MirGeneDB.bed")"
done

# ---- other RNA, tRNA, spike-ins -----------------------------------------------------------------
py ncrna --ncrna "$src/$ncrna" --cdna "$src/$cdna" --outdir "$work"
gzip -dc "$src/$genome" > "$work/genome.fa"
if [[ $org == human ]]; then
    # The old human tRNA set, unchanged: sequences from its indexes, annotation files as they are.
    tar -xzf "$old_human" -C "$work" --wildcards 'human/index.Libs/human_mature_trna.*' \
        'human/index.Libs/human_pre_trna.*' 'human/annotation.Libs/human_trna*' 'human/annotation.Libs/human_tRF_*'
    bowtie-inspect "$work/human/index.Libs/human_mature_trna" > "$work/mature_trna.fa"
    bowtie-inspect "$work/human/index.Libs/human_pre_trna" > "$work/pre_trna.fa"
    for f in trna.str trna_aminoacid_anticodon.csv trna_deduplicated_list.csv tRF_infor.csv tRF_merges.csv; do
        cp "$work/human/annotation.Libs/human_$f" "$lib/annotation.Libs/"
    done
    trna_note="old miRge3 SourceForge human library (unchanged)"
else
    prefix=$(head -1 "$src/gtrnadb-mature-tRNAs.fa" | sed -E 's/^>([A-Z][a-z]+_[a-z]+)_tRNA-.*/\1/')
    if [[ $trna_genome == ensembl ]]; then
        py trna --mature "$src/gtrnadb-mature-tRNAs.fa" --bed "$src/gtrnadb-tRNAs.bed" --genome "$work/genome.fa" \
            --outdir "$work" --species-prefix "$prefix" --chrom-prefix ''
    else
        py trna --mature "$src/gtrnadb-mature-tRNAs.fa" --bed "$src/gtrnadb-tRNAs.bed" --genome "$src/rn7.fa.gz" \
            --outdir "$work" --species-prefix "$prefix"
    fi
    trna_note="GtRNAdb $gtrnadb_name mature tRNAs (+CCA) and 100 nt trailers"
fi
cat > "$work/spike-in.fa" <<'EOF'
>spikeIn|Cal01
GTCCCACTCCGTAGATCTGTTC
>spikeIn|Cal02
GATGTAACGAGTTGGAATGCAA
>spikeIn|Cal03
TAGCATATCGAGCCTGAGAACA
>spikeIn|Cal04
CATCGGTCGAACTTATGTGAAA
>spikeIn|Cal05
GAAGCACATTCGCACATCATAT
>spikeIn|Cal06
TCTTAACCCGGACCAGAAACTA
>spikeIn|Cal07
AGGTTCCGGATAAGTAAGAGCC
>spikeIn|Cal08
TAACTCCTTAAGCGAATCTCGC
>spikeIn|Cal09
AAAGTAGCATCCGAAATACGGA
>spikeIn|Cal10
TGATACGGATGTTATACGCAGC
EOF

# ---- bowtie indexes -----------------------------------------------------------------------------
build() {  # fasta index-name
    echo "bowtie-build $2"
    bowtie-build --threads "$threads" -f "$1" "$lib/index.Libs/$2" > "$work/bowtie-build_$2.log" 2>&1 \
        || { tail -20 "$work/bowtie-build_$2.log" >&2; die "bowtie-build failed for $2"; }
}
for db in miRBase MirGeneDB; do
    build "$work/${org}_hairpin_$db.fa" "${org}_hairpin_$db"
    build "$work/${org}_mirna_$db.fa" "${org}_mirna_$db"
done
for i in mature_trna pre_trna mrna ncrna_others rrna snorna spike-in; do build "$work/$i.fa" "${org}_$i"; done
# The genome index takes hours; it is kept in --workdir and reused while the genome download is
# the same (SHA-256), so a rebuild after changes to the small libraries does not redo it.
gidx=$workdir/genome-index gsha=$(sha256sum "$src/$genome" | cut -d' ' -f1)
if [[ -s $gidx/${org}_genome.1.ebwt && $(cat "$gidx/genome.sha256" 2>/dev/null) == "$gsha" ]]; then
    echo "bowtie-build ${org}_genome: reusing $gidx (same genome $gsha)"
else
    rm -rf "$gidx" && mkdir -p "$gidx"
    echo "bowtie-build ${org}_genome"
    bowtie-build --threads "$threads" -f "$work/genome.fa" "$gidx/${org}_genome" > "$work/bowtie-build_${org}_genome.log" 2>&1 \
        || { tail -20 "$work/bowtie-build_${org}_genome.log" >&2; die "bowtie-build failed for ${org}_genome"; }
    echo "$gsha" > "$gidx/genome.sha256"
fi
cp "$gidx/${org}_genome".*ebwt "$lib/index.Libs/"

# ---- provenance, check, archive -----------------------------------------------------------------
cp "$sources" "$lib/gcf_sources.tsv"
printf 'database\trelease\nmirbase\t%s\nmirgenedb\t%s\n' "$mirbase" "$mirgenedb" > "$lib/gcf_mirna_db.tsv"
{
    printf 'key\tvalue\n'
    printf 'species\t%s\nmirge3_organism\t%s\n' "$species" "$org"
    printf 'mirbase_release\t%s\nmirgenedb_release\t%s\nensembl_release\t%s\n' "$mirbase" "$mirgenedb" "$ensembl"
    printf 'genome_assembly\t%s (Ensembl %s, %s)\n' "$ens_asm" "$ensembl" "$dna"
    printf 'mirbase_gff_assembly\t%s\n' "$(grep -m1 '^# genome-build-id' "$src/mirbase_$code.gff3" | awk '{print $NF}')"
    printf 'mirgenedb_gff_assembly\t%s\n' "$(grep -m1 '^# genome-build-id' "$src/mirgenedb_$code.gff3" | awk '{print $NF}')"
    printf 'repeatmasker\tmiRBase: UCSC %s rmsk; MirGeneDB: UCSC %s rmsk\n' "$mirbase_rmsk" "$mirgenedb_rmsk"
    printf 'trna\t%s\n' "$trna_note"
    printf 'spike_in\tgcf-workflows small RNA calibrators Cal01-Cal10\n'
    printf 'novel_mirna\tnot supported (no genome pickles)\n'
    printf 'bowtie\t%s\n' "$(bowtie-build --version | head -1)"
    printf 'builder_image\t%s\n' "${MIRGE3_BUILD:-unknown}"
    sed 's/^/snv\t/' "$work/gcf_snp_sources.tsv"
    for db in miRBase MirGeneDB; do
        printf 'count_%s\tmature %s, mirna index %s, SNP variants %s, merge groups %s, repeat overlaps %s\n' "$db" \
            "$(grep -c '^>' "$lib/fasta.Libs/${org}_mature_$db.fa")" "$(grep -c '^>' "$work/${org}_mirna_$db.fa")" \
            "$(grep -c '^>.*\.SNP[ABD-Z]$' "$work/${org}_mirna_$db.fa" || true)" \
            "$(wc -l < "$lib/annotation.Libs/${org}_merges_$db.csv")" \
            "$(wc -l < "$lib/annotation.Libs/${org}_miRNAs_in_repetitive_element_$db.csv")"
    done
} > "$lib/gcf_manifest.tsv"
py check-lib --lib "$lib" --org "$org" $([[ $org == human ]] && echo --trna-annotation)

rm -rf "${outdir:?}/$org" "$outdir/miRge3_lib_$species.tar.gz"
tar --sort=name --owner=0 --group=0 --numeric-owner --mtime='1970-01-01' \
    -C "$workdir/lib" -cf - "$org" | pigz -n -p "$threads" > "$outdir/miRge3_lib_$species.tar.gz"
mv "$lib" "$outdir/"
echo "done: $outdir/miRge3_lib_$species.tar.gz"
cat "$outdir/$org/gcf_manifest.tsv"
