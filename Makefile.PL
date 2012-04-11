use ExtUtils::MakeMaker;

# Note to self: cp 07.phrase_norm.t 08.cpanel_norm.t, s/Norm.om/cPanel.pm/, s/::Norm/::cPanel/ except the one in run_32_tests()

WriteMakefile(
    NAME              => 'Locale::Maketext::Utils',
    VERSION_FROM      => 'lib/Locale/Maketext/Utils.pm', 
    PREREQ_PM         => {
        'Locale::Maketext'  => 1.22,
        'Locales'           => 0.26,
        'DateTime'          => 0,
        'Net::LibIDN'       => 0,
        'IO::Interactive::Tiny' => 0,
        'Module::Want' => 0,
        'Encode' => 0,
        'Test::More' => 0,
        'Test::Carp' => 0,
    },
    ($] >= 5.005 ?   
      (ABSTRACT_FROM  => 'lib/Locale/Maketext/Utils.pod', 
       AUTHOR         => 'Daniel Muey, L<http://drmuey.com/cpan_contact.pl>') : ()),
);
