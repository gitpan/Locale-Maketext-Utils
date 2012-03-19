package Locale::Maketext::Utils::Phrase::Norm::BeginUpper;

use strict;
use warnings;

sub normalize_maketext_string {
    my ($filter) = @_;

    my $string_sr = $filter->get_string_sr();

    if ( ${$string_sr} !~ m/\A(?:[A-Z]|(?:\[[^\]]+)|(?: …))/ ) {

        # ${$string_sr} = "[comment,beginning needs to be upper case ?]" . ${$string_sr};
        $filter->add_violation('Does not start with an uppercase letter, ellipsis preceded by space, or bracket notation.');
    }

    # TODO (phrase obj?) If it starts w/ bracket notation will it be appropriately begun when rendered?

    return $filter->return_value;
}

1;

__END__

=encoding utf-8

=head1 Normalization

We want to make sure phrases begin correctly and consistently.

=head2 Rationale

Why would we want incorrect or inconsistent things?

=head1 possible violations

=over 4

=item Does not start with an uppercase letter, ellipsis preceded by space, or bracket notation.

Problem should be self explanatory.

=back

=head1 possible warnings

None
