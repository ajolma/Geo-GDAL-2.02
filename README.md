[![Build Status](https://travis-ci.org/ajolma/Geo-GDAL-2.02.svg?branch=master)](https://travis-ci.org/ajolma/Geo-GDAL-2.02)

Geo-GDAL
=======================

This is the swig-generated Perl interface to the GDAL/OGR library. The
master copy of this module is developed and distributed with GDAL.
GDAL is available from www.gdal.org.

You need to have the development (header files etc.) versions of gdal and
geos libraries available in your system to build these modules.

The versions of GDAL and this interface must match. Makefile.PL
attempts to do that, but it is highly recommended to install Geo::GDAL
from GDAL sources.

This module is _not_ compatible with Geo::GDAL 0.11

INSTALLATION FROM CPAN DISTRIBUTION

When this module is installed from a CPAN distribution, it must first
find GDAL development files. That is basically about finding the
gdal-config script. You can specify gdal-config or you can let
Makefile.PL search for it. However, this module is usually very
specific about the version of the GDAL it can be built against. The
branch needs to be the same.

If gdal-config was not found or its version is not good and
Makefile.PL had to look it by itself, Makefile.PL will try to download
and build GDAL. That is mostly meant for automatic testing only.

Control the GDAL that this module is built against:

  --gdal-config=PATH  use PATH as the gdal-config
    the same as environment variable PERL_GDAL_CONFIG=PATH

  --no-version-check  allow building against GDAL with different version
    the same as setting environment variable PERL_GDAL_NO_VERSION_CHECK=1

  --no-downloads      disable fetching GDAL source code as a last resort
    the same as setting environment variable PERL_GDAL_NO_DOWNLOADS=1

More information about running Makefile.PL is available at
ExtUtils-MakeMaker documentation.

To build, test and install this module the basic steps are

perl Makefile.PL
make
make test
make install

DEPENDENCIES

This module requires the GDAL library.

DOCUMENTATION

The documentation is maintained in Doxygen files. You will also need
Doxygen-Filter-Perl. To generate the documentation type

make doc

You can find the documentation also at http://arijolma.org/Geo-GDAL/snapshot/.

GDAL: http://www.gdal.org/
Doxygen : http://www.doxygen.org
Doxygen-Filter-Perl: http://search.cpan.org/~jordan/Doxygen-Filter-Perl/

COPYRIGHT AND LICENCE

Copyright (C) 2006- by Ari Jolma and GDAL Swig developers.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.
