#------------------------------------------------------------------------------
# File:         SigmaRaw.pm
#
# Description:  Read Sigma/Foveon RAW (X3F) meta information
#
# Revisions:    2005/10/16 - P. Harvey Created
#               2009/11/30 - P. Harvey Support X3F v2.3 written by Sigma DP2
#
# References:   1) http://www.x3f.info/technotes/FileDocs/X3F_Format.pdf
#------------------------------------------------------------------------------

package Image::ExifTool::SigmaRaw;

use strict;
use vars qw($VERSION);
use Image::ExifTool qw(:DataAccess :Utils);

$VERSION = '1.08';

sub ProcessX3FHeader($$$);
sub ProcessX3FDirectory($$$);
sub ProcessX3FProperties($$$);

# main X3F sections (plus header stuff)
%Image::ExifTool::SigmaRaw::Main = (
    PROCESS_PROC => \&ProcessX3FDirectory,
    NOTES => 'These tags are used in Sigma and Foveon RAW (.X3F) images.',
    Header => {
        SubDirectory => { TagTable => 'Image::ExifTool::SigmaRaw::Header' },
    },
    HeaderExt => {
        SubDirectory => { TagTable => 'Image::ExifTool::SigmaRaw::HeaderExt' },
    },
    PROP => {
        Name => 'Properties',
        SubDirectory => { TagTable => 'Image::ExifTool::SigmaRaw::Properties' },
    },
    IMAG => {
        Name => 'PreviewImage',
        Binary => 1,
    },
    IMA2 => [
        {
            Name => 'PreviewImage',
            Condition => 'not $$self{IsJpgFromRaw}',
            Binary => 1,
        },
        {
            Name => 'JpgFromRaw',
            Binary => 1,
        },
    ]
);

# common X3F header structure
%Image::ExifTool::SigmaRaw::Header = (
    PROCESS_PROC => \&ProcessX3FHeader,
    FORMAT => 'int32u',
    1 => {
        Name => 'FileVersion',
        ValueConv => '($val >> 16) . "." . ($val & 0xffff)',
    },
    2 => {
        Name => 'ImageUniqueID',
        # the serial number (with an extra leading "0") makes up
        # the first 8 digits of this UID,
        Format => 'undef[16]',
        ValueConv => 'unpack("H*", $val)',
    },
    6 => {
        Name => 'MarkBits',
        PrintConv => { BITMASK => { } },
    },
    7 => {
        Name => 'ImageWidth',
        # save this for testing preview image sizes later
        RawConv => '$$self{ImageWidth} = $val',
    },
    8 => 'ImageHeight',
    9 => 'Rotation',
    10 => {
        Name => 'WhiteBalance',
        Format => 'string[32]',
    },
    18 => { #PH (DP2, FileVersion 2.3)
        Name => 'SceneCaptureType',
        Format => 'string[32]',
    },
);

# extended header tags
%Image::ExifTool::SigmaRaw::HeaderExt = (
    GROUPS => { 2 => 'Camera' },
    NOTES => 'Extended header data found in version 2.1 and 2.2 files',
    0 => 'Unused',
    1 => { Name => 'ExposureAdjust',PrintConv => 'sprintf("%.2f",$val)' },
    2 => { Name => 'Contrast',      PrintConv => 'sprintf("%.2f",$val)' },
    3 => { Name => 'Shadow',        PrintConv => 'sprintf("%.2f",$val)' },
    4 => { Name => 'Highlight',     PrintConv => 'sprintf("%.2f",$val)' },
    5 => { Name => 'Saturation',    PrintConv => 'sprintf("%.2f",$val)' },
    6 => { Name => 'Sharpness',     PrintConv => 'sprintf("%.2f",$val)' },
    7 => { Name => 'RedAdjust',     PrintConv => 'sprintf("%.2f",$val)' },
    8 => { Name => 'GreenAdjust',   PrintConv => 'sprintf("%.2f",$val)' },
    9 => { Name => 'BlueAdjust',    PrintConv => 'sprintf("%.2f",$val)' },
   10 => { Name => 'X3FillLight',   PrintConv => 'sprintf("%.2f",$val)' },
);

# PROP tags
%Image::ExifTool::SigmaRaw::Properties = (
    PROCESS_PROC => \&ProcessX3FProperties,
    GROUPS => { 2 => 'Camera' },
    AEMODE => {
        Name => 'MeteringMode',
        PrintConv => {
            8 => '8-segment',
            C => 'Center-weighted average',
            A => 'Average',
        },
    },
    AFAREA      => 'AFArea', # observed: CENTER_V
    AFINFOCUS   => 'AFInFocus', # observed: H
    AFMODE      => 'FocusMode',
    AP_DESC     => 'ApertureDisplayed',
    APERTURE => {
        Name => 'FNumber',
        Groups => { 2 => 'Image' },
        PrintConv => 'sprintf("%.1f",$val)',
    },
    BRACKET     => 'BracketShot',
    BURST       => 'BurstShot',
    CAMMANUF    => 'Make',
    CAMMODEL    => 'Model',
    CAMNAME     => 'CameraName',
    CAMSERIAL   => 'SerialNumber',
    CM_DESC     => 'SceneCaptureType', #PH (DP2)
    COLORSPACE  => 'ColorSpace', # observed: sRGB
    DRIVE => {
        Name => 'DriveMode',
        PrintConv => {
            SINGLE => 'Single Shot',
            MULTI  => 'Multi Shot',
            '2S'   => '2 s Timer',
            '10S'  => '10 s Timer',
            UP     => 'Mirror Up',
            AB     => 'Auto Bracket',
            OFF    => 'Off',
        },
    },
    EVAL_STATE  => 'EvalState', # observed: POST-EXPOSURE
    EXPCOMP => {
        Name => 'ExposureCompensation',
        Groups => { 2 => 'Image' },
        PrintConv => 'Image::ExifTool::Exif::ConvertFraction($val)',
    },
    EXPNET => {
        Name => 'NetExposureCompensation',
        Groups => { 2 => 'Image' },
        PrintConv => 'Image::ExifTool::Exif::ConvertFraction($val)',
    },
    EXPTIME => {
        Name => 'IntegrationTime',
        Groups => { 2 => 'Image' },
        ValueConv => '$val * 1e-6', # convert from usec
        PrintConv => 'Image::ExifTool::Exif::PrintExposureTime($val)',
    },
    FIRMVERS    => 'FirmwareVersion',
    FLASH => {
        Name => 'FlashMode',
        PrintConv => 'ucfirst(lc($val))',
    },
    FLASHEXPCOMP=> 'FlashExpComp',
    FLASHPOWER  => 'FlashPower',
    FLASHTTLMODE=> 'FlashTTLMode', # observed: ON
    FLASHTYPE   => 'FlashType', # observed: NONE
    FLENGTH => {
        Name => 'FocalLength',
        PrintConv => 'sprintf("%.1f mm",$val)',
    },
    FLEQ35MM    => 'FocalLengthIn35mmFormat',
    FOCUS => {
        Name => 'Focus',
        PrintConv => {
            AF => 'Auto-focus Locked',
           'NO LOCK' => "Auto-focus Didn't Lock",
            M => 'Manual',
        },
    },
    IMAGERBOARDID => 'ImagerBoardID',
    IMAGERTEMP  => 'SensorTemperature',
    IMAGEBOARDID=> 'ImageBoardID', #PH (DP2)
    ISO         => 'ISO',
    LENSARANGE  => 'LensApertureRange',
    LENSFRANGE  => 'LensFocalRange',
    LENSMODEL   => {
        Name => 'LensType',
        Notes => q{
            decimal values differentiate lenses which would otherwise have the same
            LensType, and are used by the Composite LensID tag when attempting to
            identify the specific lens model
        },
        PrintConv => { #PH
            # 0 => 'Sigma 50mm F2.8 EX Macro', (0 used for other lenses too)
            # 8 - 18-125mm LENSARANGE@18mm=22-4
            16 => 'Sigma 18-50mm F3.5-5.6 DC',
            129 => 'Sigma 14mm F2.8 EX Aspherical',
            131 => 'Sigma 17-70mm F2.8-4.5 DC Macro',
            145 => 'Sigma Lens (145)',
            145.1 => 'Sigma 15-30mm F3.5-4.5 EX DG Aspherical',
            145.2 => 'Sigma 18-50mm F2.8 EX DG', #(NC)
            145.3 => 'Sigma 20-40mm F2.8 EX DG',
            165 => 'Sigma 70-200mm F2.8 EX', # ...but what specific model?:
            # 70-200mm F2.8 EX APO - Original version, minimum focus distance 1.8m (1999)
            # 70-200mm F2.8 EX DG - Adds 'digitally optimized' lens coatings to reduce flare (2005)
            # 70-200mm F2.8 EX DG Macro (HSM) - Minimum focus distance reduced to 1m (2006)
            # 70-200mm F2.8 EX DG Macro HSM II - Improved optical performance (2007)
            169 => 'Sigma 18-50mm F2.8 EX DC', #(NC)
        },
    },
    PMODE => {
        Name => 'ExposureProgram',
        PrintConv => {
            P => 'Program',
            A => 'Aperture Priority',
            S => 'Shutter Priority',
            M => 'Manual',
        },
    },
    RESOLUTION => {
        Name => 'Quality',
        PrintConv => {
            LOW => 'Low',
            MED => 'Medium',
            HI  => 'High',
        },
    },
    SENSORID    => 'SensorID',
    SH_DESC     => 'ShutterSpeedDisplayed',
    SHUTTER => {
        Name => 'ExposureTime',
        Groups => { 2 => 'Image' },
        PrintConv => 'Image::ExifTool::Exif::PrintExposureTime($val)',
    },
    TIME => {
        Name => 'DateTimeOriginal',
        Groups => { 2 => 'Time' },
        Description => 'Date/Time Original',
        ValueConv => 'ConvertUnixTime($val)',
        PrintConv => '$self->ConvertDateTime($val)',
    },
    WB_DESC     => 'WhiteBalance',
    VERSION_BF  => 'VersionBF',
);

#------------------------------------------------------------------------------
# Extract null-terminated unicode string from list of characters
# Inputs: 0) ExifTool object ref, 1) list ref, 2) position in list
# Returns: Converted string
sub ExtractUnicodeString($$$)
{
    my ($exifTool, $chars, $pos) = @_;
    my $i;
    for ($i=$pos; $i<@$chars; ++$i) {
        last unless $$chars[$i];
    }
    my $buff = pack('v*', @$chars[$pos..$i-1]);
    return $exifTool->Decode($buff, 'UCS2', 'II');
}

#------------------------------------------------------------------------------
# Process an X3F header
# Inputs: 0) ExifTool object reference, 1) DirInfo reference, 2) tag table ref
# Returns: 1 on success
sub ProcessX3FHeader($$$)
{
    my ($exifTool, $dirInfo, $tagTablePtr) = @_;
    my $dataPt = $$dirInfo{DataPt};
    my $hdrLen = $$dirInfo{DirLen};
    my $verbose = $exifTool->Options('Verbose');

    # process the static header structure first
    $exifTool->ProcessBinaryData($dirInfo, $tagTablePtr);

    # process extended data if available
    if (length $$dataPt >= 232) {
        if ($verbose) {
            $exifTool->VerboseDir('X3F HeaderExt', 32);
            Image::ExifTool::HexDump($dataPt, undef,
                MaxLen => $verbose > 3 ? 1024 : 96,
                Out    => $exifTool->Options('TextOut'),
                Prefix => $$exifTool{INDENT},
                Start  => $$dirInfo{DirLen},
            ) if $verbose > 2;
        }
        $tagTablePtr = GetTagTable('Image::ExifTool::SigmaRaw::HeaderExt');
        my @vals = unpack("x${hdrLen}C32V32", $$dataPt);
        my $i;
        my $unused = 0;
        for ($i=0; $i<32; ++$i) {
            $vals[$i] or ++$unused, next;
            my $val = $vals[$i+32];
            # convert value 0x40000000 => 2 ** 1, 0x3f800000 => 2 ** 0, 0x3f000000 => 2 ** -1
            if ($val) {
                my $sign;
                if ($val & 0x80000000) {
                    $sign = -1;
                    $val &= 0x7fffffff;
                } else {
                    $sign = 1;
                }
                $val = $sign * 2 ** (($val - 0x3f800000) / 0x800000);
            }
            $exifTool->HandleTag($tagTablePtr, $vals[$i], $val,
                Index  => $i,
                DataPt => $dataPt,
                Start  => $hdrLen + 32 + $i * 4,
                Size   => 4,
            );
        }
        $exifTool->VPrint(0, "$exifTool->{INDENT}($unused entries unused)\n");
    }
    return 1;
}

#------------------------------------------------------------------------------
# Process an X3F properties
# Inputs: 0) ExifTool object reference, 1) DirInfo reference, 2) tag table ref
# Returns: 1 on success
sub ProcessX3FProperties($$$)
{
    my ($exifTool, $dirInfo, $tagTablePtr) = @_;
    my $dataPt = $$dirInfo{DataPt};
    my $size = length($$dataPt);
    my $verbose = $exifTool->Options('Verbose');
    my $unknown = $exifTool->Options('Unknown');

    unless ($size >= 24 and $$dataPt =~ /^SECp/) {
        $exifTool->Warn('Bad properties header');
        return 0;
    }
    my ($entries, $fmt, $len) = unpack('x8V2x4V', $$dataPt);
    unless ($size >= 24 + 8 * $entries + $len) {
        $exifTool->Warn('Truncated Property directory');
        return 0;
    }
    $verbose and $exifTool->VerboseDir('Properties', $entries);
    $fmt == 0 or $exifTool->Warn("Unsupported character format $fmt"), return 0;
    my $charPos = 24 + 8 * $entries;
    my @chars = unpack('v*',substr($$dataPt, $charPos, $len * 2));
    my $index;
    for ($index=0; $index<$entries; ++$index) {
        my ($namePos, $valPos) = unpack('V2',substr($$dataPt, $index*8 + 24, 8));
        if ($namePos >= @chars or $valPos >= @chars) {
            $exifTool->Warn('Bad Property pointer');
            return 0;
        }
        my $tag = ExtractUnicodeString($exifTool, \@chars, $namePos);
        my $val = ExtractUnicodeString($exifTool, \@chars, $valPos);
        if (not $$tagTablePtr{$tag} and $unknown and $tag =~ /^\w+$/) {
            my $tagInfo = {
                Name => "SigmaRaw_$tag",
                Description => Image::ExifTool::MakeDescription('SigmaRaw', $tag),
                Unknown => 1,
                Writable => 0,  # can't write unknown tags
            };
            # add tag information to table
            Image::ExifTool::AddTagToTable($tagTablePtr, $tag, $tagInfo);
        }

        $exifTool->HandleTag($tagTablePtr, $tag, $val,
            Index => $index,
            DataPt => $dataPt,
            Start => $charPos + 2 * $valPos,
            Size => 2 * (length($val) + 1),
        );
    }
    return 1;
}

#------------------------------------------------------------------------------
# Process an X3F directory
# Inputs: 0) ExifTool object reference, 1) DirInfo reference, 2) tag table ref
# Returns: error string or undef on success
sub ProcessX3FDirectory($$$)
{
    my ($exifTool, $dirInfo, $tagTablePtr) = @_;
    my $raf = $$dirInfo{RAF};
    my $verbose = $exifTool->Options('Verbose');

    $raf->Seek($$dirInfo{DirStart}, 0) or return 'Error seeking to directory start';

    # parse the X3F directory structure
    my ($buff, $ver, $entries, $index);
    $raf->Read($buff, 12) == 12 or return 'Truncated X3F image';
    $buff =~ /^SECd/ or return 'Bad section header';
    ($ver, $entries) = unpack('x4V2', $buff);
    $verbose and $exifTool->VerboseDir('X3F Subsection', $entries);
    my $dir;
    $raf->Read($dir, $entries * 12) == $entries * 12 or return 'Truncated X3F directory';
    for ($index=0; $index<$entries; ++$index) {
        my $pos = $index * 12;
        my ($offset, $len, $tag) = unpack("x${pos}V2a4", $dir);
        my $tagInfo = $exifTool->GetTagInfo($tagTablePtr, $tag);
        if ($verbose) {
            $exifTool->VPrint(0, "$exifTool->{INDENT}$index) $tag Subsection ($len bytes):\n");
            if ($verbose > 2) {
                $raf->Seek($offset, 0) or return 'Error seeking';
                $raf->Read($buff, $len) == $len or return 'Truncated image';
                $exifTool->VerboseDump(\$buff);
            }
        }
        next unless $tagInfo;
        $raf->Seek($offset, 0) or return "Error seeking for $$tagInfo{Name}";
        if  ($$tagInfo{Name} eq 'PreviewImage') {
            # check image header to see if this is a JPEG preview image
            $raf->Read($buff, 28) == 28 or return 'Error reading PreviewImage header';
            # igore all image data but JPEG compressed (type 18)
            next unless $buff =~ /^SECi.{4}\x02\0\0\0\x12/s;
            # check preview image size and extract full-sized preview as JpgFromRaw
            my $imageWidth = $$exifTool{ImageWidth};
            if ($imageWidth) {
                my ($w, $h) = unpack('x16V2', $buff);
                # not sure if width/height values change for rotated images, so test both
                if ($imageWidth == $w or $imageWidth == $h) {
                    $$exifTool{IsJpgFromRaw} = 1;
                    $tagInfo = $exifTool->GetTagInfo($tagTablePtr, $tag);
                    delete $$exifTool{IsJpgFromRaw};
                }
            }
            $len -= 28;
        }
        $raf->Read($buff, $len) == $len or return "Error reading $$tagInfo{Name} data";
        my $subdir = $$tagInfo{SubDirectory};
        if ($subdir) {
            my %dirInfo = ( DataPt => \$buff );
            my $subTable = GetTagTable($$subdir{TagTable});
            $exifTool->ProcessDirectory(\%dirInfo, $subTable);
        } else {
            $exifTool->FoundTag($tagInfo, $buff);
        }
    }
    return undef;
}

#------------------------------------------------------------------------------
# Extract information from a Sigma raw (X3F) image
# Inputs: 0) ExifTool object reference, 1) DirInfo reference
# Returns: 1 on success, 0 if this wasn't a valid X3F image
sub ProcessX3F($$)
{
    my ($exifTool, $dirInfo) = @_;
    my $raf = $$dirInfo{RAF};
    my $buff;

    return 0 unless $raf->Read($buff, 40) == 40;
    return 0 unless $buff =~ /^FOVb/;

    SetByteOrder('II');
    $exifTool->SetFileType();

    # check version number
    my $ver = unpack('x4V',$buff);
    $ver = ($ver >> 16) . '.' . ($ver & 0xffff);
    if ($ver >= 3) {
        $exifTool->Warn("Can't read version $ver X3F image");
        return 1;
    } elsif ($ver > 2.3) {
        $exifTool->Warn('Untested X3F version. Please submit sample for testing', 1);
    }
    my $hdrLen = length $buff;
    # read version 2.1/2.2 extended header
    if ($ver > 2) {
        my $buf2;
        unless ($raf->Read($buf2, 192) == 192) {
            $exifTool->Warn('Error reading extended header');
            return 1;
        }
        $buff .= $buf2;
        $hdrLen += $ver > 2.2 ? 64 : 32;   # SceneCaptureType string added in 2.3
    }
    # process header information
    my $tagTablePtr = GetTagTable('Image::ExifTool::SigmaRaw::Main');
    $exifTool->HandleTag($tagTablePtr, 'Header', $buff,
        DataPt => \$buff,
        Size   => $hdrLen,
    );
    # read the directory pointer
    $raf->Seek(-4, 2);
    unless ($raf->Read($buff, 4) == 4) {
        $exifTool->Warn('Error reading X3F dir pointer');
        return 1;
    }
    my $offset = unpack('V', $buff);
    my %dirInfo = (
        RAF => $raf,
        DirStart => $offset,
    );
    # process the X3F subsections
    my $err = $exifTool->ProcessDirectory(\%dirInfo, $tagTablePtr);
    $err and $exifTool->Warn($err);
    return 1;
}

1;  # end

__END__

=head1 NAME

Image::ExifTool::SigmaRaw - Read Sigma/Foveon RAW (X3F) meta information

=head1 SYNOPSIS

This module is loaded automatically by Image::ExifTool when required.

=head1 DESCRIPTION

This module contains definitions required by Image::ExifTool to read
Sigma and Foveon X3F images.

=head1 AUTHOR

Copyright 2003-2010, Phil Harvey (phil at owl.phy.queensu.ca)

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 REFERENCES

=over 4

=item L<http://www.x3f.info/technotes/FileDocs/X3F_Format.pdf>

=back

=head1 SEE ALSO

L<Image::ExifTool::TagNames/SigmaRaw Tags>,
L<Image::ExifTool::Sigma(3pm)|Image::ExifTool::Sigma>,
L<Image::ExifTool(3pm)|Image::ExifTool>

=cut
