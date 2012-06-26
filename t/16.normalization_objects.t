use Test::More tests => 18;

use Locale::Maketext::Utils::Phrase::Norm;
use Locale::Maketext::Utils::Phrase::cPanel;

$INC{"Locale/Maketext/Utils/Phrase/Norm/TEST.pm"} = 1;
*Locale::Maketext::Utils::Phrase::Norm::TEST::normalize_maketext_string = sub { };

for my $type ( 0 .. 2 ) {

    # diag explain(Locale::Maketext::Utils::Phrase::Norm->new($type == 1 ? 'TEST' : ())->{'filternames'});

    my $label = $type == 1 ? ': additional added' : $type == 2 ? ': excluded not added' : '';
    {
        my $label = $type == 2 ? '' : $label;
        is_deeply(

            Locale::Maketext::Utils::Phrase::Norm->new( $type == 1 ? 'TEST' : () )->{'filternames'},
            [
                'Locale::Maketext::Utils::Phrase::Norm::NonBytesStr',
                'Locale::Maketext::Utils::Phrase::Norm::WhiteSpace',
                'Locale::Maketext::Utils::Phrase::Norm::Grapheme',
                'Locale::Maketext::Utils::Phrase::Norm::Ampersand',
                'Locale::Maketext::Utils::Phrase::Norm::Markup',
                'Locale::Maketext::Utils::Phrase::Norm::Ellipsis',
                'Locale::Maketext::Utils::Phrase::Norm::BeginUpper',
                'Locale::Maketext::Utils::Phrase::Norm::EndPunc',
                'Locale::Maketext::Utils::Phrase::Norm::Consider',
                'Locale::Maketext::Utils::Phrase::Norm::Escapes',
                'Locale::Maketext::Utils::Phrase::Norm::Compiles',
                (
                    $type == 1
                    ? 'Locale::Maketext::Utils::Phrase::Norm::TEST'
                    : ()
                )
            ],
            "Norm->new() filters" . $label
        );

        is_deeply(
            Locale::Maketext::Utils::Phrase::cPanel->new( $type == 1 ? 'TEST' : () )->{'filternames'},
            [
                'Locale::Maketext::Utils::Phrase::Norm::NonBytesStr',
                'Locale::Maketext::Utils::Phrase::Norm::WhiteSpace',
                'Locale::Maketext::Utils::Phrase::Norm::Grapheme',
                'Locale::Maketext::Utils::Phrase::Norm::Ampersand',
                'Locale::Maketext::Utils::Phrase::Norm::Markup',
                'Locale::Maketext::Utils::Phrase::Norm::Ellipsis',
                'Locale::Maketext::Utils::Phrase::Norm::BeginUpper',
                'Locale::Maketext::Utils::Phrase::Norm::EndPunc',
                'Locale::Maketext::Utils::Phrase::Norm::Consider',
                'Locale::Maketext::Utils::Phrase::Norm::Escapes',
                'Locale::Maketext::Utils::Phrase::Norm::Compiles',
                (
                    $type == 1
                    ? 'Locale::Maketext::Utils::Phrase::Norm::TEST'
                    : ()
                )
            ],
            "cPanel->new() filters" . $label
        );
    }

    is_deeply(
        Locale::Maketext::Utils::Phrase::Norm->new_translation( $type == 1 ? 'TEST' : $type == 2 ? 'BeginUpper' : () )->{'filternames'},
        [
            'Locale::Maketext::Utils::Phrase::Norm::NonBytesStr',
            'Locale::Maketext::Utils::Phrase::Norm::WhiteSpace',
            'Locale::Maketext::Utils::Phrase::Norm::Grapheme',
            'Locale::Maketext::Utils::Phrase::Norm::Ampersand',
            'Locale::Maketext::Utils::Phrase::Norm::Markup',
            'Locale::Maketext::Utils::Phrase::Norm::Ellipsis',
            'Locale::Maketext::Utils::Phrase::Norm::Consider',
            'Locale::Maketext::Utils::Phrase::Norm::Escapes',
            'Locale::Maketext::Utils::Phrase::Norm::Compiles',
            (
                $type == 1
                ? 'Locale::Maketext::Utils::Phrase::Norm::TEST'
                : ()
            )
        ],
        "Norm->new_translation() filters" . $label
    );

    is_deeply(
        Locale::Maketext::Utils::Phrase::cPanel->new_translation( $type == 1 ? 'TEST' : $type == 2 ? 'BeginUpper' : () )->{'filternames'},
        [
            'Locale::Maketext::Utils::Phrase::Norm::NonBytesStr',
            'Locale::Maketext::Utils::Phrase::Norm::WhiteSpace',
            'Locale::Maketext::Utils::Phrase::Norm::Grapheme',
            'Locale::Maketext::Utils::Phrase::Norm::Ampersand',
            'Locale::Maketext::Utils::Phrase::Norm::Markup',
            'Locale::Maketext::Utils::Phrase::Norm::Ellipsis',
            'Locale::Maketext::Utils::Phrase::Norm::Consider',
            'Locale::Maketext::Utils::Phrase::Norm::Escapes',
            'Locale::Maketext::Utils::Phrase::Norm::Compiles',
            (
                $type == 1
                ? 'Locale::Maketext::Utils::Phrase::Norm::TEST'
                : ()
            )
        ],
        "cPanel->new_translation() filters" . $label
    );

    is_deeply(
        Locale::Maketext::Utils::Phrase::cPanel->new_legacy( $type == 1 ? 'TEST' : $type == 2 ? 'Markup' : () )->{'filternames'},
        [
            'Locale::Maketext::Utils::Phrase::Norm::NonBytesStr',
            'Locale::Maketext::Utils::Phrase::Norm::WhiteSpace',
            'Locale::Maketext::Utils::Phrase::Norm::Grapheme',
            'Locale::Maketext::Utils::Phrase::Norm::Ellipsis',
            'Locale::Maketext::Utils::Phrase::Norm::BeginUpper',
            'Locale::Maketext::Utils::Phrase::Norm::EndPunc',
            'Locale::Maketext::Utils::Phrase::Norm::Consider',
            'Locale::Maketext::Utils::Phrase::Norm::Escapes',
            'Locale::Maketext::Utils::Phrase::Norm::Compiles',
            (
                $type == 1
                ? 'Locale::Maketext::Utils::Phrase::Norm::TEST'
                : ()
            )
        ],
        "cPanel->new_legacy() filters" . $label
    );

    is_deeply(
        Locale::Maketext::Utils::Phrase::cPanel->new_translation_legacy( $type == 1 ? 'TEST' : $type == 2 ? 'Markup' : () )->{'filternames'},
        [
            'Locale::Maketext::Utils::Phrase::Norm::NonBytesStr',
            'Locale::Maketext::Utils::Phrase::Norm::WhiteSpace',
            'Locale::Maketext::Utils::Phrase::Norm::Grapheme',
            'Locale::Maketext::Utils::Phrase::Norm::Ellipsis',
            'Locale::Maketext::Utils::Phrase::Norm::Consider',
            'Locale::Maketext::Utils::Phrase::Norm::Escapes',
            'Locale::Maketext::Utils::Phrase::Norm::Compiles',
            (
                $type == 1
                ? 'Locale::Maketext::Utils::Phrase::Norm::TEST'
                : ()
            )
        ],
        "cPanel->new_translation_legacy() filters" . $label
    );
}
