package Locale::Maketext::Utils::Phrase::Norm;

use strict;
use warnings;

use Module::Want ();
use Carp         ();

# IF YOU CHANGE THIS CHANGE THE “DEFAULT FILTERS” POD SECTION ALSO
my @default_filters = qw(NonBytesStr WhiteSpace Grapheme Ampersand Markup Ellipsis BeginUpper EndPunc Consider);    # IF YOU CHANGE THIS CHANGE THE “DEFAULT FILTERS” POD SECTION ALSO

# IF YOU CHANGE THIS CHANGE THE “DEFAULT FILTERS” POD SECTION ALSO

# TODO ?: Acronym, IntroComma, Parens (needs CLDR char/pattern in Locales.pm) [output,chr,(not|in|the|markup|list|or any if ampt() etc happen )???

sub new {
    my $ns = shift;
    $ns = ref($ns) if ref($ns);                                                                                     # just the class ma'am

    my $conf = ref( $_[-1] ) eq 'HASH' ? pop(@_) : {};

    my @filters;
    my %cr2ns;
    my $n;                                                                                                          # buffer
    for $n ( $conf->{'skip_defaults_when_given_filters'} ? ( @_ ? @_ : @default_filters ) : ( @default_filters, @_ ) ) {
        my $name = $n =~ m/[:']/ ? $n : $ns . "::$n";

        if ( Module::Want::have_mod($name) ) {
            if ( my $cr = $name->can('normalize_maketext_string') ) {
                push @filters, $cr;
                $cr2ns{"$cr"} = $name;
            }
            else {
                Carp::carp("$name does not implement normalize_maketext_string()");
                return;
            }
        }
        else {
            Carp::carp($@);
            return;
        }
    }

    if ( !@filters ) {
        Carp::carp("Filter list is empty!");
        return;
    }

    return bless { 'filters' => \@filters, 'cache' => {}, 'filter_namespace' => \%cr2ns }, $ns;
}

sub delete_cache {
    delete $_[0]->{'cache'};
}

sub normalize {
    my ( $self, $string ) = @_;

    return $self->{'cache'}{$string} if exists $self->{'cache'}{$string};

    $self->{'cache'}{$string} = bless {
        'status'           => 1,
        'warning_count'    => 0,
        'violation_count'  => 0,
        'filter_results'   => [],
        'orig_str'         => $string,
        'aggregate_result' => $string,
      },
      'Locale::Maketext::Utils::Phrase::Norm::_Res';

    my $cr;    # buffer
    foreach $cr ( @{ $self->{'filters'} } ) {

        push @{ $self->{'cache'}{$string}{'filter_results'} }, bless {
            'status'     => 1,
            'package'    => $self->{'filter_namespace'}{"$cr"},
            'orig_str'   => $string,
            'new_str'    => $string,
            'violations' => [],                                   # status 0
            'warnings'   => [],                                   # status -1 (true but not 1)
          },
          'Locale::Maketext::Utils::Phrase::Norm::_Res::Filter';

        my ( $filter_rc, $violation_count, $warning_count, $filter_modifies_string ) = $cr->( $self->{'cache'}{$string}{'filter_results'}[-1] );

        # Update string's overall aggregate modifcation
        if ($filter_modifies_string) {

            # Run aggregate value through filter, not perfect since it isn't operating on the same value as above
            my $agg_filt = bless {
                'status'     => 1,
                'package'    => $self->{'filter_namespace'}{"$cr"},
                'orig_str'   => $self->{'cache'}{$string}{'aggregate_result'},
                'new_str'    => $self->{'cache'}{$string}{'aggregate_result'},
                'violations' => [],                                              # status 0
                'warnings'   => [],                                              # status -1 (true but not 1)
              },
              'Locale::Maketext::Utils::Phrase::Norm::_Res::Filter';
            $cr->($agg_filt);
            $self->{'cache'}{$string}{'aggregate_result'} = $agg_filt->get_new_str();
        }

        # Update string's overall result
        $self->{'cache'}{$string}->{'violation_count'} += $violation_count;
        $self->{'cache'}{$string}->{'warning_count'}   += $warning_count;
        if ( $self->{'cache'}{$string}->{'status'} ) {
            if ( !$filter_rc ) {
                $self->{'cache'}{$string}->{'status'} = $filter_rc;
            }
            elsif ( $self->{'cache'}{$string}->{'status'} != -1 ) {
                $self->{'cache'}{$string}->{'status'} = $filter_rc;
            }
        }

        last if !$filter_rc && $self->{'stop_filter_on_error'};    # TODO: document, add POD, methods, new(), tests etc.
    }

    return $self->{'cache'}{$string};
}

package Locale::Maketext::Utils::Phrase::Norm::_Res;

sub get_status {
    return $_[0]->{'status'};
}

sub get_warning_count {
    return $_[0]->{'warning_count'};
}

sub get_violation_count {
    return $_[0]->{'violation_count'};
}

sub get_filter_results {
    return $_[0]->{'filter_results'};
}

sub get_orig_str {
    return $_[0]->{'orig_str'};
}

sub get_aggregate_result {
    return $_[0]->{'aggregate_result'} || $_[0]->{'orig_str'};
}

sub filters_modify_string {
    return 1 if $_[0]->{'aggregate_result'} ne $_[0]->{'orig_str'};
    return;
}

package Locale::Maketext::Utils::Phrase::Norm::_Res::Filter;

sub add_violation {
    my ( $self, $error ) = @_;
    $self->{'status'} = 0;
    push @{ $self->{'violations'} }, $error;
}

sub add_warning {
    my ( $self, $warning ) = @_;
    $self->{'status'} = -1 if !$self->get_violations();
    push @{ $self->{'warnings'} }, $warning;
}

sub get_status {
    return $_[0]->{'status'};
}

sub get_package {
    return $_[0]->{'package'};
}

sub get_orig_str {
    return $_[0]->{'orig_str'};
}

sub get_new_str {
    return $_[0]->{'new_str'};
}

sub get_violations {
    return if !@{ $_[0]->{'violations'} };
    return $_[0]->{'violations'};
}

sub get_warnings {
    return if !@{ $_[0]->{'warnings'} };
    return $_[0]->{'warnings'};
}

sub get_string_sr {
    return \$_[0]->{'new_str'};
}

sub get_warning_count {
    return $_[0]->get_warnings() ? scalar( @{ $_[0]->get_warnings() } ) : 0;
}

sub get_violation_count {
    return $_[0]->get_violations() ? scalar( @{ $_[0]->get_violations() } ) : 0;
}

sub return_value {
    my ($self) = @_;
    return ( $self->{'status'}, $self->get_violation_count(), $self->get_warning_count(), $self->filter_modifies_string() );
}

sub filter_modifies_string {
    return 1 if $_[0]->{'orig_str'} ne $_[0]->{'new_str'};
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Locale::Maketext::Utils::Phrase::Norm - Normalize and perform lint-like analysis of phrases

=head1 VERSION

This document describes Locale::Maketext::Utils::Phrase::Norm version 0.1

=head1 SYNOPSIS

    use Locale::Maketext::Utils::Phrase::Norm;

    my $norm = Locale::Maketext::Utils::Phrase::Norm->new() || die;
    
    my $result = $norm->normalize('This office has worked [quant,_1,day,days,zero days] without an “accident”.');
    
    # process $result

=head1 DESCRIPTION

Analyze, report, and normalize a maketext style phrase based on rules organized into filter modules.

=head1 INTERFACE

=head2 Main object

=head3 new()

Create a new object with all the filters initialized.

Giving no arguments means it will employ all of the default filter modules (documented in L</"DEFAULT FILTERS">).

Otherwise the optional arguments are: 

=over 4 

=item A list of filter module name spaces to run after the default filter modules.

If the given module name does not contain any package seperators it will be treated as if it needs prepended with 'Locale::Maketext::Utils::Phrase::Norm::'.

e.g. Given 'Locale::Maketext::Utils::Phrase::Norm::MyCoolFilter' you can pass the name 'MyCoolFilter'.

=item The last argument can be a hashref of options:

    my $norm = Locale::Maketext::Utils::Phrase::Norm->new('My::Filter::XYZ'); # all default filters followed by the My::Filter::XYZ filter
    
    my $norm = Locale::Maketext::Utils::Phrase::Norm->new('My::Filter::XYZ', { 'skip_defaults_when_given_filters' => 1 }); # only do My::Filter::XYZ the filter

Currently there is only the one option as in the example above. The key’s name and example above outline what it is for and how to use it.

=back 

carp()s and returns false if there is some sort of failure (documented in L</"DIAGNOSTICS">).

=head3 normalize()

Takes a phrase as the only argument and returns a result object (documented in L</"Result Object">).

=head3 delete_cache()

The result of normalize() is cached internally so calling it subsequent times with the same string won’t result in it being reprocessed.

This method deletes the internal cache. Returns the hashref that was removed.

=head2 Result Object

=head3 get_status()

Returns the status of all the filters:

=over 4

=item True means no violations

=item -1 (i.e. still true) means there were warnings but no violations.

=item False means there was at least one violation and possibly warnings.

=back 

=head3 get_warning_count()

Return the number of warnings from all filters combined.

=head3 get_violation_count()

Return the number of violations from all filters combined.

=head3 get_filter_results()

Return an array ref of filter result objects (documented in L</"Filter Result Object">).

=head3 get_orig_str()

Get the phrase as passed in before any modifications by filters.

=head3 get_aggregate_result()

Get the phrase after all filters had a chance to modify it.

=head3 filters_modify_string()

Returns true if any of the filters resulted in a string different from what you passed it. False otherwise.

=head2 Filter Result Object

=head3 Intended for use in a filter module.

See L</"ANATOMY OF A FILTER MODULE"> for more info.

=head4 add_violation()

Add a violation.

=head4 add_warning()

Add a warning.

=head4 get_string_sr()

Returns a SCALAR reference to the modified version of the string that the filter can use to modify the string.

=head4 return_value()

returns an array of the status, violation count, warning count, and filter_modifies_string().

It is what the filter’s normalize_maketext_string() should return;

=head3 Intended for use when processing results.

These can be used in a filter module’s filter code if you find use for them there. See L</"ANATOMY OF A FILTER MODULE"> for more info.

=head4 get_status()

Returns the status of the filter:

=over 4

=item True means no violations

=item -1 (i.e. still true) means there were warnings but no violations.

=item False means there was at least one violation and possibly warnings.

=back

=head4 get_package()

Get the current filter’s package.

=head4 get_orig_str()

Get the phrase as passed in before any modifications by the filter.

=head4 get_new_str()

Get the phrase after the filter had a chance to modify it.

=head4 get_violations()

Return an array ref of violations added via add_violation().

If there are no violations it returns false.

=head4 get_warnings()

Return an array ref of violations added via add_warning().

If there are no warnings it returns false.

=head4 get_warning_count()

Returns the number of warnings the filter resulted in.

=head4 get_violation_count()

Returns the number of violations the filter resulted in.

=head4 filter_modifies_string()

Returns true if the filter resulted in a string different from what you passed it. False otherwise.

=head1 DEFAULT FILTERS

The included default filters are listed below in the order they are executed by default.

=over 4

=item L<NonBytesStr|Locale::Maketext::Utils::Phrase::Norm::NonBytesStr>

=item L<WhiteSpace|Locale::Maketext::Utils::Phrase::Norm::WhiteSpace>

=item L<Grapheme|Locale::Maketext::Utils::Phrase::Norm::Grapheme>

=item L<Ampersand|Locale::Maketext::Utils::Phrase::Norm::Ampersand>

=item L<Markup|Locale::Maketext::Utils::Phrase::Norm::Markup>

=item L<Ellipsis|Locale::Maketext::Utils::Phrase::Norm::Ellipsis>

=item L<BeginUpper|Locale::Maketext::Utils::Phrase::Norm::BeginUpper>

=item L<EndPunc|Locale::Maketext::Utils::Phrase::Norm::EndPunc>

=item L<Consider|Locale::Maketext::Utils::Phrase::Norm::Consider>

=back

=head1 ANATOMY OF A FILTER MODULE

A filter module is simply a package that defines a function that does the filtering of the phrase.

=head2 normalize_maketext_string()

This gets passed a single argument: the L</"Filter Result Object"> that defines data about the phrase. 

That object can be used to do the actual checks, modifications if any, and return the expected info back (via $filter->return_value). 

    package My::Phrase::Filter::X;
    
    sub normalize_maketext_string {
        my ($filter) = @_;

        my $string_sr = $filter->get_string_sr();

        if (${$string_sr} =~ s/X/[comment,unexpected X]/g) {
              $filter->add_warning('X might be invalid might wanna check that');
        #         or
        #      $filter->add_violation('Text of violation here');
        }

        return $filter->return_value;
    }
    
    1;

It’s a good idea to explain the filter in it’s POD. Check out L<_Stub|Locale::Maketext::Utils::Phrase::Norm::_Stub> for some boilerplate.

=head1 DIAGNOSTICS

=over

=item C<< %s does not implement normalize_maketext_string() >>

new() was able to load the filter %s but that class does not have a normalize_maketext_string() method.

=item C<< Can't locate %s.pm in @INC … >>

new() was not able to load the filter %s, the actual error comes from perl via $@ from L<Module::Want>

=item C<< Filter list is empty! >>

After all initialization and no other errors the list of filters is somehow empty.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Locale::Maketext::Utils::Phrase::Norm requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Module::Want>, L<Encode> (for the L<WhiteSpace|Locale::Maketext::Utils::Phrase::Norm::WhiteSpace> filter)

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-locale-maketext-utils@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012 cPanel, Inc. C<< <copyright@cpanel.net>> >>. All rights reserved.

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself, either Perl version 5.10.1 or, at your option, 
any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
