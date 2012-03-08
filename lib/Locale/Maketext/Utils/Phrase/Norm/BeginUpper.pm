package Locale::Maketext::Utils::Phrase::Norm::BeginUpper;

use strict;
use warnings;

sub normalize_maketext_string {
    my ($filter) = @_;

    my $string_sr = $filter->get_string_sr();

    if ( ${$string_sr} !~ m/\A(?:[A-Z]|(?:\[[^\]]+)|(?: …))/ ) {

        # ${$string_sr} = "[comment,beggining needs to be upper case ?]" . ${$string_sr};
        $filter->add_violation('Does not start with an uppercase letter, ellipsis preceded by space, or bracket notation.');
    }

    return $filter->return_value;
}

1;

__END__

=encoding utf-8

=head1 Normalization

=head2 Rationale

=head1 possible violations

None

=head1 possible warnings

over 4

=item Does not start with an uppercase letter, ellipsis preceded by space, or bracket notation.

TODO DESC

=back
