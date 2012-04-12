package Locale::Maketext::Utils::Phrase::Norm::Compiles;

use strict;
use warnings;
use Locale::Maketext::Utils ();

sub normalize_maketext_string {
    my ($filter) = @_;

    my $string = $filter->get_orig_str();
    my $mt_obj = $filter->get_maketext_object();

    local $SIG{'__DIE__'};    # cpanel specific: ensure a benign eval does not trigger cpsrvd's DIE handler (may be made moot by internal case 50857)
    eval { $mt_obj->makethis($string); };

    if ($@) {
        my $error = $@;

        $error =~ s/([\[\]])/~$1/g;
        $error =~ s/[\n\r]+/ /g;

        $string =~ s/([\[\]])/~$1/g;
        $error  =~ s/\Q$string\E.*$/$string/;
        my $string_sr = $filter->get_string_sr();
        if ( $error =~ m/Can't locate object method "(.*)" via package "(.*)"/i ) {
            $error = "“$2” does not have a method “$1” in: $string";
        }
        elsif ( $error =~ m/Undefined subroutine (\S+)/i ) {    # odd but theoretically possible
            my $full_func = $1;
            my ( $f, @c ) = reverse( split( /::/, $full_func ) );
            my $c = join( '::', reverse(@c) );
            $error = "“$2” does not have a function “$1” in: $string";
        }

        ${$string_sr} = "[comment,Bracket Notation Error: $error]";

        $filter->add_violation('Bracket Notation Error');
    }

    return $filter->return_value;
}

1;

__END__

=encoding utf-8

=head1 Normalization

Check that the string compiles.

=head2 Rationale

Why would we not want to catch syntax errors?

=head1 possible violations

=over 4

=item Bracket Notation Error

There was a problem compiling the string. 

The string is replaced with a comment that details the problem, typically including an escaped verison of the problematic string: [comment,Bracket Notation Error: DETAILS_GO_HERE]

=back 

=head1 possible warnings

None
