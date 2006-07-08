use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Locale::Maketext::Utils',
    VERSION_FROM      => 'lib/Locale/Maketext/Utils.pm', 
    PREREQ_PM         => {
        'Locale::Maketext'  => 0,
        'version'           => 0,
        'File::Slurp'       => 0,
        'Locales::Language' => 0,
    },
    ($] >= 5.005 ?   
      (ABSTRACT_FROM  => 'lib/Locale/Maketext/Utils.pm', 
       AUTHOR         => 'Daniel Muey, L<http://drmuey.com/cpan_contact.pl>') : ()),
);
