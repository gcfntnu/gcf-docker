#!/usr/bin/perl -0 -i
# Exit codes for upstream unitas_1.9.2.pl (d-gebert/unitas bd87b65), applied in Dockerfile-1.9.2:
#   perl -0 -i exit-codes-1.9.2.pl unitas_1.9.2.pl
#
# Upstream ends every error with a bare `exit;` (status 0), and the parent process ignores how its
# per-file workers ended, so workflows cannot see a failed run. This changes only exit statuses:
#   - every `exit;` and the adapter-length `exit }` become exit 1,
#   - the five normal ends (-h, -show_options, -diffexpr, -supp_spec, -refdump) become exit 0,
#   - the parent exits 1 when any worker exited non-zero.
# Also sets $unitas_version to 1.9.2 (upstream left "1.9.1" in unitas_1.9.2.pl).
# Each edit must match the expected number of times, so a changed script fails the build.
use strict;
use warnings;

sub edit {
    my ( $name, $want, $n ) = @_;
    die "exit-codes-1.9.2.pl: $name: expected $want match(es), found $n\n" if $n != $want;
}

while ( my $script = <> ) {
    edit( 'exit; -> exit 1;', 37, $script =~ s/\bexit;/exit 1;/g );
    edit( 'adapter length exit', 1, $script =~ s/(should not be shorter than 5 nt\.[^\n]*; exit) \}/$1 1 }/ );

    my $normal = 0;
    $normal += $script =~ s/(\n\s*print \$usage;\n\s*)exit 1;/$1exit 0;/;
    $normal += $script =~ s/(\n\s*print \$usage_all_options;\n\s*)exit 1;/$1exit 0;/;
    $normal += $script =~ s/(\n\s*diff_expr\(\);\n\s*)exit 1;/$1exit 0;/;
    $normal += $script =~ s/(use a closely related species instead\.[^\n]*\n\s*)exit 1;/$1exit 0;/;
    $normal += $script =~ s/(\n\s*\$download_reference = 1;\n\s*load_reference_sequences\(\);\n\s*)exit 1;/$1exit 0;/;
    edit( 'normal ends -> exit 0', 5, $normal );

    edit( 'worker status', 1, $script =~ s/(foreach \$pid \(\@childs\) \{\n\s*waitpid\( \$pid, 0 \);)/$1\n    \$failed_workers++ if \$? != 0;/ );
    edit( 'parent exit', 1, $script =~ s/\n(sub process_file \{)/\nif (\$failed_workers) {\n    print "\\nERROR! Annotation failed for \$failed_workers input file(s).\\n\\n";\n    exit 1;\n}\nexit 0;\n\n$1/ );

    edit( 'version', 1, $script =~ s/\$unitas_version = "1\.9\.1";/\$unitas_version = "1.9.2";/ );
    print $script;
}
