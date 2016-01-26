# Proposal for a formal way of expressing public license information in Exif

* Matt Lee, Technical Lead, Creative Commons
* Rob Myers, Software Developer, Creative Commons

January 2016, version 0.1.

## Abstract

Millions of digital photographs are available under Creative Commons
licenses, but there is no commonly used machine readable manner for
marking these images. 

## Introduction

The Exchangeable image file format (Exif) is a standard that specifies
the format of a series of tags used in digital photography.

Creative Commons produces a commonly used series of licenses and deeds
that photographers and artists use to express how they'd like their
work to be used by others, in the form of a deed. Creative Commons has
six current copyright licenses, approximately 30 historical licenses
and two deeds for works in the public domain. Every Creative Commons
license has a Uniform Resource Indentifer (URI), and many Creative
Commons languages are translated into multiple languages, each with
their own URI.

Exif provides tags for many aspects of digital photography, include
some which have privacy concerns, including the location and serial
number of the camera. Other Exif tags include more technical aspects
of the image, such as orientation (rotation) of the camera, exposure
time and resolution.

Amongst these many tags are fields for Author, Title and
Copyright. Our proposed standard allows photographers and artists to
use these fields to express their usage rights for their work, while
allowing for tools to strip other Exif data for reasons of
privacy. There is also another metadata standard, XMP which has some
historical usage here, but is generally less visible to users. XMP may
be used alongside our suggestions for XMP and tools such as
``libexif`` typically read/write both.

Exif has a “Copyright” field (p.40) that is meant to be an an
“interoperability copyright statement including date and rights” ASCII
string. The example given (p.41) has a simple human-readable format:

    Copyright, Anne Other, 2015. All rights reserved.

<http://www.cipa.jp/std/documents/e/DC-008-2012_E.pdf>

But the first example on Wikimedia’s Exif article does not follow this standard:

    This work is licensed under the Creative Commons Attribution 3.0
    Unported License. To view a copy of this license, visit
    http://creativecommons.org/licenses/by/3.0/ or send a letter to
    Creative Commons, 171 Second Street, Suite 300, San Francisco,
    California, 94105, USA.

<https://commons.wikimedia.org/wiki/Commons:Exif#ExifTool_how-to>

The Exif "Copyright" field can store both photographer and editor
information, separated by an ASCII NULL character. The length and
formatting of the data express which of photographer and editor is
present. 

Exif also has "Artist" and "ImageDescription" fields -- the former is
not necessarily the copyright holder, and the latter is meant to be
the image title.

## Extending Exif fields to include URIs

All Creative Commons licenses require attribution on the resulting
works. Our suggestion extends the three useful fields of Exif to
include relevant URIs which can be used to enhance the display of an
image.

For example:

Title:

    Cityscape at Sunset <http://flickr.com/photos/anne.other/23456789>

Author:

    Anne Other <http://flickr.com/profile/anne.other>

Copyright:

    Cityscape at Sunset by Anne Other. This work is licensed under the
	Creative Commons Attribution-ShareAlike 4.0 International
	License. To view a copy of this license, visit
	<http://creativecommons.org/licenses/by-sa/4.0/>

An application would be able to easily parse the URIs in these fields to extend to markup such as:

    <p><a
    href="http://flickr.com/photos/anne.other/23456789">Cityscape at
    Sunset</a> by <a href="http://flickr.com/profile/anne.other">Anne
    Other</a> <a
    href="http://creativecommons.org/licenses/by-sa/4.0/">Creative
    Commons Attribution-ShareAlike 4.0 International License</a></p>

## Conclusion

Marking digital images in this manner will allow them to exist on
their own, distinct from any web pages they may be embedded in. In
future, we hope platforms and applications will use this data as the
basis of providing automated correct attribution when embedding an
image. 
