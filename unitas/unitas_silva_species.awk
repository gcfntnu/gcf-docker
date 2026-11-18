# One species' SILVA rRNA sequences in the format of the old smallRNAgroup files.
#
# Usage: awk -v taxid=9606 -v unit=SSU -f unitas_silva_species.awk TAXMAP FASTA > SILVA_SSU_<species>.fasta
#   TAXMAP  SILVA taxmap_embl_<ssu|lsu>_ref_<release>.txt: accession, start, stop, path, organism,
#           NCBI taxid (tab-separated, one header line)
#   FASTA   SILVA_<release>_<SSU|LSU>Ref_tax_silva.fasta: IDs accession.start.stop, RNA alphabet
#
# Writes every Ref entry whose NCBI taxid is `taxid` as ">rRNA|<unit>:<accession.start.stop>" with the
# sequence in DNA letters on one line, in FASTA order. With SILVA 132 this gives exactly the records
# of the old SILVA_rRNA.SSU and SILVA_rRNA.LSU files for human, mouse and rat (checked against the
# 2022 dumps). Later releases do not fit this rule: their taxmaps carry SILVA taxonomy IDs instead
# of NCBI taxids, and 144 has no LSU.
# Fails when nothing matches, or when a selected entry is missing from the FASTA.
BEGIN {
    if (taxid == "" || unit !~ /^(SSU|LSU)$/) {
        print "unitas_silva_species.awk: set -v taxid=<NCBI taxid> -v unit=SSU|LSU" > "/dev/stderr"
        bad = 1; exit 2
    }
}
FNR == NR {
    if (FNR > 1) {
        split($0, f, "\t"); t = f[6]; gsub(/[[:space:]]/, "", t)
        k = f[1] "." f[2] "." f[3]
        if (t == taxid && !(k in want)) { want[k] = 1; n_want++ }
    }
    next
}
/^>/ { flush(); split(substr($0, 2), h, /[ \t]/); id = h[1]; seq = ""; next }
{ seq = seq $0 }
function flush() {
    if (id != "" && id in want) {
        s = toupper(seq); gsub(/[^A-Z]/, "", s); gsub(/U/, "T", s)
        print ">rRNA|" unit ":" id; print s
        found[id] = 1; n_out++
    }
    id = ""
}
END {
    if (bad) exit 2
    flush()
    if (n_want == 0) { print "unitas_silva_species.awk: no " unit " entries with NCBI taxid " taxid > "/dev/stderr"; exit 1 }
    if (n_out != n_want) {
        for (k in want) if (!(k in found)) { print "unitas_silva_species.awk: " k " is in the taxmap but not in the FASTA" > "/dev/stderr"; break }
        exit 1
    }
    print "unitas_silva_species.awk: " n_out " " unit " sequences for taxid " taxid > "/dev/stderr"
}
