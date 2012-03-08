use Test::More tests => 11;

BEGIN {
    chdir 't';
    unshift @INC, qw(lib ../lib);
    use_ok('Locale::Maketext::Utils');
    use_ok('MyTestLocale');

    sub MyTestLocale::foo {
        my ( $lh, $k ) = @_;

        return "cached: $lh->{cache}{foo}{$k}" if exists $lh->{cache}{foo}{$k};
        $lh->{cache}{foo}{$k} = "i am $k";
        return "$lh->{cache}{foo}{$k}";
    }
}

my $lh = MyTestLocale->get_handle('pt_br');

is( $lh->foo('x'), 'i am x',         'initial call returns correct value' );
is( $lh->foo('x'), 'cached: i am x', 'subsequent callreturns cached value' );

ok( exists $lh->{'cache'}{'foo'}, 'pre-flush-key has cache key' );
is_deeply(
    $lh->flush_cache('foo'),
    { x => 'i am x' },
    'flush_cache(key) returns deleted data'
);
ok( !exists $lh->{'cache'}{'foo'}, 'pst-flush-key cache key gone' );
ok( exists $lh->{'cache'},         'pst-flush-key cache still there' );

$lh->foo('x');
ok( exists $lh->{'cache'}{'foo'}, 'pre-flush has cache key' );
is_deeply(
    $lh->flush_cache(),
    { foo => { x => 'i am x' } },
    'flush_cache() returns deleted cache data'
);
ok( !exists $lh->{'cache'}, 'pst-flush cache key gone' );
