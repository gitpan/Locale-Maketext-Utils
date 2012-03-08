use Test::More tests => 93;

BEGIN {
    chdir 't';
    unshift @INC, qw(lib ../lib);
    use_ok('Locale::Maketext::Utils');
    use_ok('MyTestLocale');
}

my $lh = MyTestLocale->get_handle('en');

$lh->{'-t-STDIN'} = 1;
is( $lh->maketext('x [output,underline,y] z'), "x \e[4my\e[0m z", 'output underline text' );
is( $lh->maketext('x [output,strong,y] z'),    "x \e[1my\e[0m z", 'output strong text' );
is( $lh->maketext('x [output,em,y] z'),        "x \e[3my\e[0m z", 'output em text' );

is( $lh->maketext( 'Please [output,url,_1,plain,execute,html,click here].',                                       'CMD HERE' ), 'Please execute CMD HERE.',                                          'plain url append (cmd context)' );
is( $lh->maketext( 'Please [output,url,_1,plain,visit,html,click here].',                                         'URL HERE' ), 'Please visit URL HERE.',                                            'plain url append (url context)' );
is( $lh->maketext( q{Please [output,url,_1,plain,execute '%s' when you can,html,click here].},                    'CMD HERE' ), q{Please execute 'CMD HERE' when you can.},                          'plain url with placeholder' );
is( $lh->maketext( q{Please [output,url,_1,plain,go to '%s' (again that is '%s') when you can,html,click here].}, 'URL HERE' ), q{Please go to 'URL HERE' (again that is 'URL HERE') when you can.}, 'plain url with multiple placeholders' );

is( $lh->maketext( 'My favorite site is [output,url,_1,_type,offsite].', 'http://search.cpan.org' ), 'My favorite site is http://search.cpan.org.', 'plain no value uses URL' );

is( $lh->maketext('X [output,chr,34] Y'), "X \" Y", 'output chr() 34' );
is( $lh->maketext('X [output,chr,38] Y'), "X & Y",  'output chr() 38' );
is( $lh->maketext('X [output,chr,39] Y'), "X ' Y",  'output chr() 39' );
is( $lh->maketext('X [output,chr,60] Y'), "X < Y",  'output chr() 60' );
is( $lh->maketext('X [output,chr,62] Y'), "X > Y",  'output chr() 62' );
is( $lh->maketext('X [output,chr,42] Y'), "X * Y",  'output chr() non-spec' );

is( $lh->maketext('X [output,abbr,Abbr.,Abbreviation] Y'),          "X Abbr. (Abbreviation) Y",       'output abbr()' );
is( $lh->maketext('X [output,acronym,TLA,Three Letter Acronym] Y'), "X TLA (Three Letter Acronym) Y", 'output acronym()' );
is( $lh->maketext( 'X [output,img,SRC,ALT _1 ALT] Y', 'ARG1' ), 'X ALT ARG1 ALT Y', 'output img()' );

SKIP: {
    eval 'use Encode ();';
    skip "Could not load Encode.pm", 1 if $@;
    is( $lh->maketext('X [output,chr,173] Y'), 'X ' . Encode::encode_utf8( chr(173) ) . ' Y', 'output chr() 173 (soft-hyphen)' );
}

is( $lh->maketext( 'X [output,class,_1,daring] Y',      "jibby" ), "X \e[1mjibby\e[0m Y", 'class' );
is( $lh->maketext( 'X [output,class,_1,bold,daring] Y', "jibby" ), "X \e[1mjibby\e[0m Y", 'multi class' );

# embedded tests
is(
    $lh->maketext( 'You must [output,url,_1,html,click on _2,plain,go _2 to] to complete your registration.', 'URL', 'IMG' ),
    'You must go IMG to URL to complete your registration.',
    'embedded args in output,url’s “html” and “plain” values'
);

# TODO: "# arbitrary attribute key/value args" tests in non-HTML context

$lh->{'-t-STDIN'} = 0;
is( $lh->maketext('x [output,underline,y] z'), 'x <span style="text-decoration: underline">y</span> z', 'output underline html' );
is( $lh->maketext('x [output,strong,y] z'),    'x <strong>y</strong> z',                                'output strong html' );
is( $lh->maketext('x [output,em,y] z'),        'x <em>y</em> z',                                        'output em html' );

is( $lh->maketext( 'Please [output,url,_1,plain,visit,html,click here].', 'URL HERE' ), 'Please <a href="URL HERE">click here</a>.', 'HTML url' );
is( $lh->maketext( 'Please [output,url,_1,plain,visit,html,click here,_type,offsite].', 'URL HERE' ), 'Please <a target="_blank" class="offsite" href="URL HERE">click here</a>.', 'HTML url, _type => offsite' );

is( $lh->maketext( 'My favorite site is [output,url,_1,_type,offsite].', 'http://search.cpan.org' ), 'My favorite site is <a target="_blank" class="offsite" href="http://search.cpan.org">http://search.cpan.org</a>.', 'HTML no value uses URL' );

is( $lh->maketext('X [output,chr,34] Y'),  "X &quot; Y", 'output chr() 34' );
is( $lh->maketext('X [output,chr,38] Y'),  "X &amp; Y",  'output chr() 38' );
is( $lh->maketext('X [output,chr,39] Y'),  "X &#39; Y",  'output chr() 39' );
is( $lh->maketext('X [output,chr,60] Y'),  "X &lt; Y",   'output chr() 60' );
is( $lh->maketext('X [output,chr,62] Y'),  "X &gt; Y",   'output chr() 62' );
is( $lh->maketext('X [output,chr,42] Y'),  "X * Y",      'output chr() non-spec' );
is( $lh->maketext('X [output,chr,173] Y'), 'X &shy; Y',  'output chr() 173 (soft-hyphen)' );

is( $lh->maketext( 'X [output,class,_1,daring] Y',      "jibby" ), "X <span class=\"daring\">jibby</span> Y",      'class' );
is( $lh->maketext( 'X [output,class,_1,bold,daring] Y', "jibby" ), "X <span class=\"bold daring\">jibby</span> Y", 'multi class' );

# embedded tests
is(
    $lh->maketext( 'You must [output,url,_1,html,click on _2,plain,go _2 to] to complete your registration.', 'URL', 'IMG' ),
    'You must <a href="URL">click on IMG</a> to complete your registration.',
    'embedded args in output,url’s “html” and “plain” values'
);
is(
    $lh->maketext('Y [output,strong,Hellosub(Z)Qsup(Y)Qchr(42)Qnumf(1)] Z'),
    'Y <strong>Hello<sub>Z</sub>Q<sup>Y</sup>Q*Q1</strong> Z',
    'Embedded methods: sub(), sup(), chr(), and numf()'
);

# arbitrary attribute key/value args

is( $lh->maketext('[output,fragment,Foo Bar]'),         '<span>Foo Bar</span>',           'output fragment() standard' );
is( $lh->maketext('[output,fragment,Foo Bar,baz,wop]'), '<span baz="wop">Foo Bar</span>', 'ouput fragment() w/ arbitrary attributes' );
is( $lh->maketext( '[output,fragment,Foo Bar,baz,wop,_1]', { a => 1 } ), '<span baz="wop" a="1">Foo Bar</span>', 'ouput fragment() w/ arbitrary attributes + hashref' );
is( $lh->maketext( '[output,fragment,Foo Bar,_1]',         { a => 1 } ), '<span a="1">Foo Bar</span>',           'ouput fragment() w/ hashref' );

is( $lh->maketext('[output,attr,Foo Bar]'),         '<span>Foo Bar</span>',           'output attr() standard' );
is( $lh->maketext('[output,attr,Foo Bar,baz,wop]'), '<span baz="wop">Foo Bar</span>', 'ouput attr() w/ arbitrary attributes' );
is( $lh->maketext( '[output,attr,Foo Bar,baz,wop,_1]', { a => 1 } ), '<span baz="wop" a="1">Foo Bar</span>', 'ouput attr() w/ arbitrary attributes + hashref' );
is( $lh->maketext( '[output,attr,Foo Bar,_1]',         { a => 1 } ), '<span a="1">Foo Bar</span>',           'ouput attr() w/ hashref' );

is( $lh->maketext('[output,segment,Foo Bar]'),         '<div>Foo Bar</div>',           'output segment() standard' );
is( $lh->maketext('[output,segment,Foo Bar,baz,wop]'), '<div baz="wop">Foo Bar</div>', 'ouput segment() w/ arbitrary attributes' );
is( $lh->maketext( '[output,segment,Foo Bar,baz,wop,_1]', { a => 1 } ), '<div baz="wop" a="1">Foo Bar</div>', 'ouput segment() w/ arbitrary attributes + hashref' );
is( $lh->maketext( '[output,segment,Foo Bar,_1]',         { a => 1 } ), '<div a="1">Foo Bar</div>',           'ouput fragment() w/ hashref' );

is( $lh->maketext('[output,sup,Foo Bar]'),         '<sup>Foo Bar</sup>',           'output sup() standard' );
is( $lh->maketext('[output,sup,Foo Bar,baz,wop]'), '<sup baz="wop">Foo Bar</sup>', 'ouput sup() w/ arbitrary attributes' );
is( $lh->maketext( '[output,sup,Foo Bar,baz,wop,_1]', { a => 1 } ), '<sup baz="wop" a="1">Foo Bar</sup>', 'ouput sup() w/ arbitrary attributes + hashref' );
is( $lh->maketext( '[output,sup,Foo Bar,_1]',         { a => 1 } ), '<sup a="1">Foo Bar</sup>',           'ouput sup() w/ hashref' );

is( $lh->maketext('[output,sub,Foo Bar]'),         '<sub>Foo Bar</sub>',           'output sub() standard' );
is( $lh->maketext('[output,sub,Foo Bar,baz,wop]'), '<sub baz="wop">Foo Bar</sub>', 'ouput sub() w/ arbitrary attributes' );
is( $lh->maketext( '[output,sub,Foo Bar,baz,wop,_1]', { a => 1 } ), '<sub baz="wop" a="1">Foo Bar</sub>', 'ouput sub() w/ arbitrary attributes + hashref' );
is( $lh->maketext( '[output,sub,Foo Bar,_1]',         { a => 1 } ), '<sub a="1">Foo Bar</sub>',           'ouput sub() w/ hashref' );

is( $lh->maketext('[output,strong,Foo Bar]'),         '<strong>Foo Bar</strong>',           'output strong() standard' );
is( $lh->maketext('[output,strong,Foo Bar,baz,wop]'), '<strong baz="wop">Foo Bar</strong>', 'ouput strong() w/ arbitrary attributes' );
is( $lh->maketext( '[output,strong,Foo Bar,baz,wop,_1]', { a => 1 } ), '<strong baz="wop" a="1">Foo Bar</strong>', 'ouput strong() w/ arbitrary attributes + hashref' );
is( $lh->maketext( '[output,strong,Foo Bar,_1]',         { a => 1 } ), '<strong a="1">Foo Bar</strong>',           'ouput strong() w/ hashref' );

is( $lh->maketext('[output,em,Foo Bar]'),         '<em>Foo Bar</em>',           'output em() standard' );
is( $lh->maketext('[output,em,Foo Bar,baz,wop]'), '<em baz="wop">Foo Bar</em>', 'ouput em() w/ arbitrary attributes' );
is( $lh->maketext( '[output,em,Foo Bar,baz,wop,_1]', { a => 1 } ), '<em baz="wop" a="1">Foo Bar</em>', 'ouput em() w/ arbitrary attributes + hashref' );
is( $lh->maketext( '[output,em,Foo Bar,_1]',         { a => 1 } ), '<em a="1">Foo Bar</em>',           'ouput em() w/ hashref' );

is( $lh->maketext('[output,abbr,FoBa.,Foo Bar]'),         '<abbr title="Foo Bar">FoBa.</abbr>',           'output abbr() standard' );
is( $lh->maketext('[output,abbr,FoBa.,Foo Bar,baz,wop]'), '<abbr title="Foo Bar" baz="wop">FoBa.</abbr>', 'ouput abbr() w/ arbitrary attributes' );
is( $lh->maketext( '[output,abbr,FoBa.,Foo Bar,baz,wop,_1]', { a => 1 } ), '<abbr title="Foo Bar" baz="wop" a="1">FoBa.</abbr>', 'ouput abbr() w/ arbitrary attributes + hashref' );
is( $lh->maketext('[output,abbr,FoBa.,Foo Bar,baz,wop,title,wrong]'), '<abbr title="Foo Bar" baz="wop">FoBa.</abbr>', 'ouput abbr() w/ arbitrary attributes - title ignored' );
is( $lh->maketext( '[output,abbr,FoBa.,Foo Bar,baz,wop,_1]', { a => 1, title => 'wrong' } ), '<abbr title="Foo Bar" baz="wop" a="1">FoBa.</abbr>', 'ouput abbr() w/ arbitrary attributes + hashref - title ignored' );
is( $lh->maketext( '[output,abbr,FoBa.,Foo Bar,_1]', { a => 1 } ), '<abbr title="Foo Bar" a="1">FoBa.</abbr>', 'ouput abbr() w/ hashref' );

is( $lh->maketext('[output,acronym,FB,Foo Bar]'),         '<acronym title="Foo Bar">FB</acronym>',           'output acronym() standard' );
is( $lh->maketext('[output,acronym,FB,Foo Bar,baz,wop]'), '<acronym title="Foo Bar" baz="wop">FB</acronym>', 'ouput acronym() w/ arbitrary attributes' );
is( $lh->maketext( '[output,acronym,FB,Foo Bar,baz,wop,_1]', { a => 1 } ), '<acronym title="Foo Bar" baz="wop" a="1">FB</acronym>', 'ouput acronym() w/ arbitrary attributes + hashref' );
is( $lh->maketext('[output,acronym,FB,Foo Bar,baz,wop,title,wrong]'), '<acronym title="Foo Bar" baz="wop">FB</acronym>', 'ouput acronym() w/ arbitrary attributes - title ignored' );
is( $lh->maketext( '[output,acronym,FB,Foo Bar,baz,wop,_1]', { a => 1, title => 'wrong' } ), '<acronym title="Foo Bar" baz="wop" a="1">FB</acronym>', 'ouput acronym() w/ arbitrary attributes + hashref - title ignored' );
is( $lh->maketext( '[output,acronym,FB,Foo Bar,_1]', { a => 1 } ), '<acronym title="Foo Bar" a="1">FB</acronym>', 'ouput acronym() w/ hashref' );

is( $lh->maketext('[output,underline,Foo Bar]'),         '<span style="text-decoration: underline">Foo Bar</span>',           'output fragment() standard' );
is( $lh->maketext('[output,underline,Foo Bar,baz,wop]'), '<span style="text-decoration: underline" baz="wop">Foo Bar</span>', 'ouput underline() w/ arbitrary attributes' );
is( $lh->maketext( '[output,underline,Foo Bar,baz,wop,_1]', { a => 1 } ), '<span style="text-decoration: underline" baz="wop" a="1">Foo Bar</span>', 'ouput underline() w/ arbitrary attributes + hashref' );
is( $lh->maketext( '[output,fragment,Foo Bar,_1]', { a => 1 } ), '<span a="1">Foo Bar</span>', 'ouput fragment() w/ hashref' );

is( $lh->maketext('[output,img,SRC]'),             '<img src="SRC" alt="SRC"/>',           'output img() - no alt' );
is( $lh->maketext('[output,img,SRC,_1]'),          '<img src="SRC" alt="SRC"/>',           'output img() - ALT arg missing i.e. undef()' );
is( $lh->maketext('[output,img,SRC,]'),            '<img src="SRC" alt="SRC"/>',           'output img() - ALT empty string' );
is( $lh->maketext('[output,img,SRC,ALT]'),         '<img src="SRC" alt="ALT"/>',           'output img() - w/ ALT' );
is( $lh->maketext('[output,img,SRC,ALT,baz,wop]'), '<img src="SRC" alt="ALT" baz="wop"/>', 'output img() - w/ arbitrary attributes' );
is( $lh->maketext( '[output,img,SRC,ALT,baz,wop,_1]', { a => 1 } ), '<img src="SRC" alt="ALT" baz="wop" a="1"/>', 'output img() - w/ arbitrary attributes + hashref' );
is( $lh->maketext('[output,img,SRC,ALT,baz,wop,src,wrong,alt,wrong]'), '<img src="SRC" alt="ALT" baz="wop"/>', 'output img() - w/ arbitrary attributes - alt, src ignored' );
is( $lh->maketext( '[output,img,SRC,ALT,baz,wop,_1]', { a => 1, src => 'wrong', alt => 'wrong' } ), '<img src="SRC" alt="ALT" baz="wop" a="1"/>', 'output img() - w/ arbitrary attributes + hash - alt, src ignored' );
is( $lh->maketext( '[output,img,SRC,ALT,_1]', { a => 1 } ), '<img src="SRC" alt="ALT" a="1"/>', 'output img() w/ hashref' );
