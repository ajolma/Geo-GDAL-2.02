use strict;
use warnings;
use v5.10;
use File::Basename;
use ExtUtils::MakeMaker;
use Config;
use Cwd;
use File::ShareDir::Install;

my @my_gdal_version = my_gdal_version();
my $my_gdal_version = $my_gdal_version[0] + $my_gdal_version[1]/10;

# pick up our parameters from @ARGV
my %ARGV;
for (@ARGV) {
    if (/^(.*?)\=(.*)/) {
        $ARGV{$1} = $2;
    } else {
        $ARGV{$_} = 1;
    }
    $_ = '' if /^--gdal-source-tree/;
    $_ = '' if /^--gdal-config/;
    $_ = '' if /^--no-version-check/;
    $_ = '' if /^--no-downloads/;
    print STDERR "Warning: unknown parameter: '$_'.\n" if $_;
}
# ... or from the environment
$ARGV{'--gdal-source-tree'} = $ENV{PERL_GDAL_SOURCE_TREE} if $ENV{PERL_GDAL_SOURCE_TREE};
$ARGV{'--gdal-config'} = $ENV{PERL_GDAL_CONFIG} if $ENV{PERL_GDAL_CONFIG};
$ARGV{'--no-version-check'} = 1 if $ENV{PERL_GDAL_NO_VERSION_CHECK};
$ARGV{'--no-downloads'} = 1 if $ENV{PERL_GDAL_NO_DOWNLOADS};

if ($ARGV{'--help'}) {
    print <<end;
This is Perl module Geo::GDAL, for GDAL $my_gdal_version.
    
'perl Makefile.pl' configures this package to many kinds of systems.

Usage: perl Makefile.pl [OPTION]

To assign environment variables, specify them as VAR=VALUE.

Control the GDAL that this module is built against:

  --gdal-source-tree=PATH  use PATH as the gdal source
    the same as environment variable PERL_GDAL_SOURCE_TREE=PATH

  --gdal-config=PATH  use PATH as the gdal-config
    the same as environment variable PERL_GDAL_CONFIG=PATH

  --no-version-check  allow building against GDAL with different version
    the same as setting environment variable PERL_GDAL_NO_VERSION_CHECK=1

  --no-downloads      disable fetching GDAL source code as a last resort
    the same as setting environment variable PERL_GDAL_NO_DOWNLOADS=1

More information is available at ExtUtils-MakeMaker documentation.

end
exit;
}

my ($source_tree, $gdal_config) = find_gdal_config($ARGV{'--gdal-source-tree'}, $ARGV{'--gdal-config'});

my $download;
my @found_gdal_version;
my $found_gdal_version;
if ($gdal_config) {
    @found_gdal_version = gdal_version_from_gdal_config($gdal_config);
    $found_gdal_version = join '.', $found_gdal_version[0] + $found_gdal_version[1]/10;;
    say STDERR "Found GDAL version $found_gdal_version.";

    if ($my_gdal_version == $found_gdal_version) {
        say STDERR "That's the same version that this module was developed against. All is well.";
    } elsif ($my_gdal_version < $found_gdal_version) {
        say STDERR "That's newer than what this module was developed against. All should be well.";
    } elsif ($my_gdal_version > $found_gdal_version) {
        say STDERR "That's older than what this module was developed against. That's not good.";
        $download = 1;
    }
} else {
    $download = 1;
}

if ($download && !$ARGV{'--no-downloads'}) {
    print <<end;
    
Either GDAL development files were not found or they are too old for
this module (which is for $my_gdal_version). I am going to try to
download and compile GDAL for you.  You can prevent this happening by
pointing me to good GDAL development files, using the command line
argument --no-downloads, or by setting the environment variable
PERL_GDAL_NO_DOWNLOADS to a true value.

Note that this automatic download and compile is mostly meant for
automatic tests etc. It is recommended that you download and configure
GDAL by hand. Building GDAL may take a very long time. I will capture the
output from the build and put it into gdal-build.log and
gdal-build.err. You can look into them while this goes on but the
output will be buffered.

end
    $source_tree = "./gdal";
    download_and_compile_gdal(@my_gdal_version);
    $gdal_config = "$source_tree/apps/gdal-config";
}

my ($INC, $LIB, $objects) = get_config($source_tree, $gdal_config);

if ($ARGV{'--debug'}) {
    print "LIB = $LIB\n";
    print "INC = $INC\n";
}

install_share 'gdal/data' if -d 'gdal';

for my $module (sort keys %$objects) {
    my $add = $module;
    $add =~ s/:/_/g;
    my $LD = $Config{ld};
    $LD .= ' '.$ENV{CFLAGS} if $ENV{CFLAGS};
    $LD .= ' '.$ENV{LDFLAGS} if $ENV{LDFLAGS};
    my $OPTIMIZE = '';
    $OPTIMIZE .= ' '.$ENV{CFLAGS} if $ENV{CFLAGS};
    $OPTIMIZE .= ' '.$ENV{CPPFLAGS} if $ENV{CFLAGS};
    
    my %PM = ( 'lib/Geo/GDAL.pm' => '$(INST_LIBDIR)/GDAL.pm',
               'lib/Geo/OGR.pm' => '$(INST_LIBDIR)/OGR.pm',
               'lib/Geo/OSR.pm' => '$(INST_LIBDIR)/OSR.pm',
               'lib/Geo/GDAL/Const.pm' => '$(INST_LIBDIR)/GDAL/Const.pm' );
    
    $PM{'lib/Geo/GNM.pm'} = '$(INST_LIBDIR)/GNM.pm' if $objects->{'Geo::GNM'};

    WriteMakefile( NAME => $module,
                   VERSION_FROM => 'lib/Geo/GDAL.pm',
                   ABSTRACT => 'Perl extension for the GDAL library for geospatial data',
                   AUTHOR => 'Ari Jolma <ari.jolma at gmail.com>',
                   LICENSE => 'mit',
                   META_MERGE => {
                       'meta-spec' => { version => 2 },
                       resources => {
                           repository => {
                               type => 'svn',
                               url  => 'https://svn.osgeo.org/gdal/trunk/gdal/swig/perl',
                               web  => 'https://trac.osgeo.org/gdal/browser/trunk/gdal/swig/perl',
                           },
                       },
                   },
                   MAKEFILE => 'Makefile_'.$add,
                   LIBS => $LIB,
                   INC => $INC,
                   OPTIMIZE => $OPTIMIZE,
                   LD => $LD,
                   OBJECT => $objects->{$module},
                   PM => \%PM,
                   CONFIGURE_REQUIRES => {
                       'strict' => 0,
                       'warnings' => 0,
                       'File::Basename' => 0,
                       'ExtUtils::MakeMaker' => 0,
                       'Config' => 0,
                       'Cwd' => 0,
                       'File::Fetch' => 0,
                       'Capture::Tiny' => 0,
                   },
                   BUILD_REQUIRES => {
                       'strict' => 0,
                       'warnings' => 0,
                       'File::Basename' => 0,
                       'ExtUtils::MakeMaker' => 0,
                       'Config' => 0,
                       'File::Fetch' => 0,
                       'Capture::Tiny' => 0,
                       'Cwd' => 0,
                       'File::ShareDir::Install' => 0,
                       'LWP::Simple' => 0
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

sub find_gdal_config {
    my ($source_tree, $gdal_config) = @_;
    if ($source_tree) {
        # hack to force downloading of the source
        if ($source_tree eq 'download') {
            return;
        } else {
            die "Path '$source_tree' does not exist." unless -e $source_tree && -d $source_tree;
        }
    }
    if ($source_tree) {
        $gdal_config = "$source_tree/apps/gdal-config";
        die "There is no gdal-config in '$source_tree'.\n".
            "You have to first say \"cd $source_tree; make\"." unless -r $gdal_config;
    }
    if ($gdal_config) {
        unless (-r $gdal_config) {
            die "'$gdal_config' does not exist or is unreadable.\n";
        }
    } else {
        # scan known possible locations in the order of preference:
        my @test;
        for ('c:/msys/1.0/local/bin',
             '/usr/local/bin',
             '/usr/bin',
             "$ENV{HOME}/usr/bin") 
        {
            my $test =  $_ . '/gdal-config';
            push @test, $_ if -r $test;
        }
        if (@test) {
            $source_tree = $test[0];
            $gdal_config = $source_tree . '/gdal-config';
            print "Found gdal-config in directories: '",join("', '", @test),"'.\n";
            print "Will try '$gdal_config'.\n";
        } else {
            print STDERR "Did not find any gdal-config(s)\n";
        }
    }
    return ($source_tree, $gdal_config);
}

sub get_config {
    my ($source_tree, $config) = @_;
    my $INC = "-I$source_tree ";
    my $LIB = "-L$source_tree/.libs -L$source_tree -lgdal ";
    my $objects = { 
        'Geo::GDAL' => 'gdal_wrap.o',
        'Geo::OGR' => 'ogr_wrap.o',
        'Geo::GDAL::Const' => 'gdalconst_wrap.o',
        'Geo::OSR' => 'osr_wrap.o' };
    if (open(my $fh, $config) || die "Can't open '$config': $!") {
        for (<$fh>) {
            if (/^CONFIG_LIBS/) {
                s/^CONFIG_LIBS="//;
                s/"\s*$//;
                if ($_ =~ /\.la$/) { 
                    $LIB .= parse_libtool_library_file_for_l($_);
                } else {
                    $LIB .= $_;
                }
                $LIB .= ' ';
            }
            if (/^CONFIG_DEP_LIBS/) {
                s/^CONFIG_DEP_LIBS="//;
                s/"\s*$//;
                $LIB .= $_;
            }
            if (/^CONFIG_CFLAGS/) {
                s/^CONFIG_CFLAGS="//;
                s/"\s*$//;
                $INC .= $_;
            }
            if (/CONFIG_GNM_ENABLED/ and /yes/) {
                $objects->{'Geo::GNM'} = 'gnm_wrap.o';
                $INC .= " -I$source_tree/gnm ";
            }
        }
        close $fh;
    }
    return ($INC, $LIB, $objects);
}

sub my_gdal_version {
    my $version;
    if (open(my $fh, "lib/Geo/GDAL.pm")) {
        for (<$fh>) {
            if (/GDAL_VERSION/ && /\d+\.\d+\.\d+/) {
                ($version) = /(\d+\.\d+\.\d+)/;
                last;
            }
        }
        close $fh;
    } else {
        die "'lib/Geo/GDAL.pm' not found, your distribution is broken.";
    }
    die "There is no GDAL version number in 'lib/Geo/GDAL.pm'." unless $version;
    my @version = split /\./, $version;
    die "Bad GDAL version number in 'lib/Geo/GDAL.pm': $version" if @version != 3;
    return @version;
}

sub gdal_version_from_gdal_config {
    my $gdal_config = shift;
    my $version;
    if (-x $gdal_config) {
        chomp($version = `$gdal_config --version`);
    }
    else {
        if (open(my $fh, $gdal_config) || die "Can't open '$gdal_config': $!") {
            for (<$fh>) {
                ($version) = /(\d+\.\d+\.\d+)/ if /^CONFIG_VERSION/;
            }
            close $fh;
        }
        die "Can't find version from '$gdal_config'." unless $version;
    }
    my @version = split /\./, $version;
    die "Bad GDAL version number in 'lib/Geo/GDAL.pm': $version" if @version != 3;
    return @version;
}

sub download_and_compile_gdal {
    my (@version) = @_;
    require File::Fetch;
    require Capture::Tiny;
    require LWP::Simple;
    Capture::Tiny->import(':all');
    LWP::Simple->import('head');
    my $pwd = cwd();
    open(my $log, ">", "gdal-build.log") or die "Can't open gdal-build.log: $!.";
    open(my $err, ">", "gdal-build.err") or die "Can't open gdal-build.err: $!.";

    my $step = sub {
        my @cmd = @_;
        my $ret;
        print "@cmd\n";
        my $code = sub {
            if ($cmd[0] eq 'cd') {
                $ret = chdir($cmd[1]);
            } else {
                $ret = open(my $cmd, '-|', @cmd);
                if ($ret) {
                    my $flush = $|;
                    $| = 1;
                    my $i = 0;
                    while (<$cmd>) {
                        print $log $_;
                        print "#" if $i % 50 == 0;
                        $i++;
                    }
                    print "\n" if $i;
                    $| = $flush;
                    close($cmd);
                    if ($?) {
                        print "Error in '@cmd'.\n";
                        $ret = 0;
                    }
                } else {
                    print STDERR "'@cmd' returned $ret\n";
                }
            }
        };
        my ($stderr, $result) = capture_stderr($code);
        print $err $stderr;
        return $ret;
    };

    my $ok = 1;

    # get source code
    if (-d 'gdal') {
        print "Directory gdal exists. Will assume it is a suitable GDAL source tree.\n";
    } else {
        my $ext = 'tar.xz';
        print "Find the latest revision of GDAL version ".join('.',@version[0..1])."\n";
        my $version;
        my $url;
        while (1) {
            my $test_version = join '.', @version;
            my $test_url = "http://download.osgeo.org/gdal/$test_version/gdal-$test_version.$ext";
            if (head($test_url)) {
                print "found $test_version\n";
                $version = $test_version;
                $url = $test_url;
            } else {
                print "$test_version not found\n";
                --$version[2];
                last;
            }
            ++$version[2];
        }
        if ($url) {
            my $gdal = "gdal-$version.$ext";
            if (-r $gdal and -s $gdal) { 
                # fetch leaves a zero sized file even when it fails
                print "Using existing \"$gdal\"\n";
            } else {
                print "Attempting to fetch '$url'\n";
                my $ff = File::Fetch->new(uri => $url);
                $ok = $ff->fetch if $ff;
            }
            if ($ok) {
                # extract into gdal
                $ok = $step->("mkdir", "gdal") unless -d 'gdal';
                $ok = $ok && $step->("tar", "xf", $gdal, "-C", "gdal", "--strip-components=1");
            }
        } else {
            print "No luck. Maybe this is the development version?\n";
            $ok = $step->("svn", "checkout", "https://svn.osgeo.org/gdal/trunk/gdal", "gdal");
        }
    }
    # configure and compile
    if ($ok && -r 'gdal/apps/gdal-config') {
        print "The GDAL in gdal seems to be compiled.\n";
    } elsif ($ok) {
        for my $cmd (
            ["cd", "gdal"],
            ["./configure"],
            [($^O =~ /bsd/i ? "gmake" : "make"), "-j4"],
            ["cd", ".."]) 
        {
            $ok = $step->(@$cmd);
            last unless $ok;
        }
    }
    close $log;
    close $err;
    return if $ok;
    chdir($pwd);
    open($err, "<", "gdal-build.err") or die "Can't open gdal-build.err: $!.";
    my @err = <$err>;
    close $err;
    die "Downloading and/or compiling GDAL failed.\n".
        "The error is probably explained by the error log:\n".
        "@err\n";
}

sub parse_libtool_library_file_for_l {
    my $fn = shift;
    my $fh;
    my $l = '';
    if (open($fh, $fn)) {
        while (<$fh>) {
            if (/^dlname=(.*)/) {
                $l = $1;
                $l =~ s/^'//;
                $l =~ s/^lib/\-l/;
                $l =~ s/\..*$//;
                last;
            }
        }
        close $fh;
    }
    return $l;
}

package MY;
use File::ShareDir::Install qw(postamble);
