#!/usr/bin/env bash
# unitas_refdump_extras.pl on synthetic dump files: add45s appends the 45S pre-rRNA as one rRNA record (once), and mask
# replaces every exact copy of a snoRNA or scaRNA (at least 50 nt) inside other ncRNA and cDNA records by N, keeps the
# snoRNA records themselves and short ones, and reports the counts (gcfntnu/gcf-docker#61, #62). No network.
# Usage: tests/test_refdump_extras.sh
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
extras=$here/../unitas_refdump_extras.pl
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }

sno=CTGATGATGAGCTTGCTGAGGCATCTGAGTACGTTGGATCATGTTCGATCAGTCTGAGC   # 59 nt, C/D box-like
sca=GGCATTTGCAGTCCATGCGTTTGAGTCAACTGCAGTTCGATGCACGTGGTTCAAGTCC   # 58 nt
short=ACGTACGTACGTACGTACGTACGT                                     # 24 nt: too short to mask
cat > "$tmp/ncRNA.fas" <<EOF
>snoRNA|SNORD1-ENSG1
$sno
>scaRNA|SCARNA1-ENSG2
$sca
>snoRNA|SNORDX-ENSG3
$short
>lncRNA|GAS5-ENSG4_(2)
AAAA${sno}TTTT${sno}GG
>lncRNA|OTHER-ENSG5
CCCC${short}CCCC
>rRNA|5S_rRNA-ENSG6
GTCTACGGCCATACCACCCTGAACG
EOF
cat > "$tmp/cDNA.fas" <<EOF
>protein_coding|NOP56
GG${sca}AA
>protein_coding|ACTB
ATGGATGATGATATCGCCGCGCTCG
EOF

out=$(perl "$extras" mask "$tmp/ncRNA.fas" "$tmp/cDNA.fas") || fail "mask failed"
[[ $out == "masked 2 snoRNA/scaRNA sequences: ncRNA.fas 1 records, 2 copies, $(( 2 * ${#sno} )) nt; cDNA.fas 1 records, 1 copies, ${#sca} nt" ]] \
    || fail "unexpected summary: $out"
nsno=$(printf 'N%.0s' $(seq ${#sno})) nsca=$(printf 'N%.0s' $(seq ${#sca}))
grep -qx "AAAA${nsno}TTTT${nsno}GG" "$tmp/ncRNA.fas" || fail "both snoRNA copies in the host lncRNA should be masked"
grep -qx "GG${nsca}AA" "$tmp/cDNA.fas" || fail "the scaRNA copy in the cDNA should be masked"
grep -qx "$sno" "$tmp/ncRNA.fas" && grep -qx "$sca" "$tmp/ncRNA.fas" || fail "the snoRNA and scaRNA records must stay"
grep -qx "CCCC${short}CCCC" "$tmp/ncRNA.fas" || fail "a copy of a snoRNA under 50 nt must not be masked"
grep -qx 'ATGGATGATGATATCGCCGCGCTCG' "$tmp/cDNA.fas" || fail "an unrelated cDNA must not change"
[[ $(grep -c '^>' "$tmp/ncRNA.fas") == 6 && $(grep -c '^>' "$tmp/cDNA.fas") == 2 ]] || fail "record counts changed"

printf '>NR_046235.3 Homo sapiens RNA, 45S pre-ribosomal N5\nTACCTGGTTGATCCTGCCAG\ntcgtacgacucttagcgg\n' > "$tmp/45s.fa"
out=$(perl "$extras" add45s "$tmp/ncRNA.fas" "$tmp/45s.fa" 45S_pre-rRNA-NR_046235.3) || fail "add45s failed"
[[ $out == "added rRNA|45S_pre-rRNA-NR_046235.3 (38 nt) to $tmp/ncRNA.fas" ]] || fail "unexpected add45s output: $out"
tail -2 "$tmp/ncRNA.fas" | diff -u - <(printf '>rRNA|45S_pre-rRNA-NR_046235.3\nTACCTGGTTGATCCTGCCAGTCGTACGACTCTTAGCGG\n') \
    || fail "the 45S record should be one line, upper case, U as T"
perl "$extras" add45s "$tmp/ncRNA.fas" "$tmp/45s.fa" 45S_pre-rRNA-NR_046235.3 2> "$tmp/again.err" && fail "adding the 45S twice should fail"
grep -q 'already has' "$tmp/again.err" || fail "unexpected error: $(cat "$tmp/again.err")"
printf '>a\nACGT\n>b\nACGT\n' > "$tmp/two.fa"
perl "$extras" add45s "$tmp/ncRNA.fas" "$tmp/two.fa" X 2> /dev/null && fail "a FASTA with two records should fail"
echo "test_refdump_extras.sh: ok"
