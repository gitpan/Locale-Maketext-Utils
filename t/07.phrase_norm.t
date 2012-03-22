use Test::More tests => 373;

BEGIN {
    use_ok('Locale::Maketext::Utils::Phrase::Norm');
}

our $norm = Locale::Maketext::Utils::Phrase::Norm->new();
my $spec = Locale::Maketext::Utils::Phrase::Norm->new( 'WhiteSpace', { 'skip_defaults_when_given_filters' => 1 } );

our %global_all_warnings = (
    'special' => [],
    'default' => [],
);

our %global_filter_warnings = (
    'special' => [],
    'default' => [],
);

{

    # need to skip BeginUpper and EndPunc since it bumps 1 value i none test but not the others. Also Ellipsis so we don't have to factor in an extra change
    local $norm = Locale::Maketext::Utils::Phrase::Norm->new( qw(NonBytesStr WhiteSpace Grapheme Ampersand Markup), { 'skip_defaults_when_given_filters' => 1 } );

    run_32_tests(
        'filter_name'    => 'WhiteSpace',
        'filter_pos'     => 1,
        'original'       => "\xc2\xa0… I have \xc2\xa0  all \x00sorts of\tthings.\n ",
        'modified'       => " … I have all [comment,invalid char Ux0000]sorts of[comment,invalid char Ux0009]things.[comment,invalid char Ux000A]",
        'all_violations' => {
            'special' => [
                'Invalid whitespace, control, or invisible characters',
                'Beginning ellipsis space should be a normal space',
                'Beginning white space',
                'Trailing white space',
                'Multiple internal white space',
            ],
            'default' => undef,    # undef means "same as special"
        },
        'all_warnings'      => \%global_all_warnings,
        'filter_violations' => undef,                      # undef means "same as all_violations"
        'filter_warnings'   => \%global_filter_warnings,
        'return_value'      => {
            'special' => [ 0, 5,                             0, 1 ],
            'default' => undef, # undef means "same as special"
        },
        'diag' => 0,
    );
}

run_32_tests(
    'filter_name'    => 'NonBytesStr',
    'filter_pos'     => 0,
    'original'       => 'X \x{2026} N \N{WHITE SMILING FACE} u \u1F37A U U+22EE NU \N{U+22EE}.',
    'modified'       => 'X [comment,non bytes unicode string “\x{2026}”] N [comment,charnames type string “\N{WHITE SMILING FACE}”] u [comment,non bytes unicode string “\u1F37A”] U [comment,non bytes unicode string “U+22EE”] NU [comment,charnames type string “\N{U+22EE}”].',
    'all_violations' => {
        'special' => [
            'non-bytes string (perl)',
            'charname string (perl \N{})',
            'non-bytes string (non-perl)',
        ],
        'default' => undef,    # undef means "same as special"
    },
    'all_warnings'      => \%global_all_warnings,
    'filter_violations' => undef,                      # undef means "same as all_violations"
    'filter_warnings'   => \%global_filter_warnings,
    'return_value'      => {
        'special' => [ 0, 3,                             0, 1 ],
        'default' => undef, # undef means "same as special"
    },
    'diag' => 0,
);

run_32_tests(
    'filter_name'    => 'Grapheme',
    'filter_pos'     => 2,
    'original'       => 'X \xe2\x98\xba\xe2\x80\xa6® …',                             # not interpolated on purpose, we're looking at literal strings e.g. parsing this source code maketext("X \xe2\x98\xba\xe2\x80\xa6®") to find the string 'X \xe2\x98\xba\xe2\x80\xa6®' not 'X ☺…®'
    'modified'       => 'X [comment,grapheme “\xe2\x98\xba\xe2\x80\xa6”]® …',    # not interpolated on purpose, we're looking at literal strings …
    'all_violations' => {
        'special' => [
            'Contains grapheme notation',
        ],
        'default' => undef,                                                             # undef means "same as special"
    },
    'all_warnings'      => \%global_all_warnings,
    'filter_violations' => undef,                                                       # undef means "same as all_violations"
    'filter_warnings'   => \%global_filter_warnings,
    'return_value'      => {
        'special' => [ 0, 1,                             0, 1 ],
        'default' => undef, # undef means "same as special"
    },
    'diag' => 0,
);

run_32_tests(
    'filter_name'    => 'Ampersand',
    'filter_pos'     => 3,
    'original'       => 'Z &[output,chr,&] X[asis,ATchr(&)T®]Y Z[output,chr,38]Z?',
    'modified'       => 'Z [output,chr,38] [output,chr,38] X[asis,ATchr(38)T®]Y Z [output,chr,38] Z?',
    'all_violations' => {
        'special' => [
            'Prefer [output,chr,38] over [output,chr,&].',
            'Prefer chr(38) over chr(&).',
            'Ampersands need done via [output,chr,38].',
            'Ampersand should have one space before and/or after unless it is embedded in an asis().',
        ],
        'default' => undef,    # undef means "same as special"
    },
    'all_warnings'      => \%global_all_warnings,
    'filter_violations' => undef,                      # undef means "same as all_violations"
    'filter_warnings'   => \%global_filter_warnings,
    'return_value'      => {
        'special' => [ 0, 4,                             0, 1 ],
        'default' => undef, # undef means "same as special"
    },
    'diag' => 0,
);

run_32_tests(
    'filter_name'    => 'Markup',
    'filter_pos'     => 4,
    'original'       => q{Z<'""'><>!},
    'modified'       => 'Z[output,chr,60][output,chr,39][output,chr,34][output,chr,34][output,chr,39][output,chr,62][output,chr,60][output,chr,62]!',
    'all_violations' => {
        'special' => [
            'Contains markup related characters',
        ],
        'default' => undef,    # undef means "same as special"
    },
    'all_warnings' => {
        'default' => [
            'consider if, instead of using a straight apostrophe, using ‘’ for single quoting and ’ for an apostrophe is the right thing here (i.e. instead of bracket notation)',
            'consider if, instead of using straight double quotes, using “” is the right thing here (i.e. instead of bracket notation)',
        ],
        'special' => undef,    # undef means "same as default"
    },
    'filter_violations' => undef,    # undef means "same as all_violations"
    'filter_warnings'   => {
        'default' => [
            'consider if, instead of using a straight apostrophe, using ‘’ for single quoting and ’ for an apostrophe is the right thing here (i.e. instead of bracket notation)',
            'consider if, instead of using straight double quotes, using “” is the right thing here (i.e. instead of bracket notation)',
        ],
        'special' => undef,          # undef means "same as default"
    },
    'return_value' => {
        'special' => [ 0, 1,                             2, 1 ],
        'default' => undef, # undef means "same as special"
    },
    'diag' => 0,
);
{
    my $ell = Locale::Maketext::Utils::Phrase::Norm->new( 'Ellipsis', { 'skip_defaults_when_given_filters' => 1 } );
    for my $good (
        ' … I am … good, you …',                                                    # normal spaces
        ' … I am … good, you …',                                                # character (OSX: ⌥space)
        ' …[output,nbsp]I am[output,nbsp]…[output,nbsp]good, you[output,nbsp]…',    # visual [output,nbsp]
      ) {
        my $valid = $ell->normalize($good);
        ok( $valid->get_status(),             "valid: RES get_status()" );
        ok( !$valid->filters_modify_string(), "valid: RES filters_modify_string()" );
        is( $valid->get_warning_count(),   0, "valid: RES get_warning_count()" );
        is( $valid->get_violation_count(), 0, "valid: RES get_violation_count()" );
    }
}
{

    # need to skip BeginUpper and Whitespace since it bumps 1 value in none test but not the others.
    local $norm = Locale::Maketext::Utils::Phrase::Norm->new( qw(NonBytesStr Grapheme Ampersand Markup Ellipsis EndPunc), { 'skip_defaults_when_given_filters' => 1 } );

    run_32_tests(
        'filter_name'    => 'Ellipsis',
        'filter_pos'     => 4,                                                          # is 5 with no args to new()
        'original'       => " … I… am .. bad ,,, you?",
        'modified'       => " … I[comment, invalid ellipsis] am … bad … you?",
        'all_violations' => {
            'special' => [
                'multiple period/comma instead of ellipsis character',
                'initial ellipisis needs to be preceded by a normal space',
                'invalid initial, medial, or final ellipsis',
            ],
            'default' => undef,                                                         # undef means "same as special"
        },
        'all_warnings'      => \%global_all_warnings,
        'filter_violations' => {
            'special' => [
                'multiple period/comma instead of ellipsis character',
                'initial ellipisis needs to be preceded by a normal space',
                'invalid initial, medial, or final ellipsis',
            ],
            'default' => undef,                                                         # undef means "same as special"
        },    # undef means "same as all_violations"
        'filter_warnings' => \%global_filter_warnings,
        'return_value'    => {
            'special' => [ 0, 3,                             0, 1 ],
            'default' => undef, # undef means "same as special"
        },
        'diag' => 0,
    );
}

run_32_tests(
    'filter_name'    => 'BeginUpper',
    'filter_pos'     => 6,
    'original'       => 'wazzup?',
    'modified'       => 'wazzup?',
    'all_violations' => {
        'special' => [
            'Does not start with an uppercase letter, ellipsis preceded by space, or bracket notation.',
        ],
        'default' => undef,    # undef means "same as special"
    },
    'all_warnings'      => \%global_all_warnings,
    'filter_violations' => undef,                      # undef means "same as all_violations"
    'filter_warnings'   => \%global_filter_warnings,
    'return_value'      => {
        'special' => [ 0, 1,                             0 ],
        'default' => undef, # undef means "same as special"
    },
    'filter_does_not_modify_string' => 1,
    'diag'                          => 0,
);

{
    local %global_all_warnings = %global_all_warnings;
    $global_all_warnings{'special'} = \@{ $global_all_warnings{'special'} };
    $global_all_warnings{'default'} = \@{ $global_all_warnings{'default'} };

    push @{ $global_all_warnings{'special'} }, 'Non title/label does not end with some sort of puncuation or bracket notation.';
    push @{ $global_all_warnings{'default'} }, 'Non title/label does not end with some sort of puncuation or bracket notation.';

    local %global_filter_warnings = %global_filter_warnings;
    $global_filter_warnings{'special'} = \@{ $global_filter_warnings{'special'} };
    $global_filter_warnings{'default'} = \@{ $global_filter_warnings{'default'} };

    push @{ $global_filter_warnings{'special'} }, 'Non title/label does not end with some sort of puncuation or bracket notation.';
    push @{ $global_filter_warnings{'default'} }, 'Non title/label does not end with some sort of puncuation or bracket notation.';

    run_32_tests(
        'filter_name'    => 'EndPunc',
        'filter_pos'     => 7,
        'original'       => 'I am an evil partial phrase',
        'modified'       => 'I am an evil partial phrase',
        'all_violations' => {
            'special' => [],
            'default' => [],
        },
        'all_warnings'      => \%global_all_warnings,
        'filter_violations' => undef,                      # undef means "same as all_violations"
        'filter_warnings'   => \%global_filter_warnings,
        'return_value'      => {
            'special' => [ -1, 0,                             1 ],
            'default' => undef, # undef means "same as special"
        },
        'get_status_is_warnings'        => 1,
        'filter_does_not_modify_string' => 1,
        'diag'                          => 0,
    );
}

# all phrase:
run_32_tests(
    'filter_name'    => 'Consider',
    'filter_pos'     => 8,
    'original'       => '[comment,this is a an “all BN” phrase]',
    'modified'       => '[comment,this is a an “all BN” phrase][comment,does this phrase really need to be entirely bracket notation?]',
    'all_violations' => {
        'special' => [],
        'default' => undef,    # undef means "same as special"
    },
    'all_warnings' => {
        'default' => [
            'Entire phrase is bracket notation, is there a better way in this case?',
        ],
        'special' => undef,
    },
    'filter_violations' => undef,    # undef means "same as all_violations"
    'filter_warnings'   => undef,    # undef means "same as all_warnings"
    'return_value'      => {
        'special' => [ -1, 0,                             1, 1 ],
        'default' => undef, # undef means "same as special"
    },
    'get_status_is_warnings' => 1,
    'diag'                   => 0,
);

# hardcoded URL
run_32_tests(
    'filter_name'    => 'Consider',
    'filter_pos'     => 8,
    'original'       => 'X [output,url,_1] [output,url,http://search.cpan.org] Y.',
    'modified'       => 'X [output,url,_1] [output,url,why harcode “http://search.cpan.org”] Y.',
    'all_violations' => {
        'special' => [],
        'default' => undef,    # undef means "same as special"
    },
    'all_warnings' => {
        'default' => [
            'Hard coded URLs can be a maintenance nightmare, why not pass the URL in so the phrase does not change if the URL does',
        ],
        'special' => undef,
    },
    'filter_violations' => undef,    # undef means "same as all_violations"
    'filter_warnings'   => undef,    # undef means "same as all_warnings"
    'return_value'      => {
        'special' => [ -1, 0,                             1, 1 ],
        'default' => undef, # undef means "same as special"
    },
    'get_status_is_warnings' => 1,
    'diag'                   => 0,
);

# Simple bare var
# 32k more: for (1..1001) {
run_32_tests(
    'filter_name'    => 'Consider',
    'filter_pos'     => 8,
    'original'       => 'X [_1] foo, [_8], [_-23] ‘[_99]’ [_*] ([_42]): [_2]',
    'modified'       => 'X “[_1]” foo, [_8], “[_-23]” ‘[_99]’ “[_*]” ([_42]): [_2]',
    'all_violations' => {
        'special' => [],
        'default' => undef,    # undef means "same as special"
    },
    'all_warnings' => {
        'default' => [
            'Bare variable can lead to ambiguous output',
        ],
        'special' => undef,
    },
    'filter_violations' => undef,    # undef means "same as all_violations"
    'filter_warnings'   => undef,    # undef means "same as all_warnings"
    'return_value'      => {
        'special' => [ -1, 0,                             1, 1 ],
        'default' => undef, # undef means "same as special"
    },
    'get_status_is_warnings' => 1,
    'diag'                   => 0,
);

# /32k more }

# TODO Complex bare vars (see filter mod for comment specifics)
#    [output,strong,_2] [output,strong,_-42] [output,strong,_*] [output,strong,_2,Z] [output,strong,_-42,Z] [output,strong,_*,Z] [output,strong,X_2X] [output,strong,X_-42X] [output,strong,X_*X] [output,strong,X_2X,Z] [output,strong,X_-42X,Z] [output,strong,X_*X,Z]

# No violations or warnings
my $valid = $norm->normalize('Hello World');
ok( $valid->get_status(),             "valid: RES get_status()" );
ok( !$valid->filters_modify_string(), "valid: RES filters_modify_string()" );
is( $valid->get_warning_count(),   0, "valid: RES get_warning_count()" );
is( $valid->get_violation_count(), 0, "valid: RES get_violation_count()" );

# diag explain $valid;

# No violations or warnings
$valid = $norm->normalize('Hello World …');
ok( $valid->get_status(),             "valid end …: RES get_status()" );
ok( !$valid->filters_modify_string(), "valid end …: RES filters_modify_string()" );
is( $valid->get_warning_count(),   0, "valid end …: RES get_warning_count()" );
is( $valid->get_violation_count(), 0, "valid end …: RES get_violation_count()" );

#### functions ##

sub run_32_tests {
    my %args = @_;

    diag("$args{'filter_name'} filter");
    my $spec = Locale::Maketext::Utils::Phrase::Norm->new( $args{'filter_name'}, { 'skip_defaults_when_given_filters' => 1 } );

    if ( !defined $args{'return_value'}{'special'} ) {
        $args{'return_value'}{'special'} = $args{'return_value'}{'default'};
    }
    if ( !defined $args{'return_value'}{'default'} ) {
        $args{'return_value'}{'default'} = $args{'return_value'}{'special'};
    }

    for my $k ( 'violations', 'warnings' ) {
        if ( !defined $args{"all_$k"}{'special'} ) {
            $args{"all_$k"}{'special'} = $args{"all_$k"}{'default'};
        }
        if ( !defined $args{"all_$k"}{'default'} ) {
            $args{"all_$k"}{'default'} = $args{"all_$k"}{'special'};
        }

        if ( !defined $args{"filter_$k"} ) {
            $args{"filter_$k"} = $args{"all_$k"};
        }

        if ( !defined $args{"filter_$k"}{'special'} ) {
            $args{"filter_$k"}{'special'} = $args{"all_$k"}{'special'};
        }

        if ( !defined $args{"filter_$k"}{'special'} ) {
            $args{"filter_$k"}{'special'} = $args{"filter_$k"}{'default'};
        }
        if ( !defined $args{"filter_$k"}{'default'} ) {
            $args{"filter_$k"}{'default'} = $args{"filter_$k"}{'special'};
        }

        # if they are still undef then use the "all" variant
        if ( !defined $args{"filter_$k"}{'default'} ) {
            $args{"filter_$k"}{'default'} = $args{"all_$k"}{'default'};
        }
        if ( !defined $args{"filter_$k"}{'special'} ) {
            $args{"filter_$k"}{'special'} = $args{"all_$k"}{'special'};
        }
    }

    for my $o ( $norm, $spec ) {
        $res = $o->normalize( $args{'original'} );
        my $label = @{ $o->{'filters'} } == 1 ? 'special' : 'default';

        if ( $args{'diag'} ) {
            diag explain $o;
            diag explain $res;
        }

        my $violation_count = @{ $args{'all_violations'}{$label} };
        my $warning_count   = @{ $args{'all_warnings'}{$label} };

        $args{'get_status_is_warnings'} ? is( $res->get_status(), '-1', "$label: RES get_status()" ) : ok( !$res->get_status(), "$label: RES get_status()" );
        ok( $args{'filter_does_not_modify_string'} ? !$res->filters_modify_string() : $res->filters_modify_string(), "$label: RES filter_modifies_string()" );
        is( $res->get_warning_count(),    $warning_count,    "$label: RES get_warning_count()" );
        is( $res->get_violation_count(),  $violation_count,  "$label: RES get_violation_count()" );
        is( $res->get_orig_str(),         $args{'original'}, "$label: RES get_orig_str()" );
        is( $res->get_aggregate_result(), $args{'modified'}, "$label: RES get_aggregate_result()" );

        $filt = $res->get_filter_results()->[ $label eq 'special' ? 0 : $args{'filter_pos'} ];

        if ( $args{'diag'} ) {
            diag explain $filt;
        }

        $violation_count = @{ $args{'filter_violations'}{$label} };
        $warning_count   = @{ $args{'filter_warnings'}{$label} };

        is( $filt->get_package(), "Locale::Maketext::Utils::Phrase::Norm::$args{'filter_name'}", "$label: FILT get_package()" );
        $args{'get_status_is_warnings'} ? is( $filt->get_status(), '-1', "$label: FILT get_status()" ) : ok( !$filt->get_status(), "$label: FILT get_status()" );
        ok( $args{'filter_does_not_modify_string'} ? !$filt->filter_modifies_string() : $filt->filter_modifies_string(), "$label: FILT filter_modifies_string()" );
        is( $filt->get_warning_count(),   $warning_count,   "$label: FILT get_warning_count()" );
        is( $filt->get_violation_count(), $violation_count, "$label: FILT get_violation_count()" );
        is_deeply(
            [ $filt->return_value() ],
            $args{'return_value'}{$label},
            "$label: FILT return_value()"
        );
        is( $filt->get_orig_str(), $args{'original'}, "$label: FILT get_orig_str()" );
        is( $filt->get_new_str(),  $args{'modified'}, "$label: FILT get_aggregate_result()" );

        is_deeply(
            [ $filt->get_violations() ? @{ $filt->get_violations() } : () ],
            $args{'filter_violations'}{$label},
            "$label: FILT filter get_violations()"
        );
        is_deeply(
            [ $filt->get_warnings() ? @{ $filt->get_warnings() } : () ],
            $args{'filter_warnings'}{$label},
            "$label: FILT get_warnings()"
        );
    }

    $norm->delete_cache();
}