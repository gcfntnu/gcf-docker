# Convert MirGeneDB FASTA to the miRBase header layout that UNITAS -refdump reads.
#
# UNITAS splits miRBase headers on whitespace (">ID ACC Genus species NAME [stem-loop]"): it picks
# the species from fields 3-4, names species miRNAs from field 5 (mature) or fields 5-6 joined by
# "_" (hairpin), and labels other species' hits with field 1. MirGeneDB headers are bare IDs
# (">Hsa-Let-7-P1b_5p", ">Hsa-Let-7-P1b_3p*", ">Hsa-Let-7-P1b_pre"), so this writes
#   mature  (mat and star FASTA): >Hsa-Let-7-P1b_3p* Hsa-Let-7-P1b_3p* Homo sapiens Let-7-P1b-3p
#   hairpin (pre FASTA):          >Hsa-Let-7-P1b_pre Hsa-Let-7-P1b_pre Homo sapiens Let-7-P1b stem-loop
# The MirGeneDB ID stands in for the miRBase accession. NAME has no species code, so species miRNAs
# are reported without a prefix, as with the normalized miRBase dump. Mature NAMEs are written as
# <gene>-5p/-3p, without MirGeneDB's "_" and star "*": UNITAS names reads that it places on a
# hairpin arm (isomiRs, for example) <hairpin NAME>-5p/-3p, so both routes then give one name per
# arm. Whether an arm is the star is kept in the ID. Sequences are copied unchanged (UNITAS replaces
# U by T itself).
#
#   awk -v kind=mature|hairpin -v species=mirgenedb_species.tsv -f unitas_mirgenedb2mirbase.awk FASTA... > out.fa
#
# species is a TSV of "code<TAB>Latin name" (mirgenedb_species.tsv). Words after the second are
# joined with "_" so that the name stays two fields ("Chrysemys picta_bellii"). Unknown species
# codes, malformed IDs and records without a sequence are errors (exit 1); usage errors exit 2.
# "converted N" is written to stderr.
BEGIN {
    usage = 0; err = 0; n = 0; nsp = 0; seq = ""; head = ""
    if (kind != "mature" && kind != "hairpin") { print "kind=mature|hairpin is required" > "/dev/stderr"; usage = 1; exit }
    if (species == "") { print "species=FILE is required" > "/dev/stderr"; usage = 1; exit }
    while ((getline line < species) > 0) {
        if (line ~ /^#/ || line == "") continue
        split(line, f, "\t")
        nw = split(f[2], w, " ")
        if (f[1] == "" || nw < 2) { print "bad species line: " line > "/dev/stderr"; usage = 1; exit }
        name = w[1] " " w[2]
        for (i = 3; i <= nw; i++) name = name "_" w[i]
        latin[tolower(f[1])] = name; nsp++
    }
    close(species)
    if (nsp == 0) { print "no species in " species > "/dev/stderr"; usage = 1; exit }
}
function fail(msg) { print "unitas_mirgenedb2mirbase: " msg > "/dev/stderr"; err = 1; exit 1 }
function flush(   id, code, rest) {
    if (head == "") return
    if (seq == "") fail("no sequence for " head)
    id = head
    if (id !~ /^[A-Za-z]+-[^ ]+$/) fail("malformed ID " id)
    code = id; sub(/-.*/, "", code)
    if (!(tolower(code) in latin)) fail("unknown species code " code " in " id)
    rest = substr(id, length(code) + 2)
    if (kind == "hairpin") {
        if (rest !~ /_pre$/) fail("hairpin ID without _pre: " id)
        sub(/_pre$/, "", rest)
        printf ">%s %s %s %s stem-loop\n%s\n", id, id, latin[tolower(code)], rest, seq
    } else {
        if (rest !~ /_[35]p\*?$/) fail("mature ID without _5p/_3p: " id)
        sub(/\*$/, "", rest); sub(/_[35]p$/, "-" substr(rest, length(rest) - 1), rest)
        printf ">%s %s %s %s\n%s\n", id, id, latin[tolower(code)], rest, seq
    }
    n++; head = ""; seq = ""
}
{ sub(/\r$/, "") }
/^>/ { flush(); head = substr($0, 2); sub(/[ \t].*/, "", head); next }
NF { seq = seq $0 }
END {
    if (usage) exit 2
    if (err) exit 1
    flush()
    if (err) exit 1
    print "converted " n > "/dev/stderr"
}
