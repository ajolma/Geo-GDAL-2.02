use v5.10;
use Alien::gdal;
use ExtUtils::MakeMaker;
use Alien::Base::Wrapper qw( Alien::gdal !export );
use Data::Dumper;

my $libs = [Alien::gdal->libs()];
print Dumper $libs;
say STDERR Alien::gdal->dist_dir;

my %args = Alien::Base::Wrapper->mm_args;

# the dep-libs should be in the %args
# but it is not, so, look into Alien::gdal->dist_dir() . "/bin/gdal-config" if it exists
# and add CONFIG_DEP_LIBS to $args{LIBS}[0]
my $gdal_config = Alien::gdal->dist_dir() . "/bin/gdal-config";
if (open(my $fh, "<", $gdal_config)) {
    while (<$fh>) {
        if (/^CONFIG_DEP_LIBS=(.*)/) {
            my $dep = $1;
            $dep =~ s/^\"//;
            $dep =~ s/\"$//;
            $args{LIBS}[0] .= ' '.$dep;
        }
    }
    close $fh;
} else {
    say STDERR "gdal-config not found in Alien share.\nLIBS will be just CONFIG_INST_LIBS from gdal.pc";
}

print Dumper \%args;

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
