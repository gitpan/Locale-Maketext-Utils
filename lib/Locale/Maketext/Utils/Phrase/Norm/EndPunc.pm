package Locale::Maketext::Utils::Phrase::Norm::EndPunc;

use strict;
use warnings;

sub normalize_maketext_string {
    my ($filter) = @_;

    my $string_sr = $filter->get_string_sr();

    if ( ${$string_sr} !~ m/[\!\?\.\:\]…]$/ ) {
        if ( !__is_title_case( ${$string_sr} ) ) {

            # ${$string_sr} = ${$string_sr} . "[comment,missing puncutation ?]";
            $filter->add_warning('Non title/label does not end with some sort of puncuation or bracket notation.');
        }
    }

    return $filter->return_value;
}

# this is a really, really, REALLY dumb check (that is why this filter is a warning), free not to use it!
sub __is_title_case {
    my ($string) = @_;

    my $word;    # buffer
    my $possible_ick = 0;

    # this splits on the whitespace leftover after the Whitespace filter
    for $word ( split( /(?:\x20|\xc2\xa0)/, $string ) ) {
        next if !defined $word || $word eq '';    # e.g ' … X Y'
        next if $word =~ m/^[A-Z\[]/;             # When would a title/label ever start life w/ a beginning ellipsis? i.e. ' … Address' instead of 'Email Address'.
                                                  #     If it is a short conclusion it should have puncutaion, e.g. 'Compiling …' ' … done.'
        next if length($word) > 3;                # There are longer words that should be lowercase, there are shorter words that should be capitol: see “this is a …” above

        $possible_ick++;
    }

    return if $possible_ick;
    return 1;
}

1;

__END__

=encoding utf-8

=head1 Normalization

=head2 Rationale

=head1 IF YOU USE THIS FILTER ALSO USE …

… THIS FILTER L<Locale::Maketext::Utils::Phrase::Norm::Whitespace>.

This is not enforced anywhere since we want to assume the coder knows what they are doing.

=head1 possible violations

=over 4

=item Text of violation here

Description here

=back 

=head1 possible warnings

None
