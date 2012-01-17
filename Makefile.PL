use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Locale::Maketext::Utils',
    VERSION_FROM      => 'lib/Locale/Maketext/Utils.pm', 
    PREREQ_PM         => {
        'Locale::Maketext'  => 1.21,
        'Locales'           => 0.25,
        'DateTime'          => 0,
        'Net::LibIDN'       => 0,
        'IO::Interactive::Tiny' => 0,
    },
    ($] >= 5.005 ?   
      (ABSTRACT_FROM  => 'lib/Locale/Maketext/Utils.pod', 
       AUTHOR         => 'Daniel Muey, L<http://drmuey.com/cpan_contact.pl>') : ()),
);
