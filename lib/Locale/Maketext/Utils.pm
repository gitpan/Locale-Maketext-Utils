package Locale::Maketext::Utils;

use strict;
use warnings;
$Locale::Maketext::Utils::VERSION = '0.17';

use Locale::Maketext;
@Locale::Maketext::Utils::ISA = qw(Locale::Maketext);

my %singleton_stash = ();

sub get_handle {
    my ( $class, @langtags ) = @_;

    # order is important so we don't sort() in an attempt to normalize (i.e. fr, es is not the same as es, fr)
    my $args_sig = join( ',', @langtags ) || 'no_args';

    if ( exists $singleton_stash{$class}{$args_sig} ) {
        $singleton_stash{$class}{$args_sig}->{'_singleton_reused'}++;
    }
    else {
        $singleton_stash{$class}{$args_sig} = $class->SUPER::get_handle(@langtags);
    }

    return $singleton_stash{$class}{$args_sig};
}

sub init {
    my ($lh) = @_;

    $ENV{'maketext_obj'} = $lh if !$ENV{'maketext_obj_skip_env'};

    $lh->SUPER::init();
    $lh->remove_key_from_lexicons('_AUTO');
    
    # use the base class if available, then the class itself if available
    no strict 'refs';
    for my $ns ( $lh->get_base_class(), $lh->get_language_class() ) {
        if ( defined ${ $ns . '::Encoding' } ) {
            $lh->{'encoding'} = ${ $ns . '::Encoding' } if ${ $ns . '::Encoding' };
        }
    }

    $lh->fail_with(
        sub {
            my ( $lh, $key, @args ) = @_;

            my $lookup;
            if ( exists $lh->{'_get_key_from_lookup'} ) {
                if ( ref $lh->{'_get_key_from_lookup'} eq 'CODE' ) {
                    $lookup = $lh->{'_get_key_from_lookup'}->( $lh, $key, @args );
                }
            }

            return $lookup if defined $lookup;

            if ( exists $lh->{'_log_phantom_key'} ) {
                if ( ref $lh->{'_log_phantom_key'} eq 'CODE' ) {
                    $lh->{'_log_phantom_key'}->( $lh, $key, @args );
                }
            }
            
            no strict 'refs';
            local ${ $lh->get_base_class() . '::Lexicon' }{'_AUTO'} = 1;
            return $lh->maketext( $key, @args );
        }
    );
}

sub make_alias {
    my ( $lh, $pkgs, $is_base_class ) = @_;

    my $ns = $lh->get_language_class();
    return if $ns !~ m{ \A \w+ (::\w+)* \z }xms;
    my $base = $is_base_class ? $ns : $lh->get_base_class();

    no strict 'refs';
    for my $pkg ( ref $pkgs ? @{$pkgs} : $pkgs ) {
        next if $pkg !~ m{ \A \w+ (::\w+)* \z }xms;
        *{ $base .'::' . $pkg .'::VERSION' }  = *{ $ns . '::VERSION'};
        *{ $base .'::' . $pkg .'::Onesided' } = *{ $ns . '::Onesided'};
        *{ $base .'::' . $pkg .'::Lexicon' }  = *{ $ns . '::Lexicon'};
        @{ $base .'::' . $pkg .'::ISA' }      = ($ns);
    }
}

sub remove_key_from_lexicons {
    my ( $lh, $key ) = @_;
    my $idx = 0;

    for my $lex_hr ( @{ $lh->_lex_refs() } ) {
        $lh->{'_removed_from_lexicons'}{$idx}{$key} = delete $lex_hr->{$key}
          if exists $lex_hr->{$key};
        $idx++;
    }
}

sub get_base_class {
    my $ns = shift->get_language_class();
    $ns =~ s{::\w+$}{};
    return $ns;
}

sub append_to_lexicons {
    my ( $lh, $appendage ) = @_;
    return if ref $appendage ne 'HASH';

    no strict 'refs';
    for my $lang ( keys %{$appendage} ) {
        my $ns = $lh->get_base_class() . ( $lang eq '_' ? '' : "::$lang" ) . '::Lexicon';
        %{$ns} = ( %{$ns}, %{ $appendage->{$lang} } );
    }
}

sub langtag_is_loadable {
    my ( $lh, $wants_tag ) = @_;
    $wants_tag = Locale::Maketext::language_tag($wants_tag);

    # why doesn't this work ?
    # no strict 'refs';
    # my $tag_obj = ${ $lh->get_base_class() }->get_handle( $wants_tag );
    my $tag_obj = eval $lh->get_base_class() . q{->get_handle( $wants_tag );};

    my $has_tag = $tag_obj->language_tag();
    return $wants_tag eq $has_tag ? $tag_obj : 0;
}

sub get_language_tag {
    return ( split '::', shift->get_language_class() )[-1];
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
    local $/ = !defined $/ || !$/ ? "\n" : $/;    # otherwise assume they are not stupid
    print $text . $/ if $text;
}

sub get {
    local $Carp::CarpLevel = 1;
    my $text = shift->maketext(@_);
    local $/ = !defined $/ || !$/ ? "\n" : $/;    # otherwise assume they are not stupid
    return $text . $/ if $text;
    return;
}

sub lang_names_hashref {
    my ( $lh, @langcodes ) = @_;

    if ( !@langcodes ) {                          # they havn't specified any langcodes...
        require File::Slurp;                      # only needed here, so we don't use() it
        require File::Spec;                       # only needed here, so we don't use() it

        my @search;
        my $path = $lh->get_base_class();
        $path =~ s{::}{/}g;                       # !!!! make this File::Spec safe !! File::Spec->seperator() !-e

        if ( ref $lh->{'_lang_pm_search_paths'} eq 'ARRAY' ) {
            @search = @{ $lh->{'_lang_pm_search_paths'} };
        }

        @search = @INC if !@search;               # they havn't told us where they are specifically

      DIR:
        for my $dir (@search) {
            my $lookin = File::Spec->catdir( $dir, $path );
            next DIR if !-d $lookin;
          PM:
            for my $pm ( grep { /^\w+\.pm$/ } File::Slurp::read_dir($lookin) ) {
                $pm =~ s{\.pm$}{};
                next PM if !$pm;
                push @langcodes, $pm;
            }
        }
    }

    require Locales::Language;    # only needed here, so we don't use() it
    
    local $Locales::Base::SIG{__WARN__} = sub { };    # stifle copious and useless-for-our-purposes warn()'s ...

    my $obj_two_char = substr( $lh->language_tag(), 0, 2 );    # Locales::Language only does two char ...

    my $langname  = {};
    my $native    = wantarray ? {} : undef;
    my $getLocale = Locales::Language::getLocale();

    Locales::Language::setLocale($obj_two_char);

    for my $code ( 'en', @langcodes ) {                        # en since its "built in"
        my $two_char = substr( $code, 0, 2 );                  # Locales::Language only does two char ...
        my $left_ovr = length $code > 2 ? uc( substr( $code, 3 ) ) : '';
        my $long_nam = Locales::Language::code2language($two_char);

        $langname->{$code} = $long_nam || $code;
        $langname->{$code} .= " ($left_ovr)" if $left_ovr && $long_nam;

        if ( defined $native ) {
            Locales::Language::setLocale($code);

            my $long_nam = Locales::Language::code2language($two_char);
            $native->{$code} = $long_nam || $code;
            $native->{$code} .= " ($left_ovr)" if $left_ovr && $long_nam;

            Locales::Language::setLocale($obj_two_char);
        }
    }

    Locales::Language::setLocale($getLocale);

    return wantarray ? ( $langname, $native ) : $langname;
}

sub loadable_lang_names_hashref {
    my ( $lh, @langcodes ) = @_;

    my $langname = $lh->lang_names_hashref(@langcodes);

    for my $tag ( keys %{$langname} ) {
        delete $langname->{$tag} if !$lh->langtag_is_loadable($tag);
    }

    return $langname;
}

sub add_lexicon_override_hash {
    my ( $lh, $langtag, $name, $hr ) = @_;
    if ( @_ == 3 ) {
        $hr      = $name;
        $name    = $langtag;
        $langtag = $lh->get_language_tag();
    }

    my $ns = $lh->get_language_tag() eq $langtag ? $lh->get_language_class() : $lh->get_base_class();

    no strict 'refs';
    if ( my $ref = tied( %{ $ns . '::Lexicon' } ) ) {
        return 1 if $lh->{'add_lex_hash_silent_if_already_added'} && exists $ref->{'hashes'} && exists $ref->{'hashes'}{$name};
        if ( $ref->can('add_lookup_override_hash') ) {
            return $ref->add_lookup_override_hash( $name, $hr );
        }
    }

    my $cur_errno = $!;
    if ( eval { require Sub::Todo } ) {
        goto &Sub::Todo::todo;
    }
    else { 
        $! = $cur_errno; 
        return;
    }
}

sub add_lexicon_fallback_hash {
    my ( $lh, $langtag, $name, $hr ) = @_;
    if ( @_ == 3 ) {
        $hr      = $name;
        $name    = $langtag;
        $langtag = $lh->get_language_tag();
    }

    my $ns = $lh->get_language_tag() eq $langtag ? $lh->get_language_class() : $lh->get_base_class();

    no strict 'refs';
    if ( my $ref = tied( %{ $ns . '::Lexicon' } ) ) {
        return 1 if $lh->{'add_lex_hash_silent_if_already_added'} && exists $ref->{'hashes'} && exists $ref->{'hashes'}{$name};
        if ( $ref->can('add_lookup_fallback_hash') ) {
            return $ref->add_lookup_fallback_hash( $name, $hr );
        }
    }

    my $cur_errno = $!;
    if ( eval { require Sub::Todo } ) {
        goto &Sub::Todo::todo;
    }
    else {
        $! = $cur_errno;
        return;
    }
}

sub del_lexicon_hash {
    my ( $lh, $langtag, $name ) = @_;

    if ( @_ == 2 ) {
        return if $langtag eq '*';
        $name    = $langtag;
        $langtag = '*';
    }

    return if !$langtag;

    my $count = 0;
    if ( $langtag eq '*' ) {
        no strict 'refs';
        for my $ns ( $lh->get_base_class(), $lh->get_language_class() ) {
            if ( my $ref = tied( %{ $ns . '::Lexicon' } ) ) {
                if ( $ref->can('del_lookup_hash') ) {
                    $ref->del_lookup_hash($name);
                    $count++;
                }
            }
        }

        return 1 if $count;

        my $cur_errno = $!;
        if ( eval { require Sub::Todo } ) {
            goto &Sub::Todo::todo;
        }
        else {
            $! = $cur_errno;
            return;
        }
    }
    else {
        my $ns = $lh->get_language_tag() eq $langtag ? $lh->get_language_class() : $lh->get_base_class();

        no strict 'refs';
        if ( my $ref = tied( %{ $ns . '::Lexicon' } ) ) {
            if ( $ref->can('del_lookup_hash') ) {
                return $ref->del_lookup_hash($name);
            }
        }

        my $cur_errno = $!;
        if ( eval { require Sub::Todo } ) {
            goto &Sub::Todo::todo;
        }
        else {
            $! = $cur_errno;
            return;
        }
    }
}

sub get_language_class {
    my ($lh) = @_;
    return ( ref($lh) || $lh );
}

# $Autoalias is a bad idea, if we did this method we'd need to do a proper symbol/ISA traversal
# sub get_alias_list {
#    my ($lh, $ns) = @_;
#    $ns ||= $lh->get_base_class();
#
#    no strict 'refs';
#    if (defined @{ $ns . "::Autoalias"}) {
#        return @{ $ns . "::Autoalias"};
#    }
#
#    return;
# }

sub get_base_class_dir {
    my ($lh) = @_;
    if ( !exists $lh->{'Locale::Maketext::Utils'}{'_base_clase_dir'} ) {
        $lh->{'Locale::Maketext::Utils'}{'_base_clase_dir'} = undef;

        my $inc_key = $lh->get_base_class();

        # require File::Spec;  # only needed here, so we don't use() it
        $inc_key =~ s{::}{/}g;    # TODO make portable via File::Spec
        $inc_key .= '.pm';
        if ( exists $INC{$inc_key} ) {
            if ( -e $INC{$inc_key} ) {
                $lh->{'Locale::Maketext::Utils'}{'_base_clase_dir'} = $INC{$inc_key};
                $lh->{'Locale::Maketext::Utils'}{'_base_clase_dir'} =~ s{\.pm$}{};
            }
        }
    }

    return $lh->{'Locale::Maketext::Utils'}{'_base_clase_dir'};
}

sub list_available_locales {
    my ($lh) = @_;

    # all comments in this function relate to get_alias_list() above
    # my ($lh, $include_fileless_aliases) = @_;

    # my $base;
    # if ($include_fileless_aliases) {
    #     $base = $lh->get_base_class_dir();
    # }

    my $main_ns_dir = $lh->get_base_class_dir() || return;

    # return ($lh->get_alias_list($base)), grep { $_ ne 'Utils' }
    return grep { $_ ne 'Utils' }
      map {
        my ($modified) = reverse( split( '/', $_ ) );
        substr( $modified, -3, 3, '' );    # we know the last 3 are '.pm'
                                           # see get_alias_list() above, $base ? ( $modified, $lh->get_alias_list($base . '::' . $modified) ) : $modified;
        $modified;
      } glob("$main_ns_dir/*.pm");
}

#### numf() w/ decimal ##

sub numf {
    my ( $handle, $num, $decimal_places ) = @_;

    if ( $num < 10_000_000_000 and $num > -10_000_000_000 and $num == int($num) ) {
        $num += 0;
    }
    elsif ( defined $decimal_places && ( $num =~ m{^\d+\.\d+$} || $decimal_places eq '' ) ) {
        $num += 0;
    }
    else {
        $num = CORE::sprintf( '%G', $num );
    }
    while ( $num =~ s/^([-+]?\d+)(\d{3})/$1,$2/s ) { 1 }    # right from perlfaq5

    if ( defined $decimal_places && $decimal_places ne '' ) {
        no warnings;                                        # Argument "%.3f" isn't numeric in int at
        my $safe_decimal_places = abs( int($decimal_places) );
        if ($safe_decimal_places) {
            $num =~ s/(^\d{1,}\.\d{$safe_decimal_places})(.*$)/$1/;
        }
        elsif ( $safe_decimal_places eq $decimal_places ) {
            $num =~ s/\.\d+$//;
        }
        else {
            $num = CORE::sprintf( $decimal_places, $num );
        }
    }

    $num =~ tr<.,><,.> if ref($handle) and $handle->{'numf_comma'};

    return $num;
}

#### / numf() w/ decimal/formatter ##

#### range support ##

# DO NOT advertise this yet as it makes the lookup break
#     key of '[foo,1_.._#]' becomes '[foo,_1,_2, ... _N]' on and on depending on length of args _N so its dynamic and can't be in lexicon
# We could override _compile instead *if* we could get the lenth of the caller's @_ at that point (and rely that core always has @_ filled only with args at that point)
# it'd be better if it was in Locale::Maketext: rt 37955

sub maketext {
    my ( $class, $key, @args ) = @_;

    while ( $key =~ m{(_(\-?\d+).._(\-?\d+|\#))} ) {
        my $rem = $1;
        my $end = $3 eq '#' ? scalar(@args) : $3;
        my $chg = '';

        for my $n ( $2 .. $end ) {
            next if $n == 0;
            $chg .= "_$n,";
        }

        $chg =~ s/\,$//;

        Locale::Maketext::DEBUG() and warn "RANGE: $rem -> $chg";

        $key =~ s{\Q$rem\E}{$chg}g;
    }

    # if (exists $INC{'utf8.pm'}) {
    #     utf8::is_utf8($key) or utf8::decode($key)
    #     for( @args ) {
    #         utf8::is_utf8($_) or utf8::decode($_);
    #     }
    # }

    my $value = __maketext( $class, $key, @args );

    # it'd be better if $Onesided support was in Locale::Maketext: rt 46051
    if ( !defined $value || $value eq '' ) {

        # use the class itself if available, then the base class
        no strict 'refs';
        for my $ns ( $class->get_language_class(), $class->get_base_class() ) {
            if ( defined ${ $ns . '::Onesided' } ) {
                if ( ${ $ns . '::Onesided' } ) {
                    my $lex_ref = \%{ $ns . '::Lexicon' };
                    if ($class->{'use_external_lex_cache'}) {
                        $class->{'_external_lex_cache'}{$key} = $key;
                    }
                    else {
                        $lex_ref->{$key} = $key;
                    }
                    
                    return __maketext( $class, $key, @args );
                }
            }
        }
    }

    return $value;
}

#### /range support ##

###########################################################################
## L::M::maketext() 1.13
## UNDO once https://rt.cpan.org/Ticket/Display.html?id=46738 is done ##

require Carp;
my %isa_scan;

sub __maketext {
    # Remember, this can fail.  Failure is controllable many ways.
    Carp::croak 'maketext requires at least one parameter' unless @_ > 1;

    my($handle, $phrase) = splice(@_,0,2);
    Carp::confess('No handle/phrase') unless (defined($handle) && defined($phrase));

    # Don't interefere with $@ in case that's being interpolated into the msg.
    local $@;

    # Look up the value:
    my $value;
    if (exists $handle->{'_external_lex_cache'}{$phrase}) {
        Locale::Maketext::DEBUG and warn "* Using external lex cache version of \"$phrase\"\n";
        $value = $handle->{'_external_lex_cache'}{$phrase};
    }
    else {
        foreach my $h_r (
            @{  $isa_scan{ref($handle) || $handle} || $handle->_lex_refs  }
        ) {        
            Locale::Maketext::DEBUG and warn "* Looking up \"$phrase\" in $h_r\n";
            if(exists $h_r->{$phrase}) {
                Locale::Maketext::DEBUG and warn "  Found \"$phrase\" in $h_r\n";
                unless(ref($value = $h_r->{$phrase})) {
                    # Nonref means it's not yet compiled.  Compile and replace.
                    if ($handle->{'use_external_lex_cache'}) {
                        $value = $handle->{'_external_lex_cache'}{$phrase} = $handle->_compile($value);
                    }
                    else {
                        $value = $h_r->{$phrase} = $handle->_compile($value);
                    }
                }
                last;
            }
            elsif($phrase !~ m/^_/s and $h_r->{'_AUTO'}) {
                # it's an auto lex, and this is an autoable key!
                Locale::Maketext::DEBUG and warn "  Automaking \"$phrase\" into $h_r\n";
                if ($handle->{'use_external_lex_cache'}) {
                    $value = $handle->{'_external_lex_cache'}{$phrase} = $handle->_compile($phrase);
                }
                else {
                    $value = $h_r->{$phrase} = $handle->_compile($phrase);
                }
                last;
            }
            Locale::Maketext::DEBUG>1 and print "  Not found in $h_r, nor automakable\n";
            # else keep looking
        }
    }

    unless(defined($value)) {
        Locale::Maketext::DEBUG and warn "! Lookup of \"$phrase\" in/under ", ref($handle) || $handle, " fails.\n";
        if(ref($handle) and $handle->{'fail'}) {
            Locale::Maketext::DEBUG and warn "WARNING0: maketext fails looking for <$phrase>\n";
            my $fail;
            if(ref($fail = $handle->{'fail'}) eq 'CODE') { # it's a sub reference
                return &{$fail}($handle, $phrase, @_);
                # If it ever returns, it should return a good value.
            }
            else { # It's a method name
                return $handle->$fail($phrase, @_);
                # If it ever returns, it should return a good value.
            }
        }
        else {
            # All we know how to do is this;
            Carp::croak("maketext doesn't know how to say:\n$phrase\nas needed");
        }
    }

    return $$value if ref($value) eq 'SCALAR';
    return $value unless ref($value) eq 'CODE';

    {
        local $SIG{'__DIE__'};
        eval { $value = &$value($handle, @_) };
    }
    # If we make it here, there was an exception thrown in the
    #  call to $value, and so scream:
    if ($@) {
        my $err = $@;
        # pretty up the error message
        $err =~ s{\s+at\s+\(eval\s+\d+\)\s+line\s+(\d+)\.?\n?}
                 {\n in bracket code [compiled line $1],}s;
        #$err =~ s/\n?$/\n/s;
        Carp::croak "Error in maketexting \"$phrase\":\n$err as used";
        # Rather unexpected, but suppose that the sub tried calling
        # a method that didn't exist.
    }
    else {
        return $value;
    }
}

## /L::M 1.13
###########################################################################

#### more BN methods ##

sub join {
    shift;
    return CORE::join( shift, @_ );
}

sub list {
    my $lh      = shift;
    my $com_sep = ', ';
    my $oxford  = ',';
    my $def_sep = '&';

    if ( ref($lh) ) {
        $com_sep = $lh->{'list_seperator'}   if exists $lh->{'list_seperator'};
        $oxford  = $lh->{'oxford_seperator'} if exists $lh->{'oxford_seperator'};
        $def_sep = $lh->{'list_default_and'} if exists $lh->{'list_default_and'};
    }

    my $sep = shift || $def_sep;
    return if !@_;

    if ( @_ == 1 ) {
        return $_[0];
    }
    elsif ( @_ == 2 ) {
        return CORE::join( " $sep ", @_ );
    }
    else {
        my $last = pop @_;
        return CORE::join( $com_sep, @_ ) . "$oxford $sep $last";
    }
}

sub datetime {
    my ( $lh, $dta, $str ) = @_;
    require DateTime;
    my $dt =
       !defined $dta ? DateTime->now()
      : ref $dta eq 'HASH' ? DateTime->new( %{$dta} )
      : $dta =~ m{ \A (\d+ (?: [.] \d+ )? ) (?: [:] (.*) )? \z }xms ? DateTime->from_epoch( 'epoch' => $1, 'time_zone' => ( $2 || 'UTC' ) )
      : !ref $dta ? DateTime->now( 'time_zone' => ( $dta || 'UTC' ) )
      :             $dta->clone();

    $dt->{'locale'} = DateTime::Locale->load( $lh->language_tag() );
    my $format = ref $str eq 'CODE' ? $str->($dt) : $str;
    if ( defined $format ) {
        if ( $dt->{'locale'}->can($format) ) {
            $format = $dt->{'locale'}->$format();
        }
    }

    return $dt->strftime( $format || $dt->{'locale'}->long_date_format() );
}

sub format_bytes {
    shift;
    require Number::Bytes::Human;
    return Number::Bytes::Human::format_bytes(@_);
}

sub convert {
    shift;
    require Math::Units;
    return Math::Units::convert(@_);
}

sub boolean {
    my ( $lh, $boolean, $true, $false, $null ) = @_;
    if ($boolean) {
        return $true;
    }
    else {
        if ( !defined $boolean && defined $null ) {
            return $null;
        }
        return $false;
    }
}

sub output {
    my ( $lh, $output_function, $string, @output_function_args ) = @_;
    if ( my $cr = $lh->can( 'output_' . $output_function ) ) {
        return $cr->( $lh, $string, @output_function_args );
    }
    else {
        my $cur_errno = $!;
        if ( eval { require Sub::Todo } ) {
            $! = Sub::Todo::get_errno_func_not_impl();
        }
        else {
            $! = $cur_errno; 
        }
        return $string;
    }
}

sub output_underline {
    my ( $lh, $string ) = @_;
    return ( exists $lh->{'-t-STDIN'} ? $lh->{'-t-STDIN'} : -t STDIN ) ? "\e[4m$string\e[0m" : qq{<span style="text-decoration: underline">$string</span>};
}

sub output_strong {
    my ( $lh, $string ) = @_;
    return ( exists $lh->{'-t-STDIN'} ? $lh->{'-t-STDIN'} : -t STDIN ) ? "\e[1m$string\e[0m" : "<strong>$string</strong>";
}

sub output_em {
    my ( $lh, $string ) = @_;

    # italic code 3 is specified in ANSI X3.64 and ECMA-048 but are not commonly supported by most displays and emulators, but we can try!
    return ( exists $lh->{'-t-STDIN'} ? $lh->{'-t-STDIN'} : -t STDIN ) ? "\e[3m$string\e[0m" : "<em>$string</em>";
}

sub output_url {
    my ( $lh, $url, %output_config ) = @_;

    my $return = $url;
    if ( ( exists $lh->{'-t-STDIN'} ? $lh->{'-t-STDIN'} : -t STDIN ) ) {
        if ( exists $output_config{'plain'} ) {
            if ( my @count = $output_config{'plain'} =~ m{(\%s)\b}g ) {
                my $count = @count;
                my @sprintf_args;
                for ( 1 .. $count ) {
                    push @sprintf_args, $url;
                }
                $return = sprintf( $output_config{'plain'}, @sprintf_args );
            }
            else {
                $return = "$output_config{'plain'} $url";
            }
        }
    }
    else {
        $output_config{'html'} ||= $url;
        $return = exists $output_config{'_type'}
          && $output_config{'_type'} eq 'offsite' ? qq{<a target="_blank" class="offsite" href="$url">$output_config{'html'}</a>} : qq{<a href="$url">$output_config{'html'}</a>};
    }

    return $return;
}

#### / more BN methods ##

1;
