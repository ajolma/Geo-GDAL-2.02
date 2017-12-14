use v5.10;
use Alien::gdal;
use ExtUtils::MakeMaker;
use Alien::Base::Wrapper qw( Alien::gdal !export );
use Data::Dumper;

my %args = Alien::Base::Wrapper->mm_args;

my $objects = { 
    'Geo::GDAL' => 'gdal_wrap.o',
    'Geo::OGR' => 'ogr_wrap.o',
    'Geo::GDAL::Const' => 'gdalconst_wrap.o',
    'Geo::OSR' => 'osr_wrap.o' 
};
#$objects->{'Geo::GNM'} = 'gnm_wrap.o';

$args{VERSION_FROM} = 'lib/Geo/GDAL.pm';
$args{ABSTRACT} = 'Perl extension for the GDAL library for geospatial data';
$args{AUTHOR} = 'Ari Jolma <ari.jolma at gmail.com>';
$args{LICENSE} = 'mit';
$args{META_MERGE} = {
    'meta-spec' => { version => 2 },
    resources => {
        repository => {
            type => 'svn',
            url  => 'https://svn.osgeo.org/gdal/trunk/gdal/swig/perl',
            web  => 'https://trac.osgeo.org/gdal/browser/trunk/gdal/swig/perl',
        },
    },
};

my $PM = {
    'lib/Geo/GDAL.pm' => '$(INST_LIBDIR)/GDAL.pm',
    'lib/Geo/OGR.pm' => '$(INST_LIBDIR)/OGR.pm',
    'lib/Geo/OSR.pm' => '$(INST_LIBDIR)/OSR.pm',
    'lib/Geo/GDAL/Const.pm' => '$(INST_LIBDIR)/GDAL/Const.pm'
};    
$PM->{'lib/Geo/GNM.pm'} = '$(INST_LIBDIR)/GNM.pm' if $objects->{'Geo::GNM'};

push @{$args{LIBS}}, '-LC:/strawberry/c/lib -ltiff';

print Dumper \%args;

for my $module (sort keys %$objects) {
    my $add = $module;
    $add =~ s/:/_/g;

    WriteMakefile(
        %args,
        NAME => $module,                   
        MAKEFILE => 'Makefile_'.$add,
        OBJECT => $objects->{$module},
        PM => $PM,
        CONFIGURE_REQUIRES => {
            'Alien::gdal' => 0
        },
        BUILD_REQUIRES => {
        },
        PREREQ_PM => {
            Carp => 0,
            Encode => 0,
            'Scalar::Util' => 0,
            POSIX => 0 
        },
        TEST_REQUIRES => {
            'Scalar::Util' => 0,
            'Test::More' => 0,
            'Encode' => 0,
            POSIX => 0
        } );
}
