#!/usr/bin/env perl
# -*- mode: perl -*-
# Author: Creative Commons Corporation, 2016.
# License: CC0. http://creativecommons.org/publicdomain/zero/1.0/
#          To the extent possible under law, Creative Commons Corporation
#          has waived all copyright and related or neighboring rights to ccexif.
#
# ccexif is a simple Unix command line tool to read and write Creative Commons
# license information in the Exif metadata of images.
#
# The format of this information is described in the Exif metadata proposal document.
# ccexif does not currently read, write or reconcile XMP license information.
#
# Dependency Install.
# ccexif requires Perl 5 and the ArgParse and ExifTool libraries. If the latter
# are not already installed they can be installed using cpan:
# cpan
# install Getopt::ArgParse
# install Image::ExifTool
# exit
#
# Reading Metadata: ./ccexif.pl person.jpg
# Writing Metadata: ./ccexif.pl --license by-sa --title person --workurl http://blah.com/person.jpg --author you --authorurl https://blah.com/author person.jpg

use strict;

use Getopt::ArgParse;
use Image::ExifTool qw(:Public);
use File::Copy qw(copy);

my %license_urls = (
    'by' => 'https://creativecommons.org/licenses/by/4.0/',
    'by-sa' => 'https://creativecommons.org/licenses/by-sa/4.0/',
    'by-nd' => 'https://creativecommons.org/licenses/by-nd/4.0/',
    'by-nc' => 'https://creativecommons.org/licenses/by-nc/4.0/',
    'by-nc-sa' => 'https://creativecommons.org/licenses/by-nc-sa/4.0/',
    'by-nc-nd' => 'https://creativecommons.org/licenses/by-nc-nd/4.0/'
);

my %license_names = (
    'by' => 'Attribution',
    'by-sa' => 'Attribution-ShareAlike',
    'by-nd' => 'Attribution-NoDerivatives',
    'by-nc' => 'Attribution-NonCommercial',
    'by-nc-sa' => 'Attribution-NonCommercial-ShareAlike',
    'by-nc-nd' => 'Attribution-NonCommercial-NoDerivatives'
    );

my @license_ids = keys %license_urls;

my %license_urls_reverse = reverse %license_urls;

sub parse_args {
    my @argv = @_;
    my $parser = Getopt::ArgParse->new_parser(
        prog        => 'ccexif.pl',
        description => "A simple tool to get/set JPEG Exif Creative Commons license metadata."
        );
    $parser->add_arg('--ignoreminorerrors', '-m', type => 'Bool',
                     help => 'ignore minor errors (e.g. "Bad PreviewIFD directory"');
    $parser->add_arg('--author', '-a',
                     help => 'attribution for the author, e.g. A. N. Other');
    $parser->add_arg('--title', '-t',
                     help => 'title of the work, e.g. My Cat');
    $parser->add_arg('--workurl', '-w',
                     help => 'url for the work, e.g. http://anopics.cc/cat');
    $parser->add_arg('--authorurl', '-u',
                     help => 'url for the author, e.g. http://anopics.cc/');
    $parser->add_arg('--license', '-l', choices => \@license_ids,
                     help => 'license identifier');
    $parser->add_arg('filename', required => 1,
                     help => 'the file to modify (a backup is created)');
    my $args = $parser->parse_args(@argv);
    return $args;
}

sub get_author {
    # Set author and author_url from args, or if not set parse Author.
    my ($metadata, $args) = @_;
    my $author = $args->author;
    my $author_url = $args->authorurl;
    if (! $author) {
        my $author_field = $metadata->GetValue('Artist');
        if ($author_field) {
            # Regex ignores space, punctuation, anything after closing >
            if ($author_field =~ /^(.+)\s*<([^>]+)>[^>]*$/) {
                $author = $1;
                $author_url = $2;
            } else {
                $author = $author_field;
            }
        }
    }
    return ($author, $author_url);
}

sub get_title {
    # Set title and work_url from args, or if not set parse Title.
    my ($metadata, $args) = @_;
    my $title = $args->title;
    my $work_url = $args->workurl;
    if (! $title) {
        my $title_field = $metadata->GetValue('ImageDescription');
        if ($title_field) {
            # Regex ignores space, punctuation, anything after closing >
            if ($title_field =~ /^(.+)\s*<([^>]+)>[^>]*$/) {
                $title = $1;
                $work_url = $2;
            } else {
                $title = $title_field;
            }
        }
    }
    return ($title, $work_url);
}

sub get_license_id {
    # Set license id from args, extract it from Copyright url, or False.
    my ($metadata, $args) = @_;
    my $license_id = $args->license;
    if (! $license_id) {
        my$copyright_field = $metadata->GetValue('Copyright');
        if ($copyright_field =~ /<([^>]+)>\s*\.?\s*$/) {
            $license_id = $1;
        }
    }
    return $license_id;
}

sub set_author {
    # If the author is set, use that. If author_url is also set, use both.
    my ($metadata, $author, $author_url) = @_;
    if ($author) {
        if ($author_url) {
            $metadata->SetNewValue('Artist',
                                   $author . ' <' . $author_url . '>');
        } else {
            $metadata->SetNewValue('Artist', $author);
        }
    }
}


sub set_title {
    # If the title is set, use that. If work_url is also set, use both.
    my ($metadata, $title, $work_url) = @_;
    if ($title) {
        if ($work_url) {
            $metadata->SetNewValue('ImageDescription',
                                   $title . ' <' . $work_url . '>');
        } else {
            $metadata->SetNewValue('ImageDescription', $title);
        }
    }
}

sub set_copyright {
    # Build a copyright field from the provided author, etc.
    my ($metadata, $title, $author, $license_id) = @_;
    my $text = '';
    if ($title && $author) {
        $text .= '"' . $title . '" by ' . $author . '. ';
    } elsif ($title) {
        $text .= $title . '. ';
    } elsif ($author) {
        $text .= 'By ' . $author . '. ';
    }
    if ($license_id) {
        $text .= 'This work is licensed under the Creative Commons '
            . $license_names{$license_id} . ' 4.0 International License.'
            . ' To view a copy of this license, visit <'
            . $license_urls{$license_id} . '>.';
    } else {
        $text .= 'is All Rights Reserved.';
    }
    $metadata->SetNewValue('Copyright', $text);
}

sub set_metadata {
    my ($exifTool, $args) = @_;
    my ($author, $author_url) = get_author($exifTool, $args);
    set_author($exifTool, $author, $author_url);
    my ($title, $work_url) = get_title($exifTool, $args);
    set_title($exifTool, $title, $work_url);
    my $license_id = get_license_id($exifTool, $args);
    set_copyright($exifTool, $title, $author, $license_id);
}

sub display_metadata {
    my ($exifTool, $args) = @_;
    my ($title, $work_url) = get_title($exifTool, $args);
    my $title_field = $exifTool->GetValue('ImageDescription');
    CORE::say "Exif ImageDescription: " . $title_field;
    CORE::say "Title:                 " . $title;
    CORE::say "Work URL:              " . $work_url;
    my $author_field = $exifTool->GetValue('Artist');
    my ($author, $author_url) = get_author($exifTool, $args);
    CORE::say "Exif Artist:           " . $author_field;
    CORE::say "Author:                " . $author;
    CORE::say "Attribution URL:       " . $author_url;
    my $copyright_field = $exifTool->GetValue('Copyright');
    my $license_id = get_license_id($exifTool, $args);
    CORE::say "Exif Copyright:        " . $copyright_field;
    CORE::say "License ID:            " . $license_id;
}

# Configuration

my $args = parse_args(@ARGV);
my $filename = $args->filename;
CORE::say "Filename:              " . $filename;

my $exifTool = new Image::ExifTool;
if ($args->ignoreminorerrors) {
    $exifTool->Options(IgnoreMinorErrors => 1);
}

# Update the metadata, if the license is set

if ($args->license) {
    my $info = $exifTool->ImageInfo($filename);
    set_metadata($exifTool, $args);
    my $err = $exifTool->WriteInfo($filename);
    my $error_message = $exifTool->GetValue('Error');
    if ($error_message) {
        CORE::say 'ERROR:                 ' . $error_message;
        CORE::say "To ignore [minor] errors (e.g. \"Bad PreviewIFD directory\")"
            . ": --ignoreminorerrors";
        exit 2;
    }
    my $warning_message = $exifTool->GetValue('Warning');
    if ($warning_message) {
        CORE::say 'WARNING:               ' . $warning_message;
    }
}

# Display the (newly updated) metadata

my $info = $exifTool->ImageInfo($filename);
display_metadata($exifTool, parse_args([]));
