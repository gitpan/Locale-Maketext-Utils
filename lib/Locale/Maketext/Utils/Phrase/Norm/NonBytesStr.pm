package Locale::Maketext::Utils::Phrase::Norm::NonBytesStr;

use strict;
use warnings;

sub normalize_maketext_string {
    my ($filter) = @_;

    my $string_sr = $filter->get_string_sr();

    # \x{NNNN…}
    if ( ${$string_sr} =~ s/(\\x\{[0-9a-fA-F]+\})/[comment,non bytes unicode string “$1”]/g ) {
        $filter->add_violation('non-bytes string (perl)');
    }

    # \N{…} see `perldoc charnames
    if ( ${$string_sr} =~ s/(\\N\{[^}]+\})/[comment,charnames.pm type string “$1”]/g ) {
        $filter->add_violation('charnames.pm string notation');
    }

    # u"\uNNNN…"
    if ( ${$string_sr} =~ s/([uU])(["'])(\\[uU][0-9a-fA-F]+)\2/[comment,unicode notation “$1“$3””]/g ) {
        $filter->add_violation('unicode code point notation (Python style)');
    }

    #\uNNNN…
    if ( ${$string_sr} =~ s/(?<!\[comment,unicode notation “[uU]“)(\\[uU][0-9a-fA-F]+)/[comment,unicode notation “$1”]/g ) {
        $filter->add_violation('unicode code point notation (C/C++/Java style)');
    }

    # X'NNNN…'
    # U'NNNN…'
    if ( ${$string_sr} =~ s/(?:([XxUn])(["'])([0-9a-fA-F]+)\2)/[comment,unicode notation “$1‘$3’”]/g ) {
        $filter->add_violation('unicode code point notation (alternate style)');
    }

    # U+NNNN…
    if ( ${$string_sr} =~ s/(?<!\[comment,charnames\.pm type string “\\N\{)([Uu]\+[0-9a-fA-F]+)/[comment,unicode notation “$1”]/g ) {
        $filter->add_violation('unicode code point notation (visual notation style)');    # TODO: [output,codepoint,NNNN]
    }

    # UxNNNN…
    if ( ${$string_sr} =~ s/([Uu]x[0-9a-fA-F]+)/[comment,unicode notation “$1”]/g ) {
        $filter->add_violation('unicode code point notation (visual notation type 2 style)');    # TODO: [output,codepoint,NNNN]
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

Note that HTML Entities are not addressed here since the unicode notation as well as other syntax is covered via L<Ampersand|Locale::Maketext::Utils::Phrase::Norm::Ampersand>.

=over 4

=item non-bytes string (perl)'

This means you have something like \x{NNNN} and need to use the character itself instead.

These will be turned into ‘[comment,non bytes unicode string “\x{NNNN}”]’ (where NNNN is the Unicode code point) so you can find them visually.

=item charnames.pm string notation

This means you have something like \N{…} and need to use the character itself instead.

These will be turned into ‘[comment,charnames.pm type string “\N{…}”]’ so you can find them visually.

=item unicode code point notation (C/C++/Java style)'

This means you have something like \uNNNN and need to use the character itself instead.

These will be turned into ‘[comment,unicode notation “\uNNNN”]’ (where NNNN is the Unicode code point) so you can find them visually.

=item unicode code point notation (alternate style)

This means you have something like U'NNNN' and need to use the character itself instead.

These will be turned into ‘[comment,unicode notation “U'NNNN'”]’ (where NNNN is the Unicode code point) so you can find them visually.

=item unicode code point notation (visual notation style)'

This means you have something like U+NNNN and need to use the character itself instead.

These will be turned into ‘[comment,non bytes unicode string “U+NNNN]’ (where NNNN is the Unicode code point) so you can find them visually.

=item unicode code point notation (visual notation type 2 style)'

This means you have something like UxNNNN and need to use the character itself instead.

These will be turned into ‘[comment,non bytes unicode string “UxNNNN]’ (where NNNN is the Unicode code point) so you can find them visually.

=item unicode code point notation (Python style)

This means you have something like u"\uNNNN" and need to use the character itself instead.

These will be turned into ‘[comment,non bytes unicode string “u"\uNNNN"”]’ (where NNNN is the Unicode code point) so you can find them visually.

=back 

=head1 possible warnings

None
