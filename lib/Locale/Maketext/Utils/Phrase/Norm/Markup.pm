package Locale::Maketext::Utils::Phrase::Norm::Markup;

use strict;
use warnings;

sub normalize_maketext_string {
    my ($filter) = @_;

    # & is handled more in depth in it's own module
    if ( $filter->get_orig_str() =~ m/[<>"']/ ) {

        # normalize <>"' to [output,chr,…]
        # TODO: [output,ENT] instead of [output,N] if it survives …

        my $string_sr = $filter->get_string_sr();

        if ( ${$string_sr} =~ s/'/[output,chr,39]/g ) {
            $filter->add_warning('consider if, instead of using a straight apostrophe, using ‘’ for single quoting and ’ for an apostrophe is the right thing here (i.e. instead of bracket notation)');
        }
        if ( ${$string_sr} =~ s/"/[output,chr,34]/g ) {
            $filter->add_warning('consider if, instead of using straight double quotes, using “” is the right thing here (i.e. instead of bracket notation)');
        }
        ${$string_sr} =~ s/>/[output,chr,62]/g;
        ${$string_sr} =~ s/</[output,chr,60]/g;

        $filter->add_violation('Contains markup related characters');
    }

    return $filter->return_value;
}

1;

__END__

=encoding utf-8

=head1 Normalization

Turn markup related characters into bracket notation.

=head2 Rationale

So we detect and modify them.

=head1 IF YOU USE THIS FILTER ALSO USE …

… THIS FILTER L<Locale::Maketext::Utils::Phrase::Norm::Ampersand>.

This is not enforced anywhere since we want to assume the coder knows what they are doing.

=head1 possible violations

=over 4

=item Contains markup related characters

Turns <>'" into appropriate bracket notation.

& is handled in its own driver.

=back 

=head1 possible warnings

=over 4

=item consider if, instead of using straight double quotes, using “” is the right thing here (i.e. instead of bracket notation)

This is issue when " is encountered.

=item consider if, instead of using a straight apostrophe, using ‘’ for single quoting and ’ for an apostrophe is the right thing here (i.e. instead of bracket notation)

This is issue when " is encountered.

=back
