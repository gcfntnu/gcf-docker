#!/usr/bin/env perl
# Post-processing of a UNITAS reference dump (unitas_build_refdump.sh), on its single-line FASTA files.
#
#   unitas_refdump_extras.pl add45s NCRNA_FAS PRE_RRNA_FASTA NAME ACCESSION
#       Append the 45S pre-rRNA as ">rRNA|NAME" to ncRNA.fas (gcfntnu/gcf-docker#61); the FASTA's header must name
#       ACCESSION (the pinned RefSeq version). The Ensembl and SILVA rRNAs end at the mature boundaries, so reads from
#       the 5' end of the 5.8S long form, from 28S 5'-end variants and from the transcribed spacers had no reference.
#       A read of mature rRNA now also hits the 45S: one that only hit rRNA stays rRNA, and one that also hit another
#       class moves a little towards rRNA under UNITAS's equal split over the matching records.
#
#   unitas_refdump_extras.pl mask NCRNA_FAS CDNA_FAS
#       Replace every exact copy of a snoRNA or scaRNA record (at least MIN_SNORNA nt) inside another ncRNA.fas
#       record or a cDNA.fas record by N (gcfntnu/gcf-docker#62). Host-gene transcripts (retained-intron and
#       unspliced isoforms) contain whole snoRNAs, and UNITAS divides a read equally over every matching
#       record, so a snoRNA read went mostly to lncRNA and mRNA. The rest of each host transcript is kept.
#       Prints one summary line: records, copies and bases masked per file.
use strict;
use warnings;

my $MIN_SNORNA = 50;

sub read_fasta {  # [[header, sequence], ...] of a FASTA file (sequences may span lines)
    my ($path) = @_;
    open(my $fh, '<', $path) or die "unitas_refdump_extras.pl: cannot read $path: $!\n";
    my @records;
    while (my $line = <$fh>) {
        $line =~ s/\s+$//;
        if ($line =~ /^>/) { push @records, [$line, '']; }
        elsif (@records) { $records[-1][1] .= $line; }
        elsif ($line ne '') { die "unitas_refdump_extras.pl: $path does not start with a FASTA header\n"; }
    }
    close $fh;
    return \@records;
}

sub write_fasta {  # rewrite a file atomically, one line per sequence
    my ($path, $records) = @_;
    open(my $fh, '>', "$path.part") or die "unitas_refdump_extras.pl: cannot write $path.part: $!\n";
    for (@$records) { print $fh "$_->[0]\n$_->[1]\n" or die "unitas_refdump_extras.pl: cannot write $path.part: $!\n"; }
    close $fh or die "unitas_refdump_extras.pl: cannot write $path.part: $!\n";
    rename("$path.part", $path) or die "unitas_refdump_extras.pl: cannot replace $path: $!\n";
}

my $command = shift @ARGV // '';
if ($command eq 'add45s') {
    @ARGV == 4 or die "usage: unitas_refdump_extras.pl add45s NCRNA_FAS PRE_RRNA_FASTA NAME ACCESSION\n";
    my ($ncrna, $fasta, $name, $accession) = @ARGV;
    my $records = read_fasta($fasta);
    @$records == 1 or die "unitas_refdump_extras.pl: $fasta must hold one record, has " . scalar(@$records) . "\n";
    $records->[0][0] =~ /^>\Q$accession\E(\s|$)/
        or die "unitas_refdump_extras.pl: $fasta is not $accession: $records->[0][0]\n";
    (my $seq = uc $records->[0][1]) =~ tr/U/T/;
    $seq =~ /^[ACGTN]+$/ or die "unitas_refdump_extras.pl: $fasta has letters other than ACGTN\n";
    $name =~ /^[^|>\s]+$/ or die "unitas_refdump_extras.pl: bad record name '$name'\n";
    my $dump = read_fasta($ncrna);
    for my $record (@$dump) {
        die "unitas_refdump_extras.pl: $ncrna already has >rRNA|$name\n" if $record->[0] eq ">rRNA|$name";
    }
    push @$dump, [">rRNA|$name", $seq];
    write_fasta($ncrna, $dump);  # staged in a .part file, checked, then renamed
    printf "added rRNA|%s (%d nt) to %s\n", $name, length $seq, $ncrna;
}
elsif ($command eq 'mask') {
    @ARGV == 2 or die "usage: unitas_refdump_extras.pl mask NCRNA_FAS CDNA_FAS\n";
    my ($ncrna_path, $cdna_path) = @ARGV;
    my $ncrna = read_fasta($ncrna_path);
    my %snorna;
    for my $record (@$ncrna) {
        next unless $record->[0] =~ /^>(snoRNA|scaRNA)\|/;
        my $seq = uc $record->[1];
        $snorna{$seq} = 1 if length($seq) >= $MIN_SNORNA && $seq =~ /^[ACGT]+$/;
    }
    unless (%snorna) {  # not expected in a real dump; reported in the build log, nothing masked
        print "masked 0 snoRNA/scaRNA sequences: no snoRNA or scaRNA records of at least $MIN_SNORNA nt in $ncrna_path\n";
        exit 0;
    }
    my $alternation = join '|', sort { length($b) <=> length($a) || $a cmp $b } keys %snorna;  # literals: Perl builds a trie
    my $pattern = qr/(?=($alternation))/;
    my $mask = sub {  # (records masked, copies, bases) of a record list; skips snoRNA and scaRNA records
        my ($records) = @_;
        my ($records_hit, $copies, $bases) = (0, 0, 0);
        for my $record (@$records) {
            next if $record->[0] =~ /^>(snoRNA|scaRNA)\|/;
            my $seq = uc $record->[1];
            my @hits;
            while ($seq =~ /$pattern/g) { push @hits, [$-[0], length $1]; }
            next unless @hits;
            my $masked = $record->[1];
            for my $hit (@hits) {
                my $before = substr($masked, $hit->[0], $hit->[1]);
                $bases += ($before =~ tr/Nn//c);
                substr($masked, $hit->[0], $hit->[1]) = 'N' x $hit->[1];
            }
            $record->[1] = $masked;
            $records_hit++;
            $copies += @hits;
        }
        return ($records_hit, $copies, $bases);
    };
    my @in_ncrna = $mask->($ncrna);
    my $cdna = read_fasta($cdna_path);
    my @in_cdna = $mask->($cdna);
    write_fasta($ncrna_path, $ncrna);
    write_fasta($cdna_path, $cdna);
    printf "masked %d snoRNA/scaRNA sequences: ncRNA.fas %d records, %d copies, %d nt; cDNA.fas %d records, %d copies, %d nt\n",
        scalar(keys %snorna), @in_ncrna, @in_cdna;
}
else {
    die "usage: unitas_refdump_extras.pl add45s NCRNA_FAS PRE_RRNA_FASTA NAME ACCESSION | mask NCRNA_FAS CDNA_FAS\n";
}
