# Normalize miRBase hairpin.fa headers for UNITAS -refdump (gcfntnu/gcf-docker#8).
#
# For the hairpins of the species it builds, UNITAS names each one from header fields 5 and 6
# (">ID ACC Genus species NAME stem-loop" -> NAME_stem-loop). Most NAMEs have no species prefix
# (miR-4511, let-7a), but some miRBase records repeat it (">hsa-mir-13167 MI0046423 Homo sapiens
# hsa-miR-13167 stem-loop"), so UNITAS would report hsa-miR-13167 next to unprefixed miRNAs.
# This strips the record's own species code (the ID up to the first "-") from NAME. The ID, the
# rest of the header and the sequences are unchanged. Names with another species' code are kept.
#
#   awk -v report=renamed.tsv -f unitas_normalize_hairpin.awk hairpin.fa > hairpin.normalized.fa
#       writes "id<TAB>old_name<TAB>new_name" to report for each changed header and
#       "renamed N" to stderr
#   awk -v mode=check -f unitas_normalize_hairpin.awk hairpin.fa
#       prints each header whose NAME still starts with its own species code and exits 1 if any
BEGIN {
    FS = " "; renamed = 0; left = 0; usage = 0
    if (mode != "" && mode != "check") { print "unknown mode " mode > "/dev/stderr"; usage = 1; exit }
    if (mode == "" && report == "") { print "report=FILE is required" > "/dev/stderr"; usage = 1; exit }
    if (mode == "") printf "" > report
}
function own_prefix(   code) {
    code = substr($1, 2); sub(/-.*/, "", code)
    if (code != "" && index($5, code "-") == 1 && length($5) > length(code) + 1) return code "-"
    return ""
}
/^>/ && NF >= 5 {
    p = own_prefix()
    if (mode == "check") {
        if (p != "") { print; left++ }
        next
    }
    if (p != "") {
        old = $5; $5 = substr($5, length(p) + 1)  # rebuilds $0 with single spaces, as UNITAS splits it
        printf "%s\t%s\t%s\n", substr($1, 2), old, $5 > report
        renamed++
    }
}
mode == "" { print }
END {
    if (usage) exit 2
    if (mode == "check") exit (left ? 1 : 0)
    if (mode == "") print "renamed " renamed > "/dev/stderr"
}
