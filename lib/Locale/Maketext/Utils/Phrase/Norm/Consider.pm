package Locale::Maketext::Utils::Phrase::Norm::Consider;

use strict;
use warnings;

sub normalize_maketext_string {
    my ($filter) = @_;

    my $string_sr = $filter->get_string_sr();

    my $closing_bn = qr/(?<!\~)\]/;
    my $opening_bn = qr/(?<!\~)\[/;

    my $bn_var = qr/\_(?:\-?[0-9]+|\*)/;    # should we add (?<!\~) ?

    # entires phrase is bracket notation
    if ( ${$string_sr} =~ m/^\[(.*)\]$/ ) {
        my $contents = $1;
        if ( $contents !~ m/$closing_bn/ && $contents !~ m/$opening_bn/ ) {
            ${$string_sr} .= "[comment,does this phrase really need to be entirely bracket notation?]";
            $filter->add_warning('Entire phrase is bracket notation, is there a better way in this case?');
        }
    }

    my $idx = 0;
    my @bn;
    while ( ${$string_sr} =~ m/\[.*?\]/pg ) {    # TODO: make this regex/logic smarter since it will not work with ~[ but why would we do that right :) - may need to wait for phrase-as-class obj
        push @bn, [ ${^PREMATCH}, ${^MATCH}, ${^POSTMATCH}, $idx++ ];
    }
    my $has_bare    = 0;
    my $has_hardurl = 0;
    for my $bn_ar (@bn) {
        my ( $before, $bn, $after, $array_index ) = @{$bn_ar};

        # bare variable:
        #   Simple: [_1]
        #   TODO: Complex: [output,strong,_1] (but not [numf,_1] or [output,url,_1…]), - may need to wait for phrase-as-class obj
        if ( $bn =~ m/^\[($bn_var)\]$/ ) {       # TODO: && “Complex” capture here

            # unless the bare bracket notation  …
            unless (
                ( $array_index == $#bn && $before =~ m/\:(?:\x20|\xc2\xa0)/ && ( !defined $after || $after eq '' ) )    # … is a trailing '…: [_2]'
                or
                ( $before !~ m/(?:\x20|\xc2\xa0)$/ && $after !~ m/^(?:\x20|\xc2\xa0)/ )                                 # … is surrounded by non-whitespace already
                or
                ( $before =~ m/,(?:\x20|\xc2\xa0)$/ && $after =~ m/^,/ )                                                # … is in a comma reference
              ) {
                ${$string_sr} =~ s/(\Q$bn\E)/“$1”/;
                $has_bare++;
            }
        }

        # Do not hardcode URL in [output,url]:
        if ( $bn =~ m/^\[output,url,(.*)(,|)\]$/ ) {
            my $url = $1;
            if ( $url !~ m/^($bn_var)$/ ) {
                ${$string_sr} =~ s/(\Q$bn\E)/\[output,url,why harcode “$url”\]/;
                $has_hardurl++;
            }
        }
    }
    $filter->add_warning('Hard coded URLs can be a maintenance nightmare, why not pass the URL in so the phrase does not change if the URL does') if $has_hardurl;
    $filter->add_warning('Bare variable can lead to ambiguous output')                                                                            if $has_bare;

    return $filter->return_value;
}

1;

__END__

=encoding utf-8

=head1 Normalization

The checks in here are for various best practices to consider while crafting phrases.

=head2 Rationale

These are warnings only and are meant to help point out things that typically are best done differently but could possibly be legit and thus a human needs to consider and sort it out.

=head1 possible violations

None

=head1 possible warnings

=over 4

=item Entire phrase is bracket notation, is there a better way in this case?

This will append '[comment,does this phrase really need to be entirely bracket notation?]' to the phrase.

The idea behind it is that a phrase that is entirely bracket notation is a sure sign that it needs done differently.

For example:

=over 4 

=item method

    $lh->maketext('[numf,_1]',$n);

There is no need to translate that, it’d be the same in every locale!

You would simply do this:

    $lh->numf($n)

=item overly complex

    $lh->maketext('[boolean,_1,Your foo has been installed.,Your foo has been uninstalled.]',$is_install);

Unnecessarily difficult to read/work with and without benefit. You can't use any other bracket notation. You can probably spot other issues too.

Depending on the situation you might do either of these:

    if ($is_install) {
        $lh->maketext('Your foo has been installed.');
    }
    else {
        $lh->maketext('Your foo has been uninstalled.');
    }

or if you prefer to keep the variant–pair as one unit:

    $lh->maketext('Your foo has been [boolean,_1,installed,uninstalled].',$is_install);

=back

=item Hard coded URLs can be a maintenance nightmare, why not pass the URL in so the phrase does not change if the URL does

     $lh->maketext('You can [output,url,http://support.example.com,visit our support page] for further assistance.');
     
What happens when support.example.com changes to custcare.example.com? You have to change, not only the caller but the lexicons and translations, ick!

Then after you do that your boss says, oh wait actually it needs to be customer.example.com …

But if you had passed it in as an argument:

     $lh->maketext('You can [output,url,_1,visit our support page] for further assistance.', $url_db{'support_url'});

Now when support.example.com changes to custcare.example.com you update 'support_url' in %url_db–done.

He wants it to be customer.example.com, no problem update 'support_url' in %url_db–done.

=item Bare variable can lead to ambiguous output

    $lh->maketext('The checksum was [_1].', $sum);

If $sum is empty or undef you get odd spacing (e.g. “was .” instead of “was.”), could lose info, (e.g. “wait, the checksum is what now?”), or change meaning completely (e.g. what if the checksum was the string “BAD”).

    'The checksum was .'
    'The checksum was BAD.'

That applies even if it is decorated some way:

    'The checksum was <code></code>.'
    'The checksum was <code>BAD</code>.'

It promotes evil partial phrases (i.e. that are untranslatable whish is sort of the opposite of localizing things no?)

    $lh->maketext('The checksum was [_1].', $lh->maketext('inserted into the database)); # !!!! DON’T DO THIS !!!!

One way to visually distinguish what you intend regardless of the value given is simply to quote it:

   The checksum was “[_1]”.

becomes:

   The checksum was “”.                    # It is obvious that the sum is empty
   The checksum was “BAD”.                 # It is obvious that it is a string made up of B, A, and D and not a statement that the sum has a problem
   The checksum was “perfectly awesome”.   # It looks weird so someone probably will notice and ask you to fix your code

Depending on what you’re doing other things might work too:

=over 4

=item Trailing introductory “:”:

   An error has occured: [_2]

=item Alternate text:

   Sorry, [is_defined,_2,“_2” is an invalid,you must specify a valid] value for “[_1]”.

=item Parentheses:

   The domain ([_1]) could not be found.

=item Comma reference:

   The user, [_1], already exists.

=item Etc etc

=back

=back
