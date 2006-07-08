package Locale::Maketext::Utils;

use strict;
use warnings;

use version;our $VERSION = qv('0.0.3');

use Locale::Maketext;
use base qw(Locale::Maketext);

sub init {
    my ($lh) = @_;	
    
    $lh->SUPER::init();
    $lh->remove_key_from_lexicons('_AUTO');
    
    my $ns = $lh->get_base_class() . '::Encoding'; # use the base class if available
    no strict 'refs';
    $lh->{'encoding'} = ${ $ns } if ${ $ns };
    
    $ns = ref($lh) . '::Encoding'; # then the class itself if available
    $lh->{'encoding'} = ${ $ns } if ${ $ns };
    
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

sub lang_names_hashref {
    my ($lh, @langcodes) = @_;
    
    if(!@langcodes) { # they havn't specified any langcodes...
        require File::Slurp; # only needed here, so we don't use() it
        require File::Spec;  # only needed here, so we don't use() it
        
        my @search;
        my $path = $lh->get_base_class();
        $path =~ s{::}{/}g; # !!!! make this File::Spec safe !! File::Spec->seperator() !-e
        
        if(ref $lh->{'_lang_pm_search_paths'} eq 'ARRAY') {
            @search = @{ $lh->{'_lang_pm_search_paths'} };
        }
        
        @search = @INC if !@search; # they havn't told us where they are specifically

        DIR:
        for my $dir (@search) {
            my $lookin = File::Spec->catdir($dir, $path);
            next DIR if !-d $lookin;
            PM:
            for my $pm (grep { /^\w+\.pm$/ } File::Slurp::read_dir($lookin)) {
                $pm =~ s{\.pm$}{};
                next PM if !$pm;
                push @langcodes, $pm;
            }
        }
    } 
    
    require Locales::Language; # only needed here, so we don't use() it
    my $obj_two_char = substr($lh->language_tag(), 0, 2); # Locales::Language only does two char ...
    Locales::Language::setLocale( $obj_two_char );
    my $langname = {};
    
    for my $code ('en', @langcodes) { # en since its "built in"
        my $two_char = substr($code, 0, 2); # Locales::Language only does two char ...
        my $left_ovr = length $code > 2 ? uc( substr($code, 3) ) : '';
        my $long_nam = Locales::Language::code2language( $two_char );

        $langname->{ $code } = $long_nam || $code; 
        $langname->{ $code } .= " ($left_ovr)" if $left_ovr && $long_nam;
    }
    
    return $langname;
}

sub loadable_lang_names_hashref {
    my ($lh, @langcodes) = @_;
    
    my $langname = $lh->lang_names_hashref(@langcodes);
    
    for my $tag( keys %{ $langname }) {
        delete $langname->{$tag} if !$lh->langtag_is_loadable( $tag );
    }
    
    return $langname;
}

1;

__END__

=head1 NAME

Locale::Maketext::Utils - Adds some utility functionality and failure handling to Local::Maketext handles

=head1 SYNOPSIS

In MyApp/Localize.pm:

    package MyApp::Localize;
    use Locale::Maketext::Utils; 
    use base 'Locale::Maketext::Utils'; 
  
    our $Encoding = 'utf8'; # see below
    
    # no _AUTO
    our %Lexicon = (...

Make all the language Lexicons you want. (no _AUTO)

Then in your script:
 
   my $lang = MyApp::Localize->get_handle('fr');

Now $lang is a normal Locale::Maketext handle object but now there are some new methods and failure handling which are described below.

=head1 our $Encoding

If you set your class's $Encoding variable the object's encoding will be set to that.

   my $enc = $lh->encoding(); 

$enc is $MyApp::Localize::fr::Encoding || $MyApp::Localize::Encoding || encoding()'s default

=head1 METHODS

=head2 $lh->print($key, @args);

Shortcut for

    print $lh->maketext($key, @args);

=head2 $lh->fetch($key, @args);

Alias for 

    $lh->maketext($key, @args);

=head2 $lh->get_base_class()

    Returns the base class of the object. So if $lh is a MyApp::Localize::fr object then it returns MyApp::Localize

=head2 $lh->get_language_tag()

Returns the real language name space being used, not language_tag()'s "cleaned up" one

=head2 $lh->langtag_is_loadable($lang_tag)

Returns 0 if the argument is not a language that can be used to get a handle.

Returns the language handle if it is a language that can be used to get a handle.

=head2 $lh->lang_names_hashref()

This returns a hashref whose keys are the language tags and the values are the 
name of language tag in $lh's native langauge.

It can be called several ways:

=over 4

=item * Give it a list of tags to lookup

    $lh->lang_names_hashref(@lang_tags)

=item * Have it search @INC for Base/Class/*.pm's 

    $lh->lang_names_hashref() # IE no args

=item * Have it search specific places for Base/Class/*.pm's 

    local $lh->{'_lang_pm_search_paths'} = \@lang_paths; # array ref of directories
    $lh->lang_names_hashref() # IE no args

=back

The module it uses for lookup (L<Locales::Language>) is only required when this method is called.

The module it uses for lookup (L<Locales::Language>) is currently limited to two character codes but we try to handle it gracefully here.

Does not ensure that the tags are loadable, to do that see below.

=head2 $lh->loadable_lang_names_hashref()

Exactly the same as $lh->lang_names_hashref() (because it calls that method...) except it only contains tags that are loadable.

Has additional overhead of calling $lh->langtag_is_loadable() on each key. So most likely you'd use this on a single specific place (a page to choose their language setting for instance) instead of calling it on every instance your script is run.

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

L<Locale::Maketext>, L<Locales::Language>

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