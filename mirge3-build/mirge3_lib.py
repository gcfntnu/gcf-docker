#!/usr/bin/env python3
"""Generators for miRge3 0.1.4 libraries (used by build_mirge3_lib.sh).

miRge-build only indexes the FASTA files it is given and copies the miRNA GFF. This module writes
the inputs it needs and the files it does not create, in the formats of the miRge3 SourceForge
libraries (2020):

  mirna         species mature/hairpin FASTA, mature BED (genomic, from the GFF), GFF copy
  mirna-finish  SNP variants, mirna index FASTA, SNP pseudo FASTA, merges, repeat-element list
  rmsk-bed      UCSC rmsk.txt.gz -> BED with UCSC-style transcript ids (repName, repName_dup1, ...)
  ncrna         Ensembl ncRNA and cDNA FASTA -> snoRNA (identical sequences collapsed), rRNA
                (rRNA and rRNA_pseudogene, plus --extra-rrna: RefSeq 18S, 5.8S, 28S), others, mRNA
                (cDNA without rRNA_pseudogene)
  trna          GtRNAdb mature tRNAs (+CCA) and 100 nt genomic trailers (pre-tRNA)
  mt-trna       Ensembl Mt_tRNA genes from the ncRNA FASTA (input for tRNAscan-SE -M vert)
  trna-human    human tRNA set for --tRNA-frag: GtRNAdb nuclear tRNAs (structures from its
                tRNAscan-SE detailed.ss), Ensembl mitochondrial tRNAs (structures from tRNAscan-SE),
                trailers, and the SourceForge tRF clusters that still fit (gcf_trna_changes.tsv)
  fasta-dna     FASTA to upper-case DNA with first-token names (spike-ins, mRNA)

Formats reproduced (from the SourceForge human library):
  * mirna index: every mature miRNA (or its SNP variants) with 2 nt upstream and 6 nt downstream
    flanks from its precursor (miRNA_miRge_format, as miRge-build).
  * SNP variants: <name>.SNPC is the reference allele; each alternative allele of each SNV inside
    the mature sequence is <name>.SNPA, .SNPB, .SNPD, ... (C skipped).
  * merges: one line per group, "<group>,<member>,<member>,...". A group is a miRNA with SNP
    variants (members: its variants) and/or miRNAs with identical mature sequences.
  * SNP pseudo FASTA: the mirna index records without flanks, plus one record per group (group
    name, reference sequence).
  * repetitive elements: '<miRNA>,gene_id "<repName>"; transcript_id "<id>";' per overlap.

Only the Python standard library is used, so the unit tests run without the image.
"""
import argparse
import gzip
import re
import shutil
import subprocess
import sys
import tarfile
from collections import Counter, OrderedDict, defaultdict
from pathlib import Path

SNP_LETTERS = 'ABDEFGHIJKLMNOPQRSTUVWXYZ'  # C marks the reference allele
COMPLEMENT = str.maketrans('ACGTN', 'TGCAN')


def die(msg):
    sys.exit(f'mirge3_lib: {msg}')


def open_text(path):
    path = str(path)
    return gzip.open(path, 'rt') if path.endswith('.gz') else open(path)


def read_fasta(path):
    """[(header without '>', sequence)] in file order."""
    records, header, chunks = [], None, []
    with open_text(path) as fh:
        for line in fh:
            line = line.rstrip('\r\n')
            if line.startswith('>'):
                if header is not None:
                    records.append((header, ''.join(chunks)))
                header, chunks = line[1:], []
            elif line:
                if header is None:
                    die(f'{path}: sequence before the first header')
                chunks.append(line.strip())
    if header is not None:
        records.append((header, ''.join(chunks)))
    return records


def write_fasta(path, records):
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    with open(path, 'w') as fh:
        for name, seq in records:
            fh.write(f'>{name}\n{seq}\n')


def to_dna(seq):
    return seq.upper().replace('U', 'T')


def revcomp(seq):
    return seq.translate(COMPLEMENT)[::-1]


def mirge_flanks(hairpin, mature):
    """(prefix, suffix) around the first occurrence of mature in hairpin, as miRge-build's
    miRNA_miRge_format (2 nt upstream, 6 nt downstream); None if mature is not in hairpin."""
    start = hairpin.find(mature)
    if start < 0:
        return None
    end = start + len(mature)
    return hairpin[:start][-2:], hairpin[end:][:6]


def gff_records(path):
    """(seqid, type, start, end, strand, {attr: value}) for each feature line."""
    out = []
    with open_text(path) as fh:
        for line in fh:
            if line.startswith('#') or not line.strip():
                continue
            f = line.rstrip('\n').split('\t')
            if len(f) < 9:
                die(f'{path}: not a GFF line: {line.strip()}')
            attrs = dict(kv.split('=', 1) for kv in f[8].strip().strip(';').split(';') if '=' in kv)
            out.append((f[0], f[2], int(f[3]), int(f[4]), f[6], attrs))
    return out


def mirgenedb_precursor(name):
    """Hsa-Let-7-P1b_5p / Hsa-Let-7-P1b_3p* -> Hsa-Let-7-P1b_pre."""
    return re.sub(r'_(5p|3p)\*?$', '_pre', name)


def strip_species_prefix(name):
    """hsa-miR-320b -> 320b, Hsa-Mir-430-P25_5p -> 430-P25_5p (for group names)."""
    return re.sub(r'^[A-Za-z]{3,4}-(miR|let|Mir|Let|mir)-', '', name)


def group_name(members):
    first = members[0]
    return '/'.join([first] + [strip_species_prefix(m) for m in members[1:]])


# --------------------------------------------------------------------------------------------
# mirna: species FASTA, mature BED, GFF copy
# --------------------------------------------------------------------------------------------

def cmd_mirna(args):
    lib, work, org, db = Path(args.lib), Path(args.work), args.org, args.db
    work.mkdir(parents=True, exist_ok=True)
    if db == 'miRBase':
        prefix = args.code + '-'
        recs = [(h.split()[0], h.split()[1], to_dna(s)) for h, s in read_fasta(args.mature) if h.startswith(prefix)]
        hairpin = [(h, to_dna(s)) for h, s in read_fasta(args.hairpin) if h.startswith(prefix)]
        # miRBase can give one name to different mature sequences (23.1: rno-miR-3084b-3p,
        # MIMAT0035742 and MIMAT0035744); those get the accession appended to stay unique.
        clash = {n for n, c in _counts(n for n, _, _ in recs).items() if c > 1}
        mature = [(f'{n}_{acc}' if n in clash else n, s) for n, acc, s in recs]
        accession = {acc: name for (_, acc, _), (name, _) in zip(recs, mature)}
        with open(work / f'{org}_mature_{db}.accessions.tsv', 'w') as fh:
            for acc, name in accession.items():
                fh.write(f'{acc}\t{name}\n')
        if clash:
            print(f'{db} {args.code}: names shared by different accessions, accession appended: '
                  f'{sorted(clash)}', file=sys.stderr)
    else:
        mature = [(h.split()[0], to_dna(s)) for f in [args.mature] + (args.star or []) for h, s in read_fasta(f)]
        hairpin = [(h.split()[0], to_dna(s)) for h, s in read_fasta(args.hairpin)]
        accession = None
    if not mature or not hairpin:
        die(f'no {args.code} {db} sequences (mature {len(mature)}, hairpin {len(hairpin)})')
    dup = [n for n, c in _counts(n for n, _ in mature).items() if c > 1]
    if dup:
        die(f'duplicate mature names: {dup[:5]}')
    names = {n for n, _ in mature}
    write_fasta(lib / 'fasta.Libs' / f'{org}_mature_{db}.fa', mature)
    write_fasta(work / f'{org}_hairpin_{db}.fa', hairpin)
    gff = gff_records(args.gff)
    bed, missing = [], set(names)
    for seqid, ftype, start, end, strand, attrs in gff:
        if ftype != 'miRNA':
            continue
        name = accession.get(attrs.get('ID')) if accession is not None else attrs.get('ID')
        if name in names:
            bed.append((ucsc_chrom(seqid), start - 1, end, name, strand))
            missing.discard(name)
    bed.sort(key=lambda r: (r[0], r[1], r[2], r[3]))
    with open(work / f'{org}_mature_{db}.bed', 'w') as fh:
        for seqid, start, end, name, strand in bed:
            fh.write(f'{seqid}\t{start}\t{end}\t{name}\t0\t{strand}\n')
    (lib / 'annotation.Libs').mkdir(parents=True, exist_ok=True)
    with open_text(args.gff) as src, open(lib / 'annotation.Libs' / f'{org}_{db}.gff3', 'w') as dst:
        dst.write(src.read())
    print(f'{db} {args.code}: {len(mature)} mature, {len(hairpin)} hairpin, {len(bed)} mature loci, '
          f'{len(missing)} mature without locus', file=sys.stderr)


def _counts(items):
    c = defaultdict(int)
    for i in items:
        c[i] += 1
    return c


# --------------------------------------------------------------------------------------------
# mirna-finish: SNP variants, mirna index, pseudo FASTA, merges, repeats
# --------------------------------------------------------------------------------------------

def read_bed(path):
    out = []
    with open(path) as fh:
        for line in fh:
            if line.strip():
                f = line.rstrip('\n').split('\t')
                out.append((f[0], int(f[1]), int(f[2]), f[3], f[5]))
    return out


def ucsc_chrom(c):
    """2 -> chr2, MT -> chrM; chr2 unchanged (UCSC RepeatMasker uses chr names)."""
    if c.startswith('chr'):
        return c
    return 'chrM' if c in ('MT', 'M') else 'chr' + c


def norm_chrom(c):
    """chr1 / 1 -> 1, chrM / MT / M -> MT (to match GFF and VCF contig names)."""
    c = c[3:] if c.startswith('chr') else c
    return 'MT' if c in ('M', 'MT') else c


def snvs_per_mature(bed, snp_rows, mature_seq):
    """{mature name: sorted [(offset, alt)]} for SNVs inside mature loci whose reference base
    matches the mature sequence. snp_rows: (chrom, pos 1-based, ref, alts)."""
    by_chrom = defaultdict(list)
    for chrom, pos, ref, alts in snp_rows:
        by_chrom[norm_chrom(chrom)].append((pos, ref, alts))
    found, mismatched = defaultdict(set), 0
    for seqid, start, end, name, strand in bed:
        seq = mature_seq.get(name)
        if seq is None or end - start != len(seq):
            continue  # locus does not match the sequence length (e.g. other assembly patch)
        for pos, ref, alts in by_chrom.get(norm_chrom(seqid), ()):
            if not (start < pos <= end) or len(ref) != 1:
                continue
            offset = pos - 1 - start if strand == '+' else end - pos
            r = ref.upper() if strand == '+' else revcomp(ref.upper())
            if seq[offset] != r:
                mismatched += 1
                continue
            for alt in alts:
                if len(alt) != 1 or alt.upper() not in 'ACGT':
                    continue
                a = alt.upper() if strand == '+' else revcomp(alt.upper())
                if a != r:
                    found[name].add((offset, a))
    return {n: sorted(v) for n, v in found.items()}, mismatched


def snp_variants(name, seq, snvs):
    """[(name.SNPC, seq), (name.SNPA, seq with first alt), ...]."""
    if len(snvs) > len(SNP_LETTERS):
        die(f'{name}: {len(snvs)} SNV alleles, more than {len(SNP_LETTERS)} letters')
    out = [(f'{name}.SNPC', seq)]
    for letter, (offset, alt) in zip(SNP_LETTERS, snvs):
        out.append((f'{name}.SNP{letter}', seq[:offset] + alt + seq[offset + 1:]))
    return out


def _acc_number(acc):
    return int(re.sub(r'\D', '', acc) or 0)


def precursor_for(db, name, seq, gff, hairpins, hairpin_names=None):
    """Hairpin sequence giving the flanks of a mature miRNA, or None.

    miRBase: the precursors the GFF derives the mature from (lowest accession first). Matures
    without a locus (precursor not placed on the assembly) fall back to the hairpins containing the
    sequence: the one named like the mature (rno-miR-335-5p -> rno-mir-335), else the lowest
    accession. hairpin_names: {accession: hairpin name}."""
    if db == 'MirGeneDB':
        hp = hairpins.get(mirgenedb_precursor(name))
        return hp if hp and seq in hp else None
    for acc in sorted(gff.get(name, ()), key=_acc_number):
        hp = hairpins.get(acc)
        if hp and seq in hp:
            return hp
    containing = sorted((a for a, hp in hairpins.items() if seq in hp), key=_acc_number)
    if not containing:
        return None
    stem = re.sub(r'_MIMAT\d+$', '', name)
    stem = re.sub(r'-[35]p$', '', stem).lower()
    named = [a for a in containing if (hairpin_names or {}).get(a, '').lower() == stem]
    return hairpins[(named or containing)[0]]


def read_snp_rows(path):
    rows = []
    if path:
        with open(path) as fh:
            for line in fh:
                if line.strip() and not line.startswith('#'):
                    chrom, pos, ref, alt = line.rstrip('\n').split('\t')[:4]
                    rows.append((chrom, int(pos), ref, alt.split(',')))
    return rows


def build_groups(mature, snvs):
    """[(group name, [base names])] for SNP miRNAs and identical mature sequences, in mature order."""
    by_seq = OrderedDict()
    for name, seq in mature:
        by_seq.setdefault(seq, []).append(name)
    groups = []
    for seq, names in by_seq.items():
        if len(names) > 1 or names[0] in snvs:
            groups.append((names[0] if len(names) == 1 else group_name(names), names))
    return groups


def cmd_mirna_finish(args):
    lib, work, org, db = Path(args.lib), Path(args.work), args.org, args.db
    mature = read_fasta(lib / 'fasta.Libs' / f'{org}_mature_{db}.fa')
    mature_seq = dict(mature)
    if db == 'miRBase':
        hp_records = read_fasta(work / f'{org}_hairpin_{db}.fa')
        hairpins = {h.split()[1]: s for h, s in hp_records}
        hairpin_names = {h.split()[1]: h.split()[0] for h, _ in hp_records}
        accession = dict(line.rstrip('\n').split('\t') for line in open(work / f'{org}_mature_{db}.accessions.tsv'))
        derives = defaultdict(list)
        for _, ftype, _, _, _, attrs in gff_records(args.gff):
            if ftype == 'miRNA' and 'Derives_from' in attrs and attrs.get('ID') in accession:
                derives[accession[attrs['ID']]].append(attrs['Derives_from'])
    else:
        hairpins = {h.split()[0]: s for h, s in read_fasta(work / f'{org}_hairpin_{db}.fa')}
        hairpin_names, derives = None, {}
    bed = read_bed(args.snv_bed or work / f'{org}_mature_{db}.bed')
    snvs, mismatched = snvs_per_mature(bed, read_snp_rows(args.snps), mature_seq)
    # More alleles than SNP letters (dbSNP 157: hsa-miR-8078-3p, 45 COMMON alleles in 23 nt, a
    # hypervariable locus): no variants for that miRNA rather than an arbitrary subset.
    too_many = sorted(n for n, v in snvs.items() if len(v) > len(SNP_LETTERS))
    for n in too_many:
        print(f'{db}: {n}: {len(snvs[n])} SNV alleles, more than {len(SNP_LETTERS)} letters; no SNP variants',
              file=sys.stderr)
        del snvs[n]

    index, pseudo, unflanked = [], [], 0
    for name, seq in mature:
        hp = precursor_for(db, name, seq, derives, hairpins, hairpin_names)
        flanks = mirge_flanks(hp, seq) if hp else None
        if flanks is None:
            flanks, unflanked = ('', ''), unflanked + 1
        records = snp_variants(name, seq, snvs[name]) if name in snvs else [(name, seq)]
        for rname, rseq in records:
            index.append((rname, flanks[0] + rseq + flanks[1]))
            pseudo.append((rname, rseq))

    groups = build_groups(mature, snvs)
    with open(lib / 'annotation.Libs' / f'{org}_merges_{db}.csv', 'w') as fh:
        for gname, names in groups:
            members = []
            for n in names:
                members += [r for r, _ in snp_variants(n, mature_seq[n], snvs[n])] if n in snvs else [n]
            fh.write(','.join([gname] + members) + '\n')
            pseudo.append((gname, mature_seq[names[0]]))
    write_fasta(work / f'{org}_mirna_{db}.fa', index)
    write_fasta(lib / 'fasta.Libs' / f'{org}_mirna_SNP_pseudo_{db}.fa', pseudo)

    rep_lines = OrderedDict()
    if args.repeats:
        with open(args.repeats) as fh:
            for line in fh:
                f = line.rstrip('\n').split('\t')
                if len(f) >= 11:  # mature BED6 + rmsk BED (chrom start end repName transcript_id)
                    rep_lines.setdefault(f'{f[3]},gene_id "{f[9]}"; transcript_id "{f[10]}";', None)
    with open(lib / 'annotation.Libs' / f'{org}_miRNAs_in_repetitive_element_{db}.csv', 'w') as fh:
        for line in rep_lines:
            fh.write(line + '\n')
    n_alleles = sum(len(v) for v in snvs.values())
    print(f'{db}: {len(mature)} mature, {len(snvs)} with SNVs ({n_alleles} alleles, {mismatched} ref '
          f'mismatches skipped), {len(index)} index records, {unflanked} without precursor flanks, '
          f'{len(groups)} groups, {len(rep_lines)} repeat overlaps', file=sys.stderr)


# --------------------------------------------------------------------------------------------
# rmsk-bed, ncrna, trna, fasta-dna
# --------------------------------------------------------------------------------------------

def cmd_rmsk_bed(args):
    """UCSC rmsk.txt(.gz) columns: bin swScore milliDiv milliDel milliIns genoName genoStart
    genoEnd genoLeft strand repName repClass repFamily ... -> BED with UCSC GTF-style ids."""
    seen = defaultdict(int)
    with open_text(args.rmsk) as fh, open(args.out, 'w') as out:
        for line in fh:
            f = line.rstrip('\n').split('\t')
            chrom, start, end, strand, rep = f[5], f[6], f[7], f[9], f[10]
            k = seen[rep]
            seen[rep] += 1
            tid = rep if k == 0 else f'{rep}_dup{k}'
            out.write(f'{chrom}\t{start}\t{end}\t{rep}\t{tid}\t{strand}\n')


def biotype(header):
    m = re.search(r'transcript_biotype:(\S+)', header)
    return m.group(1) if m else ''


def cmd_ncrna(args):
    """rRNA_pseudogene: Ensembl moved most human rRNA genes there (116: 71 rRNA, 516
    rRNA_pseudogene, in the cDNA file); they stay in the rRNA index as in the old libraries."""
    snorna, rrna, others, mrna = OrderedDict(), [], [], []
    for header, seq in read_fasta(args.cdna):
        if biotype(header) == 'rRNA_pseudogene':
            rrna.append((header, to_dna(seq)))
        else:
            mrna.append((header, to_dna(seq)))
    for header, seq in read_fasta(args.ncrna):
        seq, bt = to_dna(seq), biotype(header)
        if bt == 'snoRNA':
            snorna.setdefault(seq, []).append(header)
        elif bt in ('rRNA', 'rRNA_pseudogene'):
            rrna.append((header, seq))
        elif bt != 'miRNA':
            others.append((header, seq))
    sno = []
    for seq, headers in snorna.items():
        first = headers[0].split(' ', 1)
        ids = '/'.join(h.split()[0] for h in headers)
        sno.append((ids + (' ' + first[1] if len(first) > 1 else ''), seq))
    n_ensembl, extra = len(rrna), extra_rrna(args.extra_rrna or [])
    ensembl_seqs = {s for _, s in rrna}
    rrna += extra
    out = Path(args.outdir)
    write_fasta(out / 'snorna.fa', sno)
    write_fasta(out / 'rrna.fa', rrna)
    write_fasta(out / 'ncrna_others.fa', others)
    write_fasta(out / 'mrna.fa', mrna)
    print(f'ncRNA: {len(sno)} snoRNA ({sum(map(len, snorna.values()))} before collapsing), '
          f'{n_ensembl} rRNA (with rRNA_pseudogene), {len(others)} others, {len(mrna)} mRNA', file=sys.stderr)
    if extra:
        same = [h.split()[0] for h, s in extra if s in ensembl_seqs]
        print(f'rRNA: + {len(extra)} RefSeq ({", ".join(h.split()[0] for h, _ in extra)}); '
              f'{len(same)} identical to an Ensembl rRNA {same}', file=sys.stderr)


def extra_rrna(paths):
    """rDNA rRNAs Ensembl doesn't annotate (18S, 5.8S, 28S; gcf-docker#54): one NCBI FASTA record per
    file, named by its accession.version, as upper-case DNA."""
    out = []
    for p in paths:
        recs = read_fasta(p)
        if len(recs) != 1:
            die(f'{p}: expected one rRNA record, found {len(recs)}')
        header, seq = recs[0]
        seq = to_dna(seq)
        if not re.fullmatch(r'[A-Z]{1,6}_?\d+\.\d+', header.split()[0] if header else ''):
            die(f'{p}: header must start with accession.version, got {header!r}')
        if not seq or set(seq) - set('ACGT'):
            die(f'{p}: {header.split()[0]} is empty or has bases other than ACGT')
        out.append((header, seq))
    return out


def read_genome(path, wanted, rename):
    seqs, name, chunks = {}, None, []
    with open_text(path) as fh:
        for line in fh:
            if line.startswith('>'):
                if name in wanted:
                    seqs[name] = ''.join(chunks)
                raw = line[1:].split()[0]
                name, chunks = rename.get(raw, raw), []
            elif name in wanted:
                chunks.append(line.strip())
    if name in wanted:
        seqs[name] = ''.join(chunks)
    return seqs


def add_cca(seq):
    """Mature tRNA with the post-transcriptional CCA tail. GtRNAdb mature sequences never include
    it, but some end in CCA by chance (discriminator A after CC), so it is always added. (Builder
    1.0.0 skipped those; see gcf-docker#53.)"""
    return seq + 'CCA'


def trailers(loci, genome, length):
    """pre-tRNA records: the genomic `length` nt downstream of each (chrom, start0, end, name, strand)
    locus, named pre_<name>_trailer, and the names whose contig is not in `genome`."""
    pre, skipped = [], []
    for chrom, start, end, name, strand in loci:
        g = genome.get(chrom)
        if g is None:
            skipped.append(name)
            continue
        trailer = g[end:end + length] if strand == '+' else revcomp(g[max(0, start - length):start])
        pre.append((f'pre_{name}_trailer', trailer.upper()))
    return pre, skipped


def cmd_trna(args):
    mature = [(header.split()[0], add_cca(to_dna(seq))) for header, seq in read_fasta(args.mature)]
    names = {n for n, _ in mature}
    rename = {}
    for pair in args.rename or []:
        a, b = pair.split('=')
        rename[a] = b
    loci = []
    with open(args.bed) as fh:
        for line in fh:
            f = line.rstrip('\n').split('\t')
            full = f'{args.species_prefix}_{f[3]}'
            if full in names:
                loci.append((args.chrom_prefix + norm_chrom(f[0]) if args.chrom_prefix is not None else f[0],
                             int(f[1]), int(f[2]), full, f[5]))
    # mitochondrial (optional): Ensembl Mt_tRNA loci (+CCA) on --mt-genome (default --genome), named by
    # the amino acid and anticodon tRNAscan-SE calls, as in human
    if bool(args.mt_fasta) != bool(args.mt_ss):
        die('--mt-fasta and --mt-ss go together')
    mt = mito_trnas(args.mt_fasta, args.mt_ss, args.mt_slack) if args.mt_fasta else []
    if mt and any(norm_chrom(c) == 'MT' for c, *_ in loci):
        die('the GtRNAdb set has mitochondrial loci too; the Ensembl Mt_tRNA genes would double them')
    mt_path, mt_chroms = args.mt_genome or args.genome, {t['chrom'] for t in mt}
    genome = read_genome(args.genome, {c for c, *_ in loci} | (mt_chroms if mt_path == args.genome else set()), rename)
    pre, skipped = trailers(loci, genome, args.trailer)
    print(f'tRNA: {len(mature)} mature, {len(pre)} trailers, {len(skipped)} without genome contig '
          f'{skipped[:3]}', file=sys.stderr)
    if len(pre) < len(mature) * 0.9:
        die('fewer than 90% of the mature tRNAs got a trailer; check contig names')
    if mt:
        mt_genome = genome if mt_path == args.genome else read_genome(mt_path, mt_chroms, {})
        check_mito_genome(mt, mt_genome, args.trailer)
        mt_pre, _ = trailers([(t['chrom'], t['start'] - 1, t['end'], t['name'], t['strand']) for t in mt],
                             mt_genome, args.trailer)
        mature += [(t['name'], add_cca(t['seq'])) for t in mt]
        pre += mt_pre
        shorter = [f"{t['name']} ({t['sym']}; hit {t['hit']})" for t in mt if t['hit']]
        print(f'tRNA: {len(mt)} mitochondrial, Ensembl locus kept where the tRNAscan-SE hit is shorter: '
              f'{", ".join(shorter) or "none"}', file=sys.stderr)
    write_fasta(Path(args.outdir) / 'mature_trna.fa', mature)
    write_fasta(Path(args.outdir) / 'pre_trna.fa', pre)
    if mt:
        (Path(args.outdir) / 'mt_trna_shorter_hits.txt').write_text(''.join(s + '\n' for s in shorter))


# --------------------------------------------------------------------------------------------------
# human tRNA set for --tRNA-frag (mirge/libs/summary.py and mirge2_tRF_a2i.py in miRge3 0.1.4):
#   <org>_trna.str                     name, sequence, dot-bracket with XXX over the anticodon; miRge3
#                                      uses the length and anticodon position (5'/3' half vs tRF)
#   <org>_trna_aminoacid_anticodon.csv name,aa,anticodon for every mature and pre_ name (KeyError otherwise)
#   <org>_trna_deduplicated_list.csv   identical sequences, first name kept (the one-hit tRNA of a read)
#   <org>_tRF_infor.csv                clusters: positions on a tRNA or trailer; a read is assigned to
#                                      the nearest cluster on its one-hit tRNA within distance 8
#   <org>_tRF_merges.csv               merge group per cluster (tRF.Counts.csv rows; KeyError otherwise)
# The clusters were derived from data by the miRge authors and cannot be rebuilt; those that still
# lie at their position in the new sequences are carried over.

AA3 = dict(A='Ala', C='Cys', D='Asp', E='Glu', F='Phe', G='Gly', H='His', I='Ile', K='Lys', L='Leu',
           M='Met', N='Asn', P='Pro', Q='Gln', R='Arg', S='Ser', T='Thr', V='Val', W='Trp', Y='Tyr')
TRF_HEADER = 'tRNA cluster,locus,intron,RNA location,sequence,RNA sequence'
# the 22 tRNAs of vertebrate mitochondria (amino acid, anticodon), as tRNAscan-SE -M vert calls them
VERT_MT = frozenset(tuple(x.split('-')) for x in (
    'Phe-GAA Val-TAC Leu-TAA Ile-GAT Gln-TTG Met-CAT Trp-TCA Ala-TGC Asn-GTT Cys-GCA Tyr-GTA Ser-TGA '
    'Asp-GTC Lys-TTT Gly-TCC Arg-TCG His-GTG Ser-GCT Leu-TAG Glu-TTC Thr-TGT Pro-TGG').split())


def ensembl_contig(c):
    """UCSC hg38 contig -> Ensembl GRCh38 name: chr1 -> 1, chrM -> MT, chr1_KI270713v1_random ->
    KI270713.1, chrUn_GL000220v1 -> GL000220.1."""
    m = re.fullmatch(r'chr(?:\w+?_)?([A-Z]{2}\d+)v(\d+)(?:_random|_alt|_fix)?', c)
    return f'{m.group(1)}.{m.group(2)}' if m else norm_chrom(c)


def parse_trnascan_ss(text):
    """tRNAscan-SE secondary-structure output (-f, as GtRNAdb's *-tRNAs-detailed.ss) -> records:
    id (e.g. chr1.trna4), seqname, start, end, aa, anticodon, ac_start (1-based, on the precursor),
    intron ((start, end) on the precursor, or None), seq, str."""
    recs = []
    for block in re.split(r'\n\s*\n', text.strip()):
        head = re.match(r'((\S+)\.trna\d+) \((\d+)-(\d+)\)', block)
        typ = re.search(r'Type: (\S+)\s+Anticodon: (\S+) at (\d+)-(\d+)', block)
        seq = re.search(r'^Seq: (\S+)', block, re.M)
        st = re.search(r'^Str: (\S+)', block, re.M)
        if not (head and typ and seq and st):
            die(f'unexpected tRNAscan-SE block: {block[:120]!r}')
        intron = re.search(r'Possible intron: (\d+)-(\d+)', block)
        recs.append(dict(id=head.group(1), seqname=head.group(2), start=int(head.group(3)),
                         end=int(head.group(4)), aa=typ.group(1), anticodon=typ.group(2),
                         ac_start=int(typ.group(3)), seq=seq.group(1), str=st.group(1),
                         intron=(int(intron.group(1)), int(intron.group(2))) if intron else None))
    return recs


def mature_structure(rec, length):
    """(mature sequence, miRge3 structure, 1-based anticodon start) of a tRNAscan-SE record: intron
    removed, <> written as (), XXX over the anticodon, '.' up to `length` (the CCA tail)."""
    keep = range(len(rec['seq']))
    if rec['intron']:
        a, b = rec['intron']
        if a <= rec['ac_start'] + 2:
            die(f"{rec['id']}: intron {a}-{b} before the anticodon end")
        keep = [k for k in keep if not a - 1 <= k <= b - 1]
    mseq = to_dna(''.join(rec['seq'][k] for k in keep))
    mst = ''.join(rec['str'][k] for k in keep).replace('>', '(').replace('<', ')')
    ac = rec['ac_start'] - 1
    mst = mst[:ac] + 'XXX' + mst[ac + 3:]
    if len(mst) > length:
        die(f"{rec['id']}: structure ({len(mst)}) longer than the sequence ({length})")
    return mseq, mst + '.' * (length - len(mst)), ac + 1


def read_trna_str(path):
    """{name: (sequence, structure)} from a miRge3 <org>_trna.str."""
    lines = [line.strip() for line in open(path) if line.strip()]
    if len(lines) % 3 or not all(lines[i].startswith('>') for i in range(0, len(lines), 3)):
        die(f'{path}: not name/sequence/structure triplets')
    return {lines[i][1:]: (lines[i + 1], lines[i + 2]) for i in range(0, len(lines), 3)}


def read_gtrnadb_tar(path):
    """GtRNAdb <genome>-tRNAs.tar.gz -> {member suffix: text} for the files used."""
    want = ('-mature-tRNAs.fa', '-tRNAs.bed', '-tRNAs-detailed.ss', '-tRNAs_name_map.txt')
    out = {}
    with tarfile.open(path) as tar:
        for member in tar.getmembers():
            for suffix in want:
                if member.isfile() and member.name.endswith(suffix):
                    out[suffix] = tar.extractfile(member).read().decode()
    missing = [s for s in want if s not in out]
    if missing:
        die(f'{path}: no member ending in {missing}')
    return out


def fasta_text(text):
    records, header = [], None
    for line in text.splitlines():
        if line.startswith('>'):
            header = line[1:]
            records.append([header, ''])
        elif line.strip():
            records[-1][1] += line.strip()
    return [tuple(r) for r in records]


def identical_groups(names, seq_of):
    """Groups (2 or more names, in the given order) of identical sequences."""
    groups = OrderedDict()
    for n in names:
        groups.setdefault(seq_of[n], []).append(n)
    return [g for g in groups.values() if len(g) > 1]


def cluster_locus(trna, start, end, info):
    """Genomic locus of positions start..end (1-based) of a tRNA or pre_<tRNA>_trailer, as in the
    SourceForge tRF_infor.csv: '<chrom>:<lo>-<hi><strand>' (chrom 'mito' for MT; the CCA tail left
    out), and the tRNA's intron as '<lo>-<hi>' ('None' without one, and for trailers)."""
    pre = trna.startswith('pre_') and trna.endswith('_trailer')
    t = info[trna[4:-8] if pre else trna]
    gs, ge, strand = t['gs'], t['ge'], t['strand']
    intron = t['intron']
    ilen = intron[1] - intron[0] + 1 if intron else 0
    if pre:
        pos = [ge + start, ge + end] if strand == '+' else [gs - end, gs - start]
    else:
        glen = ge - gs + 1 - ilen
        end = min(end, glen)

        def genomic(p):
            q = p + ilen if intron and p >= intron[0] else p
            return gs + q - 1 if strand == '+' else ge - q + 1
        pos = [genomic(start), genomic(end)]
    if intron and not pre:
        a, b = intron
        ipos = [gs + a - 1, gs + b - 1] if strand == '+' else [ge - b + 1, ge - a + 1]
        intron_s = f'{min(ipos)}-{max(ipos)}'
    else:
        intron_s = 'None'
    return f"{t['label']}:{min(pos)}-{max(pos)}{strand}", intron_s


def mito_trnas(mt_fasta, mt_ss, slack=0):
    """Ensembl Mt_tRNA genes (mt-trna output) with their tRNAscan-SE -M vert calls -> one record per
    gene, in FASTA order: name (trnaMT_<Aa><anticodon>_MT_<strand>_<start>_<end>, Ensembl locus), sym,
    chrom, strand, start, end, seq (the Ensembl sequence, no CCA), rec (the tRNAscan-SE record) and
    hit ('a-b of n' when the hit is shorter than the locus, else None).
    Each gene needs exactly one hit with the Ensembl sequence, over the whole locus or, with `slack`,
    missing at most `slack` nt at either end (the locus is kept). The amino acid must match a gene
    symbol that encodes one (MT-TF, mt-Tf; rat symbols are GenBank accessions), and the (amino acid,
    anticodon) pairs must be the vertebrate ones, each once."""
    hits = defaultdict(list)
    for r in parse_trnascan_ss(Path(mt_ss).read_text()):
        hits[r['seqname']].append(r)
    out, seen = [], set()
    for gname, gseq in read_fasta(mt_fasta):
        sym, chrom, strand, start, end = gname.split(':')
        h = hits.get(gname, [])
        if not (len(h) == 1 and 1 <= h[0]['start'] <= 1 + slack and len(gseq) - slack <= h[0]['end'] <= len(gseq)):
            span = f'missing at most {slack} nt at either end' if slack else 'full-length'
            die(f'{gname}: expected one {span} tRNAscan-SE hit, got {[(x["start"], x["end"]) for x in h]}')
        r = h[0]
        if r['intron'] or to_dna(r['seq']) != gseq[r['start'] - 1:r['end']]:
            die(f'{gname}: tRNAscan-SE sequence differs from the Ensembl sequence')
        sym_aa = re.fullmatch(r'mt-t([a-z])\d?', sym, re.I)
        if sym_aa and AA3[sym_aa.group(1).upper()] != r['aa']:
            die(f'{gname}: tRNAscan-SE calls it {r["aa"]}')
        pair = (r['aa'], r['anticodon'])
        if pair not in VERT_MT or pair in seen:
            die(f'{gname}: tRNAscan-SE calls it {"-".join(pair)}, '
                f'{"a second time" if pair in seen else "not a vertebrate mitochondrial tRNA"}')
        seen.add(pair)
        partial = (r['start'], r['end']) != (1, len(gseq))
        out.append(dict(name=f"trnaMT_{r['aa']}{r['anticodon']}_MT_{strand}_{start}_{end}", sym=sym, chrom=chrom,
                        strand=strand, start=int(start), end=int(end), seq=gseq, rec=r,
                        hit=f"{r['start']}-{r['end']} of {len(gseq)}" if partial else None))
    return out


def check_mito_genome(mito, genome, length):
    """Each mito_trnas record's Ensembl sequence is its locus in `genome`, with a full `length` nt
    downstream for the trailer (none is cut at the end of the circular MT)."""
    for t in mito:
        g = genome.get(t['chrom'])
        if g is None:
            die(f"{t['name']}: no contig {t['chrom']} in the genome")
        s = g[t['start'] - 1:t['end']].upper()
        if (s if t['strand'] == '+' else revcomp(s)) != t['seq']:
            die(f"{t['name']}: Ensembl sequence differs from the genome")
        if (len(g) - t['end'] if t['strand'] == '+' else t['start'] - 1) < length:
            die(f"{t['name']}: less than {length} nt downstream on {t['chrom']} for the trailer")


def cmd_mt_trna(args):
    """Ensembl Mt_tRNA genes (ncRNA FASTA) -> FASTA named <symbol>:<chrom>:<strand>:<start>:<end>."""
    recs = OrderedDict()
    for header, seq in read_fasta(args.ncrna):
        if 'gene_biotype:Mt_tRNA' not in header:
            continue
        # chromosome:GRCh38:MT:577:647:1 (human, mouse), primary_assembly:GRCr8:MT:1:67:1 (rat)
        loc = re.search(r'\b(?:chromosome|primary_assembly):[^:\s]+:([^:\s]+):(\d+):(\d+):(-?1)\b', header)
        sym = re.search(r'gene_symbol:(\S+)', header)
        gene = re.search(r'gene:(\S+)', header)
        if not loc:
            die(f'no chromosome location in {header}')
        chrom, start, end, strand = loc.group(1), int(loc.group(2)), int(loc.group(3)), loc.group(4)
        name = f"{sym.group(1) if sym else gene.group(1)}:{chrom}:{'+' if strand == '1' else '-'}:{start}:{end}"
        recs.setdefault(name, to_dna(seq))
    if len(recs) != args.expect:
        die(f'{args.ncrna}: {len(recs)} Mt_tRNA genes, expected {args.expect}')
    write_fasta(args.out, list(recs.items()))
    print(f'Mt_tRNA: {len(recs)} genes from {args.ncrna}', file=sys.stderr)


def cmd_trna_human(args):
    org, changes = args.org, []
    gt = read_gtrnadb_tar(args.gtrnadb)
    # nuclear: GtRNAdb mature (+CCA), loci from its BED, structures from its tRNAscan-SE detailed.ss
    mature = [(h.split()[0], add_cca(to_dna(s))) for h, s in fasta_text(gt['-mature-tRNAs.fa'])]
    prefix = re.match(r'([A-Z][a-z]+_[a-z]+)_tRNA-', mature[0][0]).group(1)
    name_map = {}
    for line in gt['-tRNAs_name_map.txt'].splitlines()[1:]:
        f = line.split('\t')
        if len(f) >= 2:
            name_map[f[0]] = f'{prefix}_{f[1]}'
    ss = {name_map[r['id']]: r for r in parse_trnascan_ss(gt['-tRNAs-detailed.ss']) if r['id'] in name_map}
    bed = {}
    for line in gt['-tRNAs.bed'].splitlines():
        f = line.split('\t')
        if len(f) >= 6:
            bed[f'{prefix}_{f[3]}'] = (f[0], int(f[1]), int(f[2]), f[5])
    info, loci, nuclear, mito = {}, [], [], []
    for name, seq in mature:
        if name not in ss or name not in bed:
            die(f'{name}: not in the GtRNAdb detailed.ss or BED')
        mseq, st, ac = mature_structure(ss[name], len(seq))
        if add_cca(mseq) != seq:
            die(f'{name}: GtRNAdb detailed.ss sequence differs from the mature sequence')
        aa, anticodon = re.match(r'.*?_tRNA-([A-Za-z]+)-([ACGTN]{3})-', name).groups()
        chrom, s0, e, strand = bed[name]
        info[name] = dict(seq=seq, str=st, ac=ac, aa=aa, anticodon=anticodon, label=chrom, gs=s0 + 1, ge=e,
                          strand=strand, intron=ss[name]['intron'], source='GtRNAdb')
        loci.append((ensembl_contig(chrom), s0, e, name, strand))
        nuclear.append(name)
    # mitochondrial: Ensembl Mt_tRNA loci (+CCA), amino acid, anticodon and structure from tRNAscan-SE
    # (full-length hits only: the structure must cover the sequence)
    mt = mito_trnas(args.mt_fasta, args.mt_ss)
    for t in mt:
        r, name = t['rec'], t['name']
        _, st, ac = mature_structure(r, len(t['seq']) + 3)
        info[name] = dict(seq=add_cca(t['seq']), str=st, ac=ac, aa=r['aa'], anticodon=r['anticodon'], label='mito',
                          gs=t['start'], ge=t['end'], strand=t['strand'], intron=None, source=f"Ensembl {t['sym']}")
        loci.append((t['chrom'], t['start'] - 1, t['end'], name, t['strand']))
        mito.append(name)
    genome = read_genome(args.genome, {c for c, *_ in loci}, {})
    check_mito_genome(mt, genome, args.trailer)
    pre, skipped = trailers(loci, genome, args.trailer)
    if skipped:
        die(f'no genome contig for the trailers of {skipped}')
    pre_seq = dict(pre)
    write_fasta(Path(args.outdir) / 'mature_trna.fa', [(n, info[n]['seq']) for n in nuclear + mito])
    write_fasta(Path(args.outdir) / 'pre_trna.fa', pre)

    # annotation, in the order of the SourceForge files: nuclear names sorted, then MT by position
    order = sorted(nuclear) + sorted(mito, key=lambda n: info[n]['gs'])
    pres = [f'pre_{n}_trailer' for n in order]
    ann = Path(args.annotation)
    ann.mkdir(parents=True, exist_ok=True)
    with open(ann / f'{org}_trna.str', 'w') as fh:
        fh.writelines(f">{n}\n{info[n]['seq']}\n{info[n]['str']}\n" for n in order)
    with open(ann / f'{org}_trna_aminoacid_anticodon.csv', 'w') as fh:
        fh.writelines(f"{n},{info[n]['aa']},{info[n]['anticodon']}\n" for n in order)
        fh.writelines(f"{p},{info[n]['aa']},{info[n]['anticodon']}\n" for n, p in zip(order, pres))
    seq_of = {n: info[n]['seq'] for n in order}
    seq_of.update(pre_seq)
    dedup = identical_groups(order, seq_of) + identical_groups(sorted(pres), seq_of)
    with open(ann / f'{org}_trna_deduplicated_list.csv', 'w') as fh:
        fh.write('kept tRNA,tRNA list\n')
        fh.writelines(f"{g[0]},{'/'.join(g)}\n" for g in dedup)

    old_dir = Path(args.old_annotation)
    old = read_trna_str(old_dir / f'{org}_trna.str')
    rows = [line.rstrip('\n').split(',') for line in open(old_dir / f'{org}_tRF_infor.csv')]
    if ','.join(rows[0]) != TRF_HEADER:
        die(f'unexpected header in {old_dir}/{org}_tRF_infor.csv: {rows[0]}')
    rows = rows[1:]

    def base(t):  # tRNA of a tRNA or pre_<tRNA>_trailer name
        return t[4:-8] if t.startswith('pre_') and t.endswith('_trailer') else t

    def placed(r, t):  # (cluster sequence at its position of t, same locus as before)
        s, e = map(int, r[3].split('-'))
        return seq_of.get(t, '')[s - 1:e] == r[4], t in seq_of and cluster_locus(t, s, e, info) == (r[1], r[2])

    # renamed since the SourceForge set: an old name gone, one new name (not in the old set) with the same
    # sequence, and every cluster of the old name at the same position and genomic locus under the new name
    renamed = {}
    for o, (oseq, _) in old.items():
        cand = [n for n in order if n not in old and info[n]['seq'] == oseq]
        if o in info or len(cand) != 1:
            continue
        mine = [r for r in rows if base(r[0].split('_Cluster')[0]) == o]
        if all(placed(r, r[0].split('_Cluster')[0].replace(o, cand[0], 1)) == (True, True) for r in mine):
            renamed[o] = cand[0]
    was = {n: o for o, n in renamed.items()}

    # tRNAs compared with the SourceForge set; the anticodon must stay where it was
    for n in order:
        o = n if n in old else was.get(n)
        if o is None:
            changes.append(('tRNA', n, 'new', info[n]['source']))
            continue
        os_, ost = old[o]
        if os_ != info[n]['seq']:
            changes.append(('tRNA', n, 'changed', f"{info[n]['source']}; sequence differs from SourceForge"))
            continue
        if ost.find('XXX') + 1 != info[n]['ac']:
            die(f"{n}: anticodon at {info[n]['ac']}, SourceForge structure has it at {ost.find('XXX') + 1}")
        detail = 'same sequence and structure' if ost == info[n]['str'] else 'same sequence and anticodon; structure differs'
        if o != n:
            changes.append(('tRNA', n, 'renamed', f"{info[n]['source']}; SourceForge name {o}; {detail}"))
        else:
            changes.append(('tRNA', n, 'kept', f"{info[n]['source']}; {detail}"))
    for o in old:
        if o not in info and o not in renamed:
            changes.append(('tRNA', o, 'dropped', 'in the GtRNAdb BED but not its mature (high-confidence) set'
                            if o in bed else 'not in the new set'))

    # clusters: kept where the tRNA (or trailer) exists, under its new name if renamed, and the
    # sequence is at the same position
    kept, out_rows, new_name = set(), [], {}
    for r in rows:
        cname, old_locus, old_intron, loc, cseq = r[:5]
        t = cname.split('_Cluster')[0]
        if base(t) in renamed:
            t2 = t.replace(base(t), renamed[base(t)], 1)
            new_name[cname] = cname.replace(t, t2, 1)
            t = t2
        c2 = new_name.get(cname, cname)
        if t not in seq_of:
            changes.append(('cluster', cname, 'dropped', f'{t} not in the new set'))
            continue
        if not placed(r, t)[0]:
            changes.append(('cluster', cname, 'dropped', f'sequence not at {loc} of {t}'))
            continue
        s, e = map(int, loc.split('-'))
        locus, intron = cluster_locus(t, s, e, info)
        out_rows.append([c2, locus, intron, loc, cseq, seq_of[t]])
        kept.add(c2)
        detail = 'locus as before' if (locus, intron) == (old_locus, old_intron) else \
            f'locus {old_locus} {old_intron} -> {locus} {intron}'
        if c2 != cname:
            changes.append(('cluster', c2, 'renamed', f'SourceForge name {cname}; {detail}'))
        else:
            changes.append(('cluster', cname, 'kept', detail))
    with open(ann / f'{org}_tRF_infor.csv', 'w') as fh:
        fh.write(TRF_HEADER + '\n')
        fh.writelines(','.join(r) + '\n' for r in out_rows)
    groups = []
    for line in open(old_dir / f'{org}_tRF_merges.csv'):
        if not line.strip():
            continue
        gname, members = line.rstrip('\n').split(',', 1)
        members = [new_name.get(c, c) for c in members.split('/')]
        keep = [c for c in members if c in kept]
        if not keep:
            changes.append(('merge', gname, 'dropped', f'all {len(members)} clusters dropped'))
            continue
        groups.append((gname, keep))
        if len(keep) < len(members):
            changes.append(('merge', gname, 'pruned', f'{len(members) - len(keep)} of {len(members)} clusters dropped'))
    in_groups = Counter(c for _, k in groups for c in k)
    bad = sorted(c for c in kept if in_groups[c] != 1)
    if bad:
        die(f'clusters not in exactly one merge group: {bad[:5]}')
    with open(ann / f'{org}_tRF_merges.csv', 'w') as fh:
        fh.writelines(f"{g},{'/'.join(k)}\n" for g, k in groups)
    with open(args.changes, 'w') as fh:
        fh.write('kind\tname\tchange\tdetail\n')
        fh.writelines('\t'.join(c) + '\n' for c in changes)
    n = Counter((c[0], c[2]) for c in changes)
    print(f'tRNA: {len(nuclear)} GtRNAdb + {len(mito)} Ensembl MT mature, {len(pre)} trailers; SourceForge tRNAs '
          f"kept {n['tRNA', 'kept']}, renamed {n['tRNA', 'renamed']}, new {n['tRNA', 'new']}, dropped "
          f"{n['tRNA', 'dropped']}; clusters kept {n['cluster', 'kept']}, renamed {n['cluster', 'renamed']}, "
          f"dropped {n['cluster', 'dropped']}; merge groups {len(groups)} "
          f"({n['merge', 'dropped']} dropped, {n['merge', 'pruned']} pruned)", file=sys.stderr)


def trna_annotation_problems(ann, org, mature_names, pre_names):
    """What miRge3 0.1.4 --tRNA-frag would trip over in a library's tRNA annotation (KeyErrors in
    summary.py and mirge2_tRF_a2i.py, or tRNAs it cannot type)."""
    ann, problems = Path(ann), []
    names = set(mature_names) | set(pre_names)
    st = read_trna_str(ann / f'{org}_trna.str')
    problems += [f'{n}: not in {org}_trna.str' for n in mature_names if n not in st]
    problems += [f'{n}: structure needs one XXX and the sequence length' for n, (s, x) in st.items()
                 if x.count('XXX') != 1 or len(x) != len(s)]
    aa = {line.split(',')[0] for line in open(ann / f'{org}_trna_aminoacid_anticodon.csv') if line.strip()}
    problems += [f'{n}: no amino acid/anticodon row' for n in sorted(names - aa)]
    dedup = [line.rstrip('\n').split(',') for line in open(ann / f'{org}_trna_deduplicated_list.csv')][1:]
    problems += [f'{x}: in the deduplicated list, not in an index' for g in dedup for x in g[1].split('/')
                 if x not in names]
    clusters = {}
    for r in [line.rstrip('\n').split(',') for line in open(ann / f'{org}_tRF_infor.csv')][1:]:
        clusters[r[0]] = r[0].split('_Cluster')[0]
    problems += [f'{c}: tRNA {t} not in an index' for c, t in clusters.items() if t not in names]
    groups = Counter()
    for line in open(ann / f'{org}_tRF_merges.csv'):
        if line.strip():
            groups.update(line.rstrip('\n').split(',', 1)[1].split('/'))
    problems += [f'{c}: in {groups[c]} merge groups' for c in clusters if groups[c] != 1]
    problems += [f'{c}: in a merge group, not a cluster' for c in groups if c not in clusters]
    return problems


def index_names(prefix):
    if not shutil.which('bowtie-inspect'):
        die('bowtie-inspect is needed for --trna-annotation')
    out = subprocess.run(['bowtie-inspect', '-n', str(prefix)], check=True, capture_output=True, text=True).stdout
    return [line.split()[0] for line in out.splitlines() if line.strip()]


def cmd_fasta_dna(args):
    records = []
    for f in args.fasta:
        records += [(h if args.keep_header else h.split()[0], to_dna(s)) for h, s in read_fasta(f)]
    write_fasta(args.out, records)


DATABASES = ('miRBase', 'MirGeneDB')  # exact spelling: miRge3 builds file names from -d as given
INDEXES = ['genome', 'mature_trna', 'pre_trna', 'mrna', 'ncrna_others', 'rrna', 'snorna', 'spike-in']


def library_files(org, trna_annotation=False):
    """Files of <lib>/<org>/ that miRge3 0.1.4 opens for the options gcf-workflows uses."""
    files = []
    for db in DATABASES:
        files += [f'annotation.Libs/{org}_{db}.gff3',
                  f'annotation.Libs/{org}_merges_{db}.csv',
                  f'annotation.Libs/{org}_miRNAs_in_repetitive_element_{db}.csv',
                  f'fasta.Libs/{org}_mature_{db}.fa',
                  f'fasta.Libs/{org}_mirna_SNP_pseudo_{db}.fa',
                  f'index.Libs/{org}_hairpin_{db}.1.ebwt',
                  f'index.Libs/{org}_mirna_{db}.1.ebwt']
    files += [f'index.Libs/{org}_{i}.1.ebwt' for i in INDEXES]
    if trna_annotation:
        files += [f'annotation.Libs/{org}_{n}' for n in
                  ('trna.str', 'trna_aminoacid_anticodon.csv', 'trna_deduplicated_list.csv',
                   'tRF_infor.csv', 'tRF_merges.csv')]
    return files


def cmd_snv_bed(args):
    """Mature loci from another miRBase release's GFF (e.g. 22.1 on GRCm38, for dbSNP 150), by
    accession, for the SNV lookup only. Loci whose length differs from the sequence are left out."""
    work = Path(args.work)
    accession = dict(line.rstrip('\n').split('\t') for line in open(work / f'{args.org}_mature_miRBase.accessions.tsv'))
    seqs = dict(read_fasta(Path(args.lib) / 'fasta.Libs' / f'{args.org}_mature_miRBase.fa'))
    bed = set()
    for seqid, ftype, start, end, strand, attrs in gff_records(args.gff):
        name = accession.get(attrs.get('ID'))
        if ftype == 'miRNA' and name in seqs and end - start + 1 == len(seqs[name]):
            bed.add((ucsc_chrom(seqid), start - 1, end, name, strand))
    with open(args.out, 'w') as fh:
        for seqid, start, end, name, strand in sorted(bed):
            fh.write(f'{seqid}\t{start}\t{end}\t{name}\t0\t{strand}\n')
    print(f'SNV loci from {args.gff}: {len(bed)} loci for {len({b[3] for b in bed})} of {len(seqs)} mature',
          file=sys.stderr)


def cmd_check_lib(args):
    lib = Path(args.lib)
    missing = [f for f in library_files(args.org, args.trna_annotation) if not (lib / f).is_file()]
    empty = [f for f in library_files(args.org, args.trna_annotation)
             if (lib / f).is_file() and (lib / f).stat().st_size == 0 and 'repetitive' not in f]
    if missing or empty:
        die(f'library {lib} is incomplete: missing {missing}, empty {empty}')
    print(f'library {lib}: all {len(library_files(args.org, args.trna_annotation))} files present',
          file=sys.stderr)
    if args.trna_annotation:
        idx = lib / 'index.Libs'
        problems = trna_annotation_problems(lib / 'annotation.Libs', args.org,
                                            index_names(idx / f'{args.org}_mature_trna'),
                                            index_names(idx / f'{args.org}_pre_trna'))
        if problems:
            die(f'tRNA annotation of {lib}: {len(problems)} problems, e.g. {problems[:5]}')
        print(f'library {lib}: tRNA annotation consistent with the tRNA indexes', file=sys.stderr)


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    sub = p.add_subparsers(dest='cmd', required=True)
    s = sub.add_parser('mirna')
    for a in ('--db', '--org', '--code', '--mature', '--hairpin', '--gff', '--lib', '--work'):
        s.add_argument(a, required=True)
    s.add_argument('--star', nargs='*')
    s.set_defaults(func=cmd_mirna)
    s = sub.add_parser('mirna-finish')
    for a in ('--db', '--org', '--gff', '--lib', '--work'):
        s.add_argument(a, required=True)
    s.add_argument('--snps', help='chrom<TAB>pos<TAB>ref<TAB>alt[,alt] (bcftools query)')
    s.add_argument('--repeats', help='bedtools intersect -wa -wb of the mature BED and rmsk BED')
    s.add_argument('--snv-bed', help='mature loci the --snps were queried on (default: the mature BED)')
    s.set_defaults(func=cmd_mirna_finish)
    s = sub.add_parser('rmsk-bed')
    s.add_argument('--rmsk', required=True)
    s.add_argument('--out', required=True)
    s.set_defaults(func=cmd_rmsk_bed)
    s = sub.add_parser('ncrna')
    s.add_argument('--ncrna', required=True)
    s.add_argument('--cdna', required=True)
    s.add_argument('--outdir', required=True)
    s.add_argument('--extra-rrna', nargs='+', metavar='FASTA',
                   help='rRNAs to append to the rRNA index, one NCBI record per file (18S, 5.8S, 28S)')
    s.set_defaults(func=cmd_ncrna)
    s = sub.add_parser('trna')
    for a in ('--mature', '--bed', '--genome', '--outdir', '--species-prefix'):
        s.add_argument(a, required=True)
    s.add_argument('--chrom-prefix', default=None,
                   help="rewrite BED contigs to <prefix><1|MT> (e.g. '' for Ensembl names)")
    s.add_argument('--rename', nargs='*', help='genome contig renames, old=new')
    s.add_argument('--trailer', type=int, default=100)
    s.add_argument('--mt-fasta', help='mt-trna output: adds the mitochondrial tRNAs (with --mt-ss)')
    s.add_argument('--mt-ss', help='tRNAscan-SE -M vert -f output for --mt-fasta')
    s.add_argument('--mt-genome', help='genome FASTA with the Mt_tRNA contig (default --genome)')
    s.add_argument('--mt-slack', type=int, default=0,
                   help='nt the tRNAscan-SE hit may miss at either end of a locus (the locus is kept)')
    s.set_defaults(func=cmd_trna)
    s = sub.add_parser('mt-trna')
    s.add_argument('--ncrna', required=True, help='Ensembl ncRNA FASTA')
    s.add_argument('--out', required=True)
    s.add_argument('--expect', type=int, default=22, help='number of Mt_tRNA genes required')
    s.set_defaults(func=cmd_mt_trna)
    s = sub.add_parser('trna-human')
    s.add_argument('--gtrnadb', required=True, help='GtRNAdb <genome>-tRNAs.tar.gz')
    s.add_argument('--genome', required=True, help='Ensembl genome FASTA (contig names 1, MT, KI270713.1)')
    s.add_argument('--mt-fasta', required=True, help='mt-trna output')
    s.add_argument('--mt-ss', required=True, help='tRNAscan-SE -M vert -f output for --mt-fasta')
    s.add_argument('--old-annotation', required=True, help='SourceForge annotation.Libs (tRF clusters)')
    s.add_argument('--outdir', required=True, help='writes mature_trna.fa and pre_trna.fa')
    s.add_argument('--annotation', required=True, help='library annotation.Libs')
    s.add_argument('--changes', required=True, help='gcf_trna_changes.tsv')
    s.add_argument('--org', default='human')
    s.add_argument('--trailer', type=int, default=100)
    s.set_defaults(func=cmd_trna_human)
    s = sub.add_parser('fasta-dna')
    s.add_argument('--out', required=True)
    s.add_argument('--keep-header', action='store_true')
    s.add_argument('fasta', nargs='+')
    s.set_defaults(func=cmd_fasta_dna)
    s = sub.add_parser('snv-bed')
    for a in ('--org', '--gff', '--lib', '--work', '--out'):
        s.add_argument(a, required=True)
    s.set_defaults(func=cmd_snv_bed)
    s = sub.add_parser('check-lib')
    s.add_argument('--lib', required=True)
    s.add_argument('--org', required=True)
    s.add_argument('--trna-annotation', action='store_true')
    s.set_defaults(func=cmd_check_lib)
    args = p.parse_args(argv)
    args.func(args)


if __name__ == '__main__':
    main()
