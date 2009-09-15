use Test::More tests => 32;

BEGIN { 
    chdir 't';
    unshift @INC, qw(lib ../lib);
    use_ok('Locale::Maketext::Utils');
    use_ok('MyTestLocale');
};

my $lh = MyTestLocale->get_handle('en');

$lh->{'-t-STDIN'} = 1;
ok($lh->maketext('x [output,underline,y] z') eq "x \e[4my\e[0m z", 'output underline text');
ok($lh->maketext('x [output,strong,y] z') eq "x \e[1my\e[0m z", 'output strong text');
ok($lh->maketext('x [output,em,y] z') eq "x \e[3my\e[0m z", 'output em text');

ok($lh->maketext('Please [output,url,_1,plain,execute,html,click here].','CMD HERE') eq 'Please execute CMD HERE.', 'plain url append (cmd context)');
ok($lh->maketext('Please [output,url,_1,plain,visit,html,click here].','URL HERE') eq 'Please visit URL HERE.', 'plain url append (url context)');
ok($lh->maketext(q{Please [output,url,_1,plain,execute '%s' when you can,html,click here].},'CMD HERE') eq q{Please execute 'CMD HERE' when you can.}, 'plain url with placeholder');
ok($lh->maketext(q{Please [output,url,_1,plain,go to '%s' (again that is '%s') when you can,html,click here].},'URL HERE') eq q{Please go to 'URL HERE' (again that is 'URL HERE') when you can.}, 'plain url with multiple placeholders');

ok($lh->maketext('My favorite site is [output,url,_1,_type,offsite].','http://search.cpan.org') eq 'My favorite site is http://search.cpan.org.', 'plain no value uses URL');

ok($lh->maketext('X [output,chr,34] Y') eq "X \" Y", 'output chr() 34');
ok($lh->maketext('X [output,chr,38] Y') eq "X & Y", 'output chr() 38');
ok($lh->maketext('X [output,chr,39] Y') eq "X ' Y", 'output chr() 39');
ok($lh->maketext('X [output,chr,60] Y') eq "X < Y", 'output chr() 60');
ok($lh->maketext('X [output,chr,62] Y') eq "X > Y", 'output chr() 62');
ok($lh->maketext('X [output,chr,42] Y') eq "X * Y", 'output chr() non-spec');

ok($lh->maketext('X [output,class,_1,daring] Y',"jibby") eq "X \e[1mjibby\e[0m Y", 'class');
ok($lh->maketext('X [output,class,_1,bold,daring] Y',"jibby") eq "X \e[1mjibby\e[0m Y", 'multi class');

$lh->{'-t-STDIN'} = 0;
ok($lh->maketext('x [output,underline,y] z') eq 'x <span style="text-decoration: underline">y</span> z', 'output underline html');
ok($lh->maketext('x [output,strong,y] z') eq 'x <strong>y</strong> z', 'output strong html');
ok($lh->maketext('x [output,em,y] z') eq 'x <em>y</em> z', 'output em html');

ok($lh->maketext('Please [output,url,_1,plain,visit,html,click here].','URL HERE') eq 'Please <a href="URL HERE">click here</a>.', 'HTML url');
ok($lh->maketext('Please [output,url,_1,plain,visit,html,click here,_type,offsite].','URL HERE') eq 'Please <a target="_blank" class="offsite" href="URL HERE">click here</a>.', 'HTML url, _type => offsite');

ok($lh->maketext('My favorite site is [output,url,_1,_type,offsite].','http://search.cpan.org') eq 'My favorite site is <a target="_blank" class="offsite" href="http://search.cpan.org">http://search.cpan.org</a>.', 'HTML no value uses URL'); 

ok($lh->maketext('X [output,chr,34] Y') eq "X &quot; Y", 'output chr() 34');
ok($lh->maketext('X [output,chr,38] Y') eq "X &amp; Y", 'output chr() 38');
ok($lh->maketext('X [output,chr,39] Y') eq "X &#39; Y", 'output chr() 39');
ok($lh->maketext('X [output,chr,60] Y') eq "X &lt; Y", 'output chr() 60');
ok($lh->maketext('X [output,chr,62] Y') eq "X &gt; Y", 'output chr() 62');
ok($lh->maketext('X [output,chr,42] Y') eq "X * Y", 'output chr() non-spec');

ok($lh->maketext('X [output,class,_1,daring] Y',"jibby") eq "X <span class=\"daring\">jibby</span> Y", 'class');
ok($lh->maketext('X [output,class,_1,bold,daring] Y',"jibby") eq "X <span class=\"bold daring\">jibby</span> Y", 'multi class');
