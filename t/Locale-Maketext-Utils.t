use Test::More tests => 35;
BEGIN { use_ok('Locale::Maketext::Utils') };

package TestApp::Localize;
use Locale::Maketext::Utils;
use base 'Locale::Maketext::Utils';

our $Encoding = 'utf8';

our %Lexicon = (
    '_AUTO'    => 42, 
    'Fallback' => 'Fallback orig',
    'One Side' => 'I am not one sides',
);

__PACKAGE__->make_alias('i_alias1', 1);

package TestApp::Localize::en;
use base 'TestApp::Localize';

package TestApp::Localize::en_us;
use base 'TestApp::Localize';

package TestApp::Localize::i_default;
use base 'TestApp::Localize';

package TestApp::Localize::i_oneside;
use base 'TestApp::Localize';

__PACKAGE__->make_alias( [qw(i_alias2 i_alias3)], 0 ); 
our $Onesided = 1;
our %Lexicon = (
    'One Side' => '',
);

package TestApp::Localize::fr;
use base 'TestApp::Localize';

our $Encoding = 'utf7';

our %Lexicon = (
    'Hello World' => 'Bonjour Monde',
);

package main;

my $noarg = TestApp::Localize->get_handle();
ok($noarg->language_tag() eq 'en', 'get_handle no arg');

my $first_lex = (@{ $noarg->_lex_refs() })[0];
ok(!exists $first_lex->{'_AUTO'}, '_AUTO removal/remove_key_from_lexicons()');
ok($noarg->{'_removed_from_lexicons'}{'0'}{'_AUTO'} eq '42', 
   '_AUTO removal archive/remove_key_from_lexicons()');

my $en = TestApp::Localize->get_handle('en');
ok($en->language_tag() eq 'en', 'get_handle en');
ok($en->langtag_is_loadable('invalid') eq '0', 'langtag_is_loadable() w/ unloadable tag');
ok(ref $en->langtag_is_loadable('fr') eq 'TestApp::Localize::fr', 
   'langtag_is_loadable() w/ loadable tag');

ok($en->encoding() eq 'utf8', 'base $Encoding');   
$en->{'_get_key_from_lookup'} = sub {
     return 'look up version';
};
ok($en->maketext('Needs looked up') eq 'look up version', '_get_key_from_lookup');

my $bad = TestApp::Localize->get_handle('bad');
ok($bad->language_tag() eq 'en', 'invalid get_handle arg');
$bad->{'_log_phantom_key'} = sub {
    $ENV{'_log_phantum_key'} = 'done';    
};
ok($bad->maketext('Not in Lexicon') eq 'Not in Lexicon'
   && $ENV{'_log_phantum_key'} eq'done', '_log_phantom_key');

my $oneside = TestApp::Localize->get_handle('i_oneside');
ok($TestApp::Localize::i_oneside::Lexicon{'One Side'} eq 'One Side', '$Onesided');

my $alias1 = TestApp::Localize->get_handle('i_alias1');
ok($alias1->get_language_tag() eq 'i_alias1', '$Aliaspkg w/ string');
my $alias2 = TestApp::Localize->get_handle('i_alias2');
ok($alias2->get_language_tag() eq 'i_alias2', '$Aliaspkg w/ array ref 1');
my $alias3 = TestApp::Localize->get_handle('i_alias3');
ok($alias3->get_language_tag() eq 'i_alias3', '$Aliaspkg w/ array ref 2');

ok($alias1->fetch('One Side') eq 'I am not one sides', 'Base class make_alias');
ok($alias2->fetch('One Side') eq 'One Side', 'Extended class make_alias');

my $en_US = TestApp::Localize->get_handle('en-US');
ok($en_US->language_tag() eq 'en-us', 'get_handle en-US');
ok($en_US->get_language_tag() eq 'en_us', 'get_language_tag()');

my $fr = TestApp::Localize->get_handle('fr');
ok($fr->language_tag() eq 'fr', 'get_handle fr');
ok($fr->get_base_class() eq 'TestApp::Localize', 'get_base_class()');
ok($fr->fetch('Hello World') eq 'Bonjour Monde', 'fetch() method'); 
# safe to assume print() will work to if fetch() does...

ok($fr->encoding() eq 'utf7', 'class $Encoding'); 
ok($fr->fetch('Fallback') eq 'Fallback orig', 'fallback  behavior');
ok($fr->fetch('Thank you') eq 'Thank you', 'fail_with _AUTO behavior');

$fr->append_to_lexicons({
    '_'  => {
        'Fallback' => 'Fallback new',  
    },
    'fr' => {
        'Thank you' => 'Merci',
    },
});

ok($fr->fetch('Thank you') eq 'Merci', 'append_to_lexicons()');
ok($fr->fetch('Fallback') eq 'Fallback new', 'fallback behavior after append');

my $fr_hr = $fr->lang_names_hashref('en-uk', 'it', 'xxyyzz');
ok($fr_hr->{'en'} eq 'Anglais', 'names default');
ok($fr_hr->{'en-uk'} eq 'Anglais (UK)', 'names suffix');
ok($fr_hr->{'it'} eq 'Italien', 'names normal');
ok($fr_hr->{'xxyyzz'} eq 'xxyyzz', 'names fake');

my $loadable_hr = $fr->loadable_lang_names_hashref('en-uk', 'it', 'xxyyzz', 'fr');

ok( (keys %{ $loadable_hr }) == 2
    && exists $loadable_hr->{'en'}
    && exists $loadable_hr->{'fr'}, 'loadable names');

# prepare 
my $dir = './my_lang_pm_search_paths_test';
mkdir $dir;
mkdir "$dir/TestApp";
mkdir "$dir/TestApp/Localize";
die "mkdir $@" if !-d "$dir/TestApp/Localize";

open my $pm, '>', "$dir/TestApp/Localize/it.pm" or die "open $!";
    print {$pm} <<'IT_END';
package TestApp::Localize::it;
use base 'TestApp::Localize';

__PACKAGE__->make_alias('it_us');

our %Lexicon = (
    'Hello World' => 'Ciao Mondo',  
);

1;
IT_END
close $pm;

require "$dir/TestApp/Localize/it.pm";
my $it_us = TestApp::Localize->get_handle('it_us');
ok($it_us->fetch('Hello World') eq 'Ciao Mondo', '.pm file alias test');

# _lang_pm_search_paths
$en->{'_lang_pm_search_paths'} = [$dir];
my $dir_hr = $en->lang_names_hashref();
ok( (keys %{ $dir_hr }) == 2
    && exists $dir_hr->{'en'}
    && exists $dir_hr->{'it'}, '_lang_pm_search_paths names');

# @INC
unshift @INC, $dir;
my $inc_hr = $fr->lang_names_hashref();
ok( (keys %{ $inc_hr }) == 2
    && exists $inc_hr->{'en'}
    && exists $inc_hr->{'it'}, '@INC names');

# cleanup 
unlink "$dir/TestApp/Localize/it.pm";
rmdir "$dir/TestApp/Localize";
rmdir "$dir/TestApp";
rmdir $dir;
warn "Could not cleanup $dir" if -d $dir;