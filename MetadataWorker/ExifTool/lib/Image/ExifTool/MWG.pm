#------------------------------------------------------------------------------
# File:         MWG.pm
#
# Description:  Metadata Working Group support
#
# Revisions:    2009/10/21 - P. Harvey Created
#
# References:   1) http://www.metadataworkinggroup.org/
#------------------------------------------------------------------------------

package Image::ExifTool::MWG;

use strict;
use vars qw($VERSION);
use Image::ExifTool qw(:DataAccess :Utils);
use Image::ExifTool::Exif;

$VERSION = '1.02';

# enable MWG strict mode by default
# (causes non-standard EXIF, IPTC and XMP to be ignored)
$Image::ExifTool::MWG::strict = 1 unless defined $Image::ExifTool::MWG::strict;

sub RecoverTruncatedIPTC($$$);

# MWG Composite tags
%Image::ExifTool::MWG::Composite = (
    GROUPS => { 0 => 'Composite', 1 => 'MWG', 2 => 'Image' },
    VARS => { NO_ID => 1 },
    NOTES => q{
        This table lists special Composite tags which are used to access other tags
        based on the Metadata Working Group 1.01 recommendations.  These tags are
        only accessible when the MWG module is loaded (via C<-use MWG> on the
        command line, or C<use Image::ExifTool::MWG> in the API).  When reading, the
        value of each MWG tag is B<Derived From> the specified tags based on the MWG
        guidelines.  When writing, the value of the IPTCDigest tag is updated
        automatically when the IPTC is changed if either the IPTCDigest tag didn't
        exist beforehand or its value agreed with the original IPTC digest
        (indicating that the XMP is synchronized with the IPTC).  IPTC information
        is written only if the original file contained IPTC.  For more information
        about the MWG recommendation, see L<http://www.metadataworkinggroup.org/>.

        Loading the MWG module activates "strict MWG conformance mode", which has
        the effect of causing EXIF, IPTC and XMP in non-standard locations to be
        ignored when reading, as per the MWG recommendations.  Instead, a "Warning"
        tag is generated when non-standard metadata is encountered.  This feature
        may be disabled by setting C<$Image::ExifTool::MWG::strict = 0> in the
        ExifTool config file (or from your Perl script when using the API).  Note
        that the behaviour when writing is not changed:  ExifTool always creates new
        records only in the standard location, but writes new tags to any
        EXIF/IPTC/XMP records that exist.

        A problem with the MWG specification is that although XMP:Creator and
        IPTC:By-line are list-type tags, the corresponding EXIF tag, EXIF:Artist, is
        not.  So, short of changing the EXIF specification to allow EXIF:Artist to
        store a list of strings, the only reasonable alternative is to NOT allow
        MWG:Creator to be written as a list.  (It is insufficient to say that
        EXIF:Artist may store multiple strings separated with semicolons because
        there is nothing in any of the MWG, EXIF, XMP or IPTC specifications that
        states an individual Creator string may not contain a semicolon, and for
        this to be feasible all of these specifications would require this
        restriction.)  For this reason, the MWG:Creator tag is written as a single
        string.  Multiple names may of course be written within the string (and it
        would be reasonable to separate them with semicolons as suggested by the MWG
        and EXIF specifications), but this tag is not treated as a list by ExifTool
        when writing.
    },
    Keywords => {
        Flags  => ['Writable','List'],
        Desire => {
            0 => 'IPTC:Keywords', # (64-character limit)
            1 => 'XMP-dc:Subject',
            2 => 'CurrentIPTCDigest',
            3 => 'IPTCDigest',
        },
        ValueConv => q{
            return $val[1] if not defined $val[2] or (defined $val[1] and
                             (not defined $val[3] or $val[2] eq $val[3]));
            return Image::ExifTool::MWG::RecoverTruncatedIPTC($val[0], $val[1], 64);
        },
        DelCheck   => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteCheck => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteAlso  => {
            # only write Keywords if IPTC exists (ie. set EditGroup option)
            'IPTC:Keywords'  => '$opts{EditGroup} = 1; $val',
            'XMP-dc:Subject' => '$val',
        },
    },
    Description => {
        Writable => 1,
        Desire => {
            0 => 'EXIF:ImageDescription',
            1 => 'IPTC:Caption-Abstract', # (2000-character limit)
            2 => 'XMP-dc:Description',
            3 => 'CurrentIPTCDigest',
            4 => 'IPTCDigest',
        },
        ValueConv => q{
            return $val[0] if defined $val[0];
            return $val[2] if not defined $val[3] or (defined $val[2] and
                             (not defined $val[4] or $val[3] eq $val[4]));
            return Image::ExifTool::MWG::RecoverTruncatedIPTC($val[1], $val[2], 2000);
        },
        DelCheck   => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteCheck => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteAlso  => {
            'EXIF:ImageDescription' => '$val',
            'IPTC:Caption-Abstract' => '$opts{EditGroup} = 1; $val',
            'XMP-dc:Description'    => '$val',
        },
    },
    DateTimeOriginal => {
        Description => 'Date/Time Original',
        Groups => { 2 => 'Time' },
        Notes => '"creation date of the intellectual content being shown" - MWG',
        Writable => 1,
        Desire => {
            0 => 'EXIF:DateTimeOriginal',
            1 => 'EXIF:SubSecTimeOriginal',
            2 => 'IPTC:DateCreated',
            3 => 'IPTC:TimeCreated',
            4 => 'XMP-photoshop:DateCreated',
            5 => 'CurrentIPTCDigest',
            6 => 'IPTCDigest',
        },
        ValueConv => q{
            return $val[1] ? "$val[0].$val[1]" : $val[0] if defined $val[0];
            return $val[4] if not defined $val[5] or (defined $val[4] and
                             (not defined $val[6] or $val[5] eq $val[6]));
            return $val[3] ? "$val[2] $val[3]" : $val[2] if $val[2];
            return undef;
        },
        PrintConv => '$self->ConvertDateTime($val)',
        PrintConvInv => '$self->InverseDateTime($val,undef,1)',
        DelCheck   => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteCheck => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteAlso  => {
            # set EXIF date/time values according to PrintConv option instead
            # of defaulting to Type=ValueConv to allow reformatting to be applied
            'EXIF:DateTimeOriginal'     => 'delete $opts{Type}; $val',
            'EXIF:SubSecTimeOriginal'   => 'delete $opts{Type}; $val',
            'IPTC:DateCreated'          => '$opts{EditGroup} = 1; $val',
            'IPTC:TimeCreated'          => '$opts{EditGroup} = 1; $val',
            'XMP-photoshop:DateCreated' => '$val',
        },
    },
    CreateDate => {
        Groups => { 2 => 'Time' },
        Notes => '"creation date of the digital representation" - MWG',
        Writable => 1,
        Desire => {
            0 => 'EXIF:CreateDate',
            1 => 'EXIF:SubSecTimeDigitized',
            2 => 'IPTC:DigitalCreationDate',
            3 => 'IPTC:DigitalCreationTime',
            4 => 'XMP-xmp:CreateDate',
            5 => 'CurrentIPTCDigest',
            6 => 'IPTCDigest',
        },
        ValueConv => q{
            return $val[1] ? "$val[0].$val[1]" : $val[0] if defined $val[0];
            return $val[4] if not defined $val[5] or (defined $val[4] and
                             (not defined $val[6] or $val[5] eq $val[6]));
            return $val[3] ? "$val[2] $val[3]" : $val[2] if $val[2];
            return undef;
        },
        PrintConv => '$self->ConvertDateTime($val)',
        PrintConvInv => '$self->InverseDateTime($val,undef,1)',
        DelCheck   => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteCheck => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteAlso  => {
            'EXIF:CreateDate'          => 'delete $opts{Type}; $val',
            'EXIF:SubSecTimeDigitized' => 'delete $opts{Type}; $val',
            'IPTC:DigitalCreationDate' => '$opts{EditGroup} = 1; $val',
            'IPTC:DigitalCreationTime' => '$opts{EditGroup} = 1; $val',
            'XMP-xmp:CreateDate'       => '$val',
        },
    },
    ModifyDate => {
        Groups => { 2 => 'Time' },
        Notes => '"modification date of the digital image file" - MWG',
        Writable => 1,
        Desire => {
            0 => 'EXIF:ModifyDate',
            1 => 'EXIF:SubSecTime',
            2 => 'XMP-xmp:ModifyDate',
            3 => 'CurrentIPTCDigest',
            4 => 'IPTCDigest',
        },
        ValueConv => q{
            return $val[1] ? "$val[0].$val[1]" : $val[0] if defined $val[0];
            return $val[2] if not defined $val[3] or not defined $val[4] or $val[3] eq $val[4];
            return undef;
        },
        PrintConv => '$self->ConvertDateTime($val)',
        PrintConvInv => '$self->InverseDateTime($val,undef,1)',
        # return empty string from check routines so this tag will never be set
        # (only WriteAlso tags are written), the only difference is a -v2 message
        DelCheck   => '""',
        WriteCheck => '""',
        WriteAlso  => {
            'EXIF:ModifyDate'    => 'delete $opts{Type}; $val',
            'EXIF:SubSecTime'    => 'delete $opts{Type}; $val',
            'XMP-xmp:ModifyDate' => '$val',
        },
    },
    Orientation => {
        Writable   => 1,
        Require    => 'EXIF:Orientation',
        ValueConv  => '$val',
        PrintConv  => \%Image::ExifTool::Exif::orientation,
        DelCheck   => '""',
        WriteCheck => '""',
        WriteAlso  => {
            'EXIF:Orientation' => '$val',
        },
    },
    Rating => {
        Writable   => 1,
        Require    => 'XMP-xmp:Rating',
        ValueConv  => '$val',
        DelCheck   => '""',
        WriteCheck => '""',
        WriteAlso  => {
            'XMP-xmp:Rating' => '$val',
        },
    },
    Copyright => {
        Groups => { 2 => 'Author' },
        Writable => 1,
        Desire => {
            0 => 'EXIF:Copyright',
            1 => 'IPTC:CopyrightNotice', # (128-character limit)
            2 => 'XMP-dc:Rights',
            3 => 'CurrentIPTCDigest',
            4 => 'IPTCDigest',
        },
        ValueConv => q{
            return $val[0] if defined $val[0];
            return $val[2] if not defined $val[3] or (defined $val[2] and
                             (not defined $val[4] or $val[3] eq $val[4]));
            return Image::ExifTool::MWG::RecoverTruncatedIPTC($val[1], $val[2], 128);
        },
        DelCheck   => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteCheck => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteAlso  => {
            'EXIF:Copyright'       => '$val',
            'IPTC:CopyrightNotice' => '$opts{EditGroup} = 1; $val',
            'XMP-dc:Rights'        => '$val',
        },
    },
    Creator => {
        Groups => { 2 => 'Author' },
        Writable => 1,
        Desire => {
            0 => 'EXIF:Artist',
            1 => 'IPTC:By-line', # (32-character limit)
            2 => 'XMP-dc:Creator',
            3 => 'CurrentIPTCDigest',
            4 => 'IPTCDigest',
        },
        Notes => 'NOT a list-type tag.  See "A problem with the MWG specification" above',
        ValueConv => q{
            return $val[0] if defined $val[0];
            return $val[2] if not defined $val[3] or (defined $val[2] and
                             (not defined $val[4] or $val[3] eq $val[4]));
            return Image::ExifTool::MWG::RecoverTruncatedIPTC($val[1], $val[2], 32);
        },
        DelCheck   => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteCheck => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteAlso  => {
            'EXIF:Artist'    => '$val',
            'IPTC:By-line'   => '$opts{Replace} = 1; $opts{EditGroup} = 1; $val',
            'XMP-dc:Creator' => '$opts{Replace} = 1; $val',
        },
    },
    Country => {
        Groups => { 2 => 'Location' },
        Writable => 1,
        Desire => {
            0 => 'IPTC:Country-PrimaryLocationName', # (64-character limit)
            1 => 'XMP-photoshop:Country',
            2 => 'CurrentIPTCDigest',
            3 => 'IPTCDigest',
        },
        ValueConv => q{
            return $val[1] if not defined $val[2] or (defined $val[1] and
                             (not defined $val[3] or $val[2] eq $val[3]));
            return Image::ExifTool::MWG::RecoverTruncatedIPTC($val[0], $val[1], 64);
        },
        DelCheck   => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteCheck => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteAlso  => {
            'IPTC:Country-PrimaryLocationName' => '$opts{EditGroup} = 1; $val',
            'XMP-photoshop:Country'            => '$val',
        },
    },
    State => {
        Groups => { 2 => 'Location' },
        Writable => 1,
        Desire => {
            0 => 'IPTC:Province-State', # (32-character limit)
            1 => 'XMP-photoshop:State',
            2 => 'CurrentIPTCDigest',
            3 => 'IPTCDigest',
        },
        ValueConv => q{
            return $val[1] if not defined $val[2] or (defined $val[1] and
                             (not defined $val[3] or $val[2] eq $val[3]));
            return Image::ExifTool::MWG::RecoverTruncatedIPTC($val[0], $val[1], 32);
        },
        DelCheck   => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteCheck => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteAlso  => {
            'IPTC:Province-State' => '$opts{EditGroup} = 1; $val',
            'XMP-photoshop:State' => '$val',
        },
    },
    City => {
        Groups => { 2 => 'Location' },
        Writable => 1,
        Desire => {
            0 => 'IPTC:City', # (32-character limit)
            1 => 'XMP-photoshop:City',
            2 => 'CurrentIPTCDigest',
            3 => 'IPTCDigest',
        },
        ValueConv => q{
            return $val[1] if not defined $val[2] or (defined $val[1] and
                             (not defined $val[3] or $val[2] eq $val[3]));
            return Image::ExifTool::MWG::RecoverTruncatedIPTC($val[0], $val[1], 32);
        },
        DelCheck   => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteCheck => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteAlso  => {
            'IPTC:City'          => '$opts{EditGroup} = 1; $val',
            'XMP-photoshop:City' => '$val',
        },
    },
    Location => {
        Groups => { 2 => 'Location' },
        Writable => 1,
        Desire => {
            0 => 'IPTC:Sub-location', # (32-character limit)
            1 => 'XMP-iptcCore:Location',
            2 => 'CurrentIPTCDigest',
            3 => 'IPTCDigest',
        },
        ValueConv => q{
            return $val[1] if not defined $val[2] or (defined $val[1] and
                             (not defined $val[3] or $val[2] eq $val[3]));
            return Image::ExifTool::MWG::RecoverTruncatedIPTC($val[0], $val[1], 32);
        },
        DelCheck   => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteCheck => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteAlso  => {
            'IPTC:Sub-location'     => '$opts{EditGroup} = 1; $val',
            'XMP-iptcCore:Location' => '$val',
        },
    },
);

unless ($Image::ExifTool::documentOnly) {
    # add our composite tags
    Image::ExifTool::AddCompositeTags('Image::ExifTool::MWG');
    # must also add to lookup so we can write them
    # (since MWG tags aren't in the tag lookup by default)
    Image::ExifTool::AddTagsToLookup(\%Image::ExifTool::MWG::Composite,
                                     'Image::ExifTool::Composite');
}


#------------------------------------------------------------------------------
# Reconcile IPTC digest after writing an MWG tag
# Inputs: 0) ExifTool object ref
# Returns: empty string
sub ReconcileIPTCDigest($)
{
    my $exifTool = shift;

    # set new value for IPTCDigest if not done already
    unless ($Image::ExifTool::Photoshop::iptcDigestInfo and
            $exifTool->{NEW_VALUE}{$Image::ExifTool::Photoshop::iptcDigestInfo})
    {
        # write new IPTCDigest only if it doesn't exist or
        # is the same as the digest of the original IPTC
        my @a; # (capture warning messages)
        @a = $exifTool->SetNewValue('Photoshop:IPTCDigest', 'old', Protected => 1, DelValue => 1);
        @a = $exifTool->SetNewValue('Photoshop:IPTCDigest', 'new', Protected => 1);
    }
    return '';
}

#------------------------------------------------------------------------------
# Recover strings which were truncated by IPTC dataset length limit
# Inputs: 0) IPTC value, 1) XMP value, 2) length limit
# Notes: handles the case where IPTC and/or XMP values are lists
sub RecoverTruncatedIPTC($$$)
{
    my ($iptc, $xmp, $limit) = @_;

    return $iptc unless defined $xmp;
    if (ref $iptc) {
        $xmp = [ $xmp ] unless ref $xmp;
        my ($i, @vals);
        for ($i=0; $i<@$iptc; ++$i) {
            push @vals, RecoverTruncatedIPTC($$iptc[$i], $$xmp[$i], $limit);
        }
        return \@vals;
    } elsif (defined $iptc and length $iptc == $limit) {    
        $xmp = $$xmp[0] if ref $xmp;    # take first element of list
        return $xmp if length $xmp > $limit and $iptc eq substr($xmp, 0, $limit);
    }
    return $iptc;
}

1;  # end

__END__

=head1 NAME

Image::ExifTool::MWG - Metadata Working Group support

=head1 SYNOPSIS

    # enable MWG tags (strict mode enabled by default)
    use Image::ExifTool::MWG;

    # disable MWG strict mode
    $Image::ExifTool::MWG::strict = 0;

=head1 DESCRIPTION

The MWG module contains tag definitions which are designed to simplify
implementation of the Metadata Working Group guidelines.  These special MWG
composite tags are enabled simply by loading this module:

    use Image::ExifTool::MWG;

When the MWG module is loaded, "strict MWG conformance" is enabled by
default.  In this mode, ExifTool will generate a Warning tag instead of
extracting EXIF, IPTC and XMP from non-standard locations.  The strict mode
may be disabled by setting the MWG "strict" flag to zero (either before or
after loading the MWG module):

    $Image::ExifTool::MWG::strict = 0;

=head1 AUTHOR

Copyright 2003-2010, Phil Harvey (phil at owl.phy.queensu.ca)

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 REFERENCES

=over 4

=item L<http://www.metadataworkinggroup.org/>

=back

=head1 SEE ALSO

L<Image::ExifTool::TagNames/MWG Tags>,
L<Image::ExifTool(3pm)|Image::ExifTool>

=cut
