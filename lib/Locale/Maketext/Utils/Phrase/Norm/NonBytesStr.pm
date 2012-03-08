package Locale::Maketext::Utils::Phrase::Norm::NonBytesStr;

use strict;
use warnings;

sub normalize_maketext_string {
    my ($filter) = @_;

    my $string_sr = $filter->get_string_sr();

    if ( ${$string_sr} =~ s/(\\x\{[0-9a-fA-F]+\})/[comment,non bytes unicode string “$1”]/g ) {
        $filter->add_violation('non-bytes string (perl)');
    }

    if ( ${$string_sr} =~ s/(\\N\{[^}]+\})/[comment,charnames type string “$1”]/g ) {
        $filter->add_violation('charname string (perl \N{})');
    }

    if ( ${$string_sr} =~ s/(?<!\\N\{)(\s*)(\\?[uU][x\+]?[0-9a-fA-F]+)/${1}[comment,non bytes unicode string “$2”]/g ) {
        $filter->add_violation('non-bytes string (non-perl)');
    }

    return $filter->return_value;
}

1;

__END__

=encoding utf-8

=head1 Normalization

We only want bytes strings and not “wide” unicode code point notation.

=head2 Rationale

This helps give consistency, clarity, and simplicity.

There's no really good way to combine the use of bytes strings and unicode string without issues. If we use bytes strings everything just works.

You can simply use the character itself or a bracket notation method for the handful of markup related or visually special characters

=head1 possible violations

If you get false positives then that only goes to help highlight how ambiguity adds to the reason to avoid non-bytes strings!

=over 4

=item non-bytes string (perl)'

This means you have something like \x{2026} and need to use the character itself instead.

These will be turned into ‘[comment,non bytes unicode string “\x{NNNN}”]’ (where NNNN is the Unicode code point) so you can find them visually.

=item non-bytes string (non-perl)'

This means you have something like \u2026 and need to use the character itself instead.

These will be turned into ‘[comment,non bytes unicode string “\u2026”]’ (where NNNN is the Unicode code point) so you can find them visually.

=back 

=head1 possible warnings

None
