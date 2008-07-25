package Locale::Maketext::Utils;

use strict;
use warnings;
use version;our $VERSION = qv('0.0.10');

use Locale::Maketext;
use Locale::Maketext::Pseudo;
use base qw(Locale::Maketext);

our @EXPORT_OK = qw(env_maketext env_print env_fetch env_say env_get);

sub env_maketext {
    goto &Locale::Maketext::Pseudo::env_maketext;
}

sub env_print {
    goto &Locale::Maketext::Pseudo::env_print;
}       

sub env_fetch { 
    goto &Locale::Maketext::Pseudo::env_fetch; 
}               
                    
sub env_say { 
    goto &Locale::Maketext::Pseudo::env_say;
}
    
sub env_get {
     goto &Locale::Maketext::Pseudo::env_get;          
}

sub init {
    my ($lh) = @_;	
    
    $ENV{'maketext_obj'} = $lh if !$ENV{'maketext_obj_skip_env'};
    
    $lh->SUPER::init();
    $lh->remove_key_from_lexicons('_AUTO');

    # use the base class if available, then the class itself if available
    for my $ns ( $lh->get_base_class(),  ref($lh) ) {
        no strict 'refs';

        if( defined ${ $ns . '::Encoding' } ) {
            $lh->{'encoding'} = ${ $ns . '::Encoding' } if ${ $ns . '::Encoding' };  
        }
        
        if( defined ${ $ns . '::Onesided' } ) {
            if(${ $ns . '::Onesided' }) {
                my $lex_ref = \%{ $ns . '::Lexicon' };
                %{ $ns . '::Lexicon' } = map { 
                    my $v = $lex_ref->{$_} ne '' ? $lex_ref->{$_} : $_;
                    $_ => $v 
                } keys %{ $ns . '::Lexicon' };
            }
        }
        ${ $ns . '::Lexicon' }{'-DateTime'} = sub {
			my ($lh, $dta, $str) = @_;
			require DateTime;		
		    my $dt = !defined $dta      ? DateTime->now()
		           : ref $dta eq 'HASH' ? DateTime->new( %{ $dta } ) 
		           :                      $dta->clone()
		           ; 
		    $dt->{'locale'} = DateTime::Locale->load( $lh->language_tag() );
		    my $format = ref $str eq 'CODE' ? $str->( $dt ) : $str;
			return $dt->strftime( $format || $dt->{'locale'}->long_date_format() );	
		};
    }
    
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

sub make_alias {
    my ($lh, $pkgs, $is_base_class) = @_;    
    
    my $ns = ref $lh ? ref $lh : $lh;
    return if $ns !~ m{ \A \w+ (::\w+)* \z }xms;
    my $base = $is_base_class ? $ns : $lh->get_base_class();
    
    for my $pkg (ref $pkgs ? @{ $pkgs } : $pkgs) {
        next if $pkg !~ m{ \A \w+ (::\w+)* \z }xms;
        eval qq{package $base\:\:$pkg;use base '$ns';package $ns;};
    }
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
    my $ns = shift;
    $ns = ref $ns if ref $ns;        
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

sub say {
    local $Carp::CarpLevel = 1; 
    my $text = shift->maketext(@_);
    local $/ = !defined $/ || !$/ ? "\n" : $/; # otherwise assume they are not stupid 
    print $text . $/ if $text;
}

sub get {
    local $Carp::CarpLevel = 1; 
    my $text = shift->maketext(@_);
    local $/ = !defined $/ || !$/ ? "\n" : $/; # otherwise assume they are not stupid   
    return $text . $/ if $text;
    return; 
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

sub AUTOLOAD {
    my $self = shift;
	my $type = ref($self) or Carp::croak "$self is not an object";

	my $name = lc( our $AUTOLOAD );
	$name =~ s{.*:}{};

    my @name = split /_/, $name;
    if($name[0] eq 'say' || $name[0] eq 'print' || $name[0] eq 'get' || $name[0] eq 'fetch') {
        my $method = $name[0];
        my $tag    = $name[1];
        my $classy = @name == 4 ? $name[2] : '';
        my $part   = @name == 4 ? $name[3] : $name[2];
        $part      = '' if !$part;
        
        if($part ne 'open' && $part ne 'close') {
            $classy = $part;
            $part   = '';
        }

        my $string = $classy ? qq(<$tag class="$classy">) : "<$tag>" if $part eq 'open' || !$part;
        $string   .= $self->fetch(@_);
        $string   .= "</$tag>" if $part eq 'close' || !$part;
        local $/   = "\n" if !defined $/      || !$/; # otherwise assume they are not stupid
        $string   .= "$/"   if $method eq 'say' || $method eq 'get';

        print  $string    if $method eq 'say' || $method eq 'print';
        return $string    if $method eq 'get' || $method eq 'fetch';
    }

    return;
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
  
    our $Encoding = 'utf-8'; # see below
    
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

=head1 our $Onesided

Setting this to a true value treats the class's %Lexicon as one sided. What that means is if the hash's keys and values will be the same (IE your main Lexicon) you can specify it in the key only and leave the value blank. 

So instead of a Lexicon entry like this:

   q{Hello I love you won't you tell me your name} => q{Hello I love you won't you tell me your name},

You just do:
  
    q{Hello I love you won't you tell me your name} => '',
    
The advantages are a smaller file, less prone to mistyping or mispasting, and 
most important of all someone translating it can simply copy it into their module and enter their translation instead of having to remove the value first.   
 
=head1 Aliasing

In your package you can create an alias with this:

   __PACKAGE__->make_alias($langs, 1);
   or
   MyApp::Localize->make_alias([qw(en en_us i_default)], 1);
   
   __PACKAGE__->make_alias($langs);
   or
   MyApp::Localize::fr->make_alias('fr_ca');
   
Where $langs is a string or a reference to an array of strings that are the aliased language tags.

You must set the second argument to true if __PACKAGE__ is the base class.

The reason is there is no way to tell if the pakage name is the base class or not.

This needs done before you call get_handle() or it will have no effect on your object really.

Ideally you'd put all calls to this in the main lexicon to ensure it will apply to any get_handle() calls.

Alternatively, and at times more ideally, you can keep each module's aliases in them and then when setting your obj require the module first.

=head1 Special Lexicon keys

These are special keys you're Lexicon will have.

=over 4

=item * -DateTime

This key allows you to add localization to your language object.

    $lang->maketext('-DateTime');
    $lang->maketext('-DateTime', $datetime); 
    $lang->maketext('-DateTime', $datetime, $format);

In the example above: 

$datetime could be a L<DateTime> object *or* a hashref of args suitable for DateTime->new(). undefined = DateTime->now()

$format could be a string suitable for DateTime->strftime (Eg '%F %H:%M:%S') *or* a coderef that gets passed a DateTime object and returns a string suitable for DateTime->strftime. undef = L<DateTime::Locale>'s long_date_format()

    sub { $_[0]->{'locale'}->long_datetime_format } # use localized DateTime::Locale format method    

    $lang->maketext('-DateTime', undef, sub { $_[0]->{'locale'}->long_datetime_format } ); # current datetime in format and language of Lexicon's Locale

=back

=head1 METHODS

=head2 $lh->print($key, @args);

Shortcut for

    print $lh->maketext($key, @args);

=head2 $lh->fetch($key, @args);

Alias for 

    $lh->maketext($key, @args);

=head2 $lh->say($key, @args);

Like $lh->print($key, @args); except appends $/ || \n

=head2 $lh->get($key, @args);

Like $lh->fetch($key, @args); except appends $/ || \n

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

=head1 Project example

Main Class:

    package MyApp::Localize;
    use Locale::Maketext::Utils; 
    use base 'Locale::Maketext::Utils'; 

    our $Onesided = 1;
    our $Encoding = 'utf-8'; 
    
    __PACKAGE__->make_alias([qw(en en_us i_default)], 1);
    
    our %Lexicon = (
        'Hello World' => '',
    );
    
    1;

French class: 

    package MyApp::Localize::fr;
    use base 'MyApp::Localize';

    __PACKAGE__->make_alias('fr_ca');
    
    our %Lexicon = (
        'Hello World' => 'Bonjour Monde',
    );
    
    1;


=head1 ENVIRONMENT

$ENV{'maketext_obj'} gets set to the language object on initialization ( for functions to use, see "FUNCTIONS" below ) unless $ENV{'maketext_obj_skip_env'} is true

=head1 FUNCTIONS

All are exportable, each takes the same args as the method of the same name (sans 'env_') 
and each uses $ENV{'maketext_obj'} if valid or it uses a L<Local::Maketext::Pseudo> object.

=over 4

=item env_maketext()

=item env_fetch()

=item env_print()

=item env_get()

=item env_say()

=back


=head1 SEE ALSO

L<Locale::Maketext>, L<Locales::Language>, L<Locale::Maketext::Pseudo>

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