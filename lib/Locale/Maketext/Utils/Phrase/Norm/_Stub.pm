package Locale::Maketext::Utils::Phrase::Norm::_Stub;

use strict;
use warnings;

sub normalize_maketext_string {
    my ($filter) = @_;

    my $string_sr = $filter->get_string_sr();

    # if (${$string_sr} =~ s/X/Y/g) {
    #      $filter->add_warning('X might be invalid might wanna check that');
    #         or
    #      $filter->add_violation('Text of violation here');
    # }

    return $filter->return_value;
}

1;

__END__

=encoding utf-8

=head1 Normalization

=head2 Rationale

=head1 possible violations

=over 4

=item Text of violation here

Description here

=back 

=head1 possible warnings

None
