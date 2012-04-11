use Test::More tests => 15;

use Locale::Maketext::Utils::Phrase::Norm;

my $no_arg    = Locale::Maketext::Utils::Phrase::Norm->new();
my $true_arg  = Locale::Maketext::Utils::Phrase::Norm->new( { 'run_extra_filters' => 1 } );
my $false_arg = Locale::Maketext::Utils::Phrase::Norm->new( { 'run_extra_filters' => 0 } );

ok( !$no_arg->run_extra_filters(),    'defaults to off' );
ok( $true_arg->run_extra_filters(),   'true arg is on' );
ok( !$false_arg->run_extra_filters(), 'false arg is off' );

is( $false_arg->enable_extra_filters(), 1, 'enable_extra_filters() returns 1' );
ok( $false_arg->run_extra_filters(), 'enable_extra_filters() enabled it' );

is( $true_arg->disable_extra_filters(), 0, 'disable_extra_filters() returns 0' );
ok( !$true_arg->run_extra_filters(), 'disable_extra_filters() disabled it' );

my $spec = Locale::Maketext::Utils::Phrase::Norm->new( 'EndPunc', 'Consider', { 'skip_defaults_when_given_filters' => 1 } );

my $res = $spec->normalize('JAPH [_1] yo');
ok( $res->get_status(), 'extra filters not applied when disabled (entire module and partial module)' );

my $filt = $res->get_filter_results();
is( $filt->[0]->get_status(), 1, 'entire module extra skipped' );
is( $filt->[1]->get_status(), 1, 'partial module extra skipped' );

ok( exists $spec->{'cache'}{'JAPH [_1] yo'}, 'normalize() cached phrase' );
$spec->enable_extra_filters();
ok( !exists $spec->{'cache'}{'JAPH [_1] yo'}, 'changing filter state clears cache' );

$res = $spec->normalize('JAPH [_1] yo');
is( $res->get_status(), -1, 'extra filters applied when disabled (entire module and partial module)' );

$filt = $res->get_filter_results();
is( $filt->[0]->get_status(), -1, 'entire module extra run' );
is( $filt->[1]->get_status(), -1, 'partial module extra run' );
