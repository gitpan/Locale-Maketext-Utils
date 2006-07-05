package Locale::Maketext::Utils;

use strict;
use warnings;

use version;our $VERSION = qv('0.0.1');

use Locale::Maketext;
use base qw(Locale::Maketext);

sub init {
    my ($lh) = @_;	
    
    $lh->SUPER::init();
    $lh->remove_key_from_lexicons('_AUTO');
    
    $lh->fail_with(sub {
         my ($lh, $key, @args) = @_;
         
         my $lookup; 
         if(exists $lh->{'_get_key_from_lookup'}) {
	         if(ref $lh->{'_get_key_from_lookup'} eq 'CODE') {
		        $lookup = $lh->{'_get_key_from_lookup'}->($lh, $key, @args);
		     }
		 }
	
         return $lookup if defined $lookup; 

         if(exists $lh->{'_log_phantom_key'}) {
	         if(ref $lh->{'_log_phantom_key'} eq 'CODE') {
		         $lh->{'_log_phantom_key'}->($lh, $key, @args);
		     }
		 }

         no strict 'refs';
         local ${ $lh->get_base_class() . '::Lexicon' }{'_AUTO'} = 1;
         return $lh->maketext($key, @args);
    });
}

sub remove_key_from_lexicons {
    my($lh, $key) = @_;
    my $idx = 0;
    
    for my $lex_hr ( @{ $lh->_lex_refs() }) {
        $lh->{'_removed_from_lexicons'}{$idx}{$key} = delete $lex_hr->{$key}
            if exists $lex_hr->{$key};
        $idx++;
    }
}

sub get_base_class {
    my $ns = ref shift;    
    $ns =~ s{::\w+$}{};
    return $ns;
}

sub append_to_lexicons {
	my($lh, $appendage) = @_;
	return if ref $appendage ne 'HASH';
	
    no strict 'refs';
    for my $lang (keys %{ $appendage }) {
	    my $ns = $lh->get_base_class() 
	             . ($lang eq '_' ? '' : "::$lang") 
	             . '::Lexicon';
	    %{ $ns } = (%{ $ns }, %{ $appendage->{$lang} });
    }
}

sub langtag_is_loadable {
    my ($lh, $wants_tag) = @_;
    $wants_tag = Locale::Maketext::language_tag($wants_tag);

    # why doesn't this work ?
    # no strict 'refs';
    # my $tag_obj = ${ $lh->get_base_class() }->get_handle( $wants_tag );
    my $tag_obj = eval $lh->get_base_class() . q{->get_handle( $wants_tag );};

    my $has_tag = $tag_obj->language_tag();    
    return $wants_tag eq $has_tag ? $tag_obj : 0;
}

sub get_language_tag {
    return ( split '::', ref(shift) )[-1];
}

sub print {
    local $Carp::CarpLevel = 1; 
    print shift->maketext(@_);
}

sub fetch { 
    local $Carp::CarpLevel = 1;
    return shift->maketext(@_);	
}

1;

__END__

=head1 NAME

Locale::Maketext::Utils - Adds some utility methods and failure handling to Local::Maketext handles

=head1 SYNOPSIS

In MyApp/Localize.pm:

    package MyApp::Localize;
    use Locale::Maketext::Utils; 
    use base 'Locale::Maketext::Utils'; 
  
    # no _AUTO
    our %Lexicon = (...

Make all the language Lexicons you want. (no _AUTO)

Then in your script:
 
   my $lang = MyApp::Localize->get_handle('fr');

Now $lang is a normal Locale::Maketext handle object but now there are some new methods and failure handling which are described below.

=head1 METHODS

=head2 $lh->print($key, @args);

Shortcut for

    print $lh->maketext($key, @args);

=head2 $lh->fetch($key, @args);

Alias for 

    $lh->maketext($key, @args);

=head2 $lh->get_language_tag()

Returns the real language name space being used, not language_tag()'s "cleaned up" one

=head2 $lh->langtag_is_loadable($lang_tag)

Returns 0 if the argument is not a language that can be used to get a handle.

Returns the language handle if it is a language that can be used to get a handle.

=head2 $lh->append_to_lexicons( $lexicons_hashref );

This method allows modules or script to append to the object's Lexicons

Each key is the language tag whose Lexicon you will prepend its value, a hashref, to.

So assuming the key is 'fr', then this is the lexicon that gets appended to:

__PACKAGE__::fr::Lexicon

The only exception is if the key is '_'. In that case the main package's Lexicon is appended to:

__PACKAGE__::Lexicon

    $lh->append_to_lexicons({
        '_' => {
            'Hello World' => 'Hello World',
        },
        'fr' => {
            'Hello World' => 'Bonjour Monde',
        }, 
    });

=head2 $lh->remove_key_from_lexicons($key)

Removes $key from every lexicon. What is removed is stored in $lh->{'_removed_from_lexicons'}

If defined, $lh->{'_removed_from_lexicons'} is a hashref whose keys are the index number of the $lh->_lex_refs() arrayref.

The value is the key and the value that that lexicon had.

This is used internally to remove _AUTO keys so that the failure handler below will get used

=head1 Automatically _AUTO'd Failure Handling with hooks

This module sets fail_with() so that failure is handled for every Lexicon you define as if _AUTO was set and in addition you can use the hooks below.

This functionality is turned off if:

=over 4

=item * _AUTO is set on the Lexicon (and it was not removed internally for some strange reason)

=item * you've changed the failure function with $lh->fail_with() (If you do change it be sure to restore your _AUTO's inside $lh->{'_removed_from_lexicons'})

=back

The result is that a key is looked for in the handle's Lexicon, then the default Lexicon, then the handlers below, and finally the key itself (Again, as if _AUTO had been set on the Lexicon).
I find this extremely useful and hope you do as well :)

=head2 $lh->{'_get_key_from_lookup'}

If lookup fails this code reference will be called with the arguments ($lh, $key, @args)

It can do whatever you want to try and find the $key and return the desired string.

   return $string_from_db;

If it fails it should simply:

   return;

That way it will continue on to the part below:

=head2 $lh->{'_log_phantom_key'}

If $lh->{'_get_key_from_lookup'} is not a code ref, or $lh->{'_get_key_from_lookup'} returned undef then this method is called with the arguments ($lh, $key, @args) right before the failure handler does its _AUTO wonderfulness.

=head1 SEE ALSO

L<Locale::Maketext>

=head1 SUGGESTIONS

If you have an idea for a method that would fit into this module just let me know and we'll see what can be done

=head1 AUTHOR

Daniel Muey, L<http://drmuey.com/cpan_contact.pl>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Daniel Muey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut