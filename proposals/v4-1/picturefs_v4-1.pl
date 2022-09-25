#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

#------------------------------------------------------------------------------
# File:         example.config
#
# Description:  Example user configuration file for Image::ExifTool
#
# Notes:        This example file shows how to define your own shortcuts and
#               add new EXIF, IPTC, XMP, PNG, MIE and Composite tags, as well
#               as how to specify preferred lenses for the LensID tag, and
#               define new file types and default ExifTool option values.
#
#               Note that unknown tags may be extracted even if they aren't
#               defined, but tags must be defined to be written.  Also note
#               that it is possible to override an existing tag definition
#               with a user-defined tag.
#
#               To activate this file, rename it to ".ExifTool_config" and
#               place it in your home directory or the exiftool application
#               directory.  (On Mac and some Windows systems this must be done
#               via the command line since the GUI's may not allow filenames to
#               begin with a dot.  Use the "rename" command in Windows or "mv"
#               on the Mac.)  This causes ExifTool to automatically load the
#               file when run.  Your home directory is determined by the first
#               defined of the following environment variables:
#
#                   1.  EXIFTOOL_HOME
#                   2.  HOME
#                   3.  HOMEDRIVE + HOMEPATH
#                   4.  (the current directory)
#
#               Alternatively, the -config option of the exiftool application
#               may be used to load a specific configuration file (note that
#               this must be the first option on the command line):
#
#                   exiftool -config example.config ...
#
#               This example file defines the following 16 new tags as well as
#               a number of Shortcut and Composite tags:
#
#                   1.  EXIF:NewEXIFTag
#                   2.  GPS:GPSPitch
#                   3.  GPS:GPSRoll
#                   4.  IPTC:NewIPTCTag
#                   5.  XMP-xmp:NewXMPxmpTag
#                   6.  XMP-exif:GPSPitch
#                   7.  XMP-exif:GPSRoll
#                   8.  XMP-xxx:NewXMPxxxTag1
#                   9.  XMP-xxx:NewXMPxxxTag2
#                  10.  XMP-xxx:NewXMPxxxTag3
#                  11.  XMP-xxx:NewXMPxxxStruct
#                  12.  PNG:NewPngTag1
#                  13.  PNG:NewPngTag2
#                  14.  PNG:NewPngTag3
#                  15.  MIE-Meta:NewMieTag1
#                  16.  MIE-Test:NewMieTag2
#
#               For detailed information on the definition of tag tables and
#               tag information hashes, see lib/Image/ExifTool/README.
#------------------------------------------------------------------------------

# Shortcut tags are used when extracting information to simplify
# commonly used commands.  They can be used to represent groups
# of tags, or to provide an alias for a tag name.
%Image::ExifTool::UserDefined::Shortcuts = (
    MyShortcut => ['exif:createdate','exposuretime','aperture'],
    MyAlias => 'FocalLengthIn35mmFormat',
);

# NOTE: All tag names used in the following tables are case sensitive.

# The %Image::ExifTool::UserDefined hash defines new tags to be added
# to existing tables.
%Image::ExifTool::UserDefined = (
    'Image::ExifTool::Composite' => {
        # Composite tags have values that are derived from the values of
        # other tags.  The Require/Desire elements below specify constituent
        # tags that must/may exist, and the keys of these hashes are used as
        # indices in the @val array of the ValueConv expression to access the
        # numerical (-n) values of these tags.  Print-converted values are
        # accessed via the @prt array.  All Require'd tags must exist for
        # the Composite tag to be evaluated.  If no Require'd tags are
        # specified, then at least one of the Desire'd tags must exist.  See
        # the Composite table in Image::ExifTool::Exif for more examples,
        # and lib/Image/ExifTool/README for all of the details.
        BaseName            => {
            Require   => {
                0 => 'FileName',
            },
            # remove the extension from FileName
            ValueConv => '$val[0] =~ /(.*)\./ ? $1 : $val[0]',
        },
        # the next few examples demonstrate simplifications which may be
        # used if only one tag is Require'd or Desire'd:
        # 1) the Require lookup may be replaced with a simple tag name
        # 2) "$val" may be used to represent "$val[0]" in the expression
        FileExtension       => {
            Require   => 'FileName',
            ValueConv => '$val=~/\.([^.]*)$/; $1',
        },
        # override CircleOfConfusion tag to use D/1750 instead of D/1440
        CircleOfConfusion   => {
            Require   => 'ScaleFactor35efl',
            Groups    => { 2 => 'Camera' },
            ValueConv => 'sqrt(24*24+36*36) / ($val * 1750)',
            # an optional PrintConv may be used to format the value
            PrintConv => 'sprintf("%.3f mm",$val)',
        },
        # generate a description for this file type
        FileTypeDescription => {
            Require   => 'FileType',
            ValueConv => 'GetFileType($val,1) || $val',
        },
        # calculate physical image size based on resolution
        PhysicalImageSize   => {
            Require   => {
                0 => 'ImageWidth',
                1 => 'ImageHeight',
                2 => 'XResolution',
                3 => 'YResolution',
                4 => 'ResolutionUnit',
            },
            ValueConv => '$val[0]/$val[2] . " " . $val[1]/$val[3]',
            # (the @prt array contains print-formatted values)
            PrintConv => 'sprintf("%.1fx%.1f $prt[4]", split(" ",$val))',
        },
        # [advanced] select largest JPEG preview image
        BigImage            => {
            Groups    => { 2 => 'Preview' },
            Desire    => {
                0 => 'JpgFromRaw',
                1 => 'PreviewImage',
                2 => 'OtherImage',
                # (DNG and A100 ARW may be have 2 PreviewImage's)
                3 => 'PreviewImage (1)',
                # (if the MPF has 2 previews, MPImage3 could be the larger one)
                4 => 'MPImage3',
            },
            # ValueConv may also be a code reference
            # Inputs: 0) reference to list of values, 1) ExifTool object
            ValueConv => sub {
                my $val = shift;
                my ($image, $bigImage, $len, $bigLen);
                foreach $image (@$val) {
                    next unless ref $image eq 'SCALAR';
                    # check for JPEG image (or "Binary data" if -b not used)
                    next unless $$image =~ /^(\xff\xd8\xff|Binary data (\d+))/;
                    $len = $2 || length $$image; # get image length
                    # save largest image
                    next if defined $bigLen and $bigLen >= $len;
                    $bigLen = $len;
                    $bigImage = $image;
                }
                return $bigImage;
            },
        },
        # **** ADD ADDITIONAL COMPOSITE TAG DEFINITIONS HERE ****
        MediaDatePath       => {
            Desire    => {
                0 => 'DateTimeOriginal',
                1 => 'CreateDate',
                2 => 'ModifyDate',
                3 => 'GPSDateTime',
                4 => 'QuickTime:CreateDate'
            },
            ValueConv => sub {
                my $val = shift;
                my ($DateTime, $MediaPath, $DatePath);
                foreach $DateTime (@$val) {
                    next if not defined $DateTime;
                    $DateTime =~ /^(\d{4}):(\d{2}):(\d{2})/;
                    $MediaPath = "/" . $1 . "-Media";
                    $DatePath = $1 . "-" . $2 . "-" . $3;
                    return $MediaPath . "/" . $DatePath;
                }
            }
        },
        MediaModelPath      => {
            Desire    => {
                0 => 'EXIF:Model',
                1 => 'EXIF:Make'
            },
            ValueConv => sub {
                my $val = shift;
                my $MakeModel;
                return $$val[1] . " " . $$val[0] if $$val[1] =~ /(Hasselblad)/;
                foreach $MakeModel (@$val) {
                    next if not defined $MakeModel;
                    return $MakeModel;
                }
            }
        },
        IsMomentMedia       => {
            Require   => {
                0 => 'FilePath'
            },
            ValueConv => q{
                return 'true' if $val[0] =~ /\(\d{4}-\d{2}-\d{2}\)/;
            }
        },
        MediaPath           => {
            Require   => {
                0 => 'MediaDatePath',
                1 => 'MediaModelPath',
            },
            ValueConv => q{
                return $val[0] . "/" . $val[1];
            }
        },
        HasUsefulParent => {
            Require   => {
                0 => 'Directory'
            },
            ValueConv => sub {
                my $val = shift;
                return $1 if $$val[0] =~ /(\d{3}MEDIA)$/;
                return $1 if $$val[0] =~ /((PANORAMA|HYPERLAPSE|HDR)\/\d{3}_\d{4})$/;
                return $1 if $$val[0] =~ /(\d{3}N\w+)$/;
                return $1 if $$val[0] =~ /(\d{3}(APPLE|IMPRT))$/;
                return $1 if $$val[0] =~ /(FOLDER\d{2})$/;
                return $1 if $$val[0] =~ /(\d{3}GOPRO)$/;
                return;
            }
        }
    },
);

# This is a basic example of the definition for a new XMP namespace.
# This table is referenced through a SubDirectory tag definition
# in the %Image::ExifTool::UserDefined definition above.
# The namespace prefix for these tags is 'xxx', which corresponds to
# an ExifTool family 1 group name of 'XMP-xxx'.
%Image::ExifTool::UserDefined::xxx = (
    GROUPS => { 0 => 'XMP', 1 => 'XMP-xxx', 2 => 'Image' },
    NAMESPACE => { 'xxx' => 'http://ns.myname.com/xxx/1.0/' },
    WRITABLE => 'string', # (default to string-type tags)
    # Example 8.  XMP-xxx:NewXMPxxxTag1 (an alternate-language tag)
    # - replace "NewXMPxxxTag1" with your own tag name (eg. "MyTag")
    NewXMPxxxTag1 => { Writable => 'lang-alt' },
    # Example 9.  XMP-xxx:NewXMPxxxTag2 (a string tag in the Author category)
    NewXMPxxxTag2 => { Groups => { 2 => 'Author' } },
    # Example 10.  XMP-xxx:NewXMPxxxTag3 (an unordered List-type tag)
    NewXMPxxxTag3 => { List => 'Bag' },
    # Example 11.  XMP-xxx:NewXMPxxxStruct (a structured tag)
    # - example structured XMP tag
    NewXMPxxxStruct => {
        # the "Struct" entry defines the structure fields
        Struct => {
            # optional namespace prefix and URI for structure fields
            # (required only if different than NAMESPACE above)
            # --> multiple entries may exist in this namespace lookup,
            # with the last one alphabetically being the default for
            # the fields, but each field may have a "Namespace"
            # element to specify which prefix to use
            NAMESPACE => { 'test' => 'http://x.y.z/test/' },
            # optional structure name (used for warning messages only)
            STRUCT_NAME => 'MyStruct',
            # optional rdf:type property for the structure
            TYPE => 'http://x.y.z/test/xystruct',
            # structure fields (very similar to tag definitions)
            X => { Writable => 'integer' },
            Y => { Writable => 'integer' },
            # a nested structure...
            Things => {
                List => 'Bag',
                Struct => {
                    NAMESPACE => { thing => 'http://x.y.z/thing/' },
                    What  => { },
                    Where => { },
                },
            },
        },
        List => 'Seq', # structures may also be elements of a list
    },
    # Each field in the structure has a corresponding flattened tag that is
    # generated automatically with an ID made from a concatenation of the
    # original structure tag ID and the field name (after capitalizing the
    # first letter of the field name if necessary).  The Name and/or
    # Description of these flattened tags may be changed if desired, but all
    # other tag properties are taken from the structure field definition.
    # The "Flat" flag must be used when setting the Name or Description of a
    # flattened tag.  For example:
    NewXMPxxxStructX => { Name => 'SomeOtherName', Flat => 1 },
);

# Adding a new MIE group requires a few extra definitions
use Image::ExifTool::MIE;
%Image::ExifTool::UserDefined::MIETest = (
    %Image::ExifTool::MIE::tableDefaults,   # default MIE table entries
    GROUPS      => { 0 => 'MIE', 1 => 'MIE-Test', 2 => 'Document' },
    WRITE_GROUP => 'MIE-Test',
    # Example 16.  MIE-Test:NewMieTag2
    NewMieTag2  => { },     # new user-defined tag in MIE-Test group
);

# A special 'Lenses' list can be defined to give priority to specific lenses
# in the logic to determine a lens model for the Composite:LensID tag
@Image::ExifTool::UserDefined::Lenses = (
    'Sigma AF 10-20mm F4-5.6 EX DC',
    'Tokina AF193-2 19-35mm f/3.5-4.5',
);

# User-defined file types to recognize
%Image::ExifTool::UserDefined::FileTypes = (
    XXX => { # <-- the extension of the new file type (case insensitive)
        # BaseType specifies the format upon which this file is based (case
        # sensitive).  If BaseType is defined, then the file will be fully
        # supported, and in this case the Magic pattern should not be defined
        BaseType => 'TIFF',
        MIMEType => 'image/x-xxx',
        Description => 'My XXX file type',
        # if the BaseType is writable by ExifTool, then the new file type
        # will also be writable unless otherwise specified, like this:
        Writable => 0,
    },
    YYY => {
        # without BaseType, the file will be recognized but not supported
        Magic => '0123abcd',    # regular expression to match at start of file
        MIMEType => 'application/test',
        Description => 'My YYY file type',
    },
    ZZZ => {
        # if neither BaseType nor Magic are defined, the file will be
        # recognized by extension only.  MIMEType will be application/unknown
        # unless otherwise specified
        Description => 'My ZZZ file type',
    },
    # if only BaseType is specified, then the following simplified syntax
    # may be used.  In this example, files with extension "TTT" will be
    # processed as JPEG files
    TTT => 'JPEG',
);

# Change default location for writing QuickTime tags so Keys is preferred
# (by default, the PREFERRED levels are: ItemList=2, UserData=1, Keys=0)
use Image::ExifTool::QuickTime;
$Image::ExifTool::QuickTime::Keys{PREFERRED} = 3;

# Specify default ExifTool option values
# (see the Options function documentation for available options)
%Image::ExifTool::UserDefined::Options = (
    CoordFormat => '%.6f',  # change default GPS coordinate format
    Duplicates => 1,        # make -a default for the exiftool app
    GeoMaxHDOP => 4,        # ignore GPS fixes with HDOP > 4
    RequestAll => 3,        # request additional tags not normally generated
);

#------------------------------------------------------------------------------
1;  #end