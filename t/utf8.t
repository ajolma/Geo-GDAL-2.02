use v5.10;
use strict;
use warnings;
use Scalar::Util 'blessed';
use Encode qw(encode decode);
use Test::More tests => 15;
BEGIN { use_ok('Geo::GDAL') };

# test utf8 conversion in bindings and filenames
# todo: separate the two tests

# the file tests assume the filenames
# are cp1252 in windows and utf8 otherwise

my $win = $^O =~ /Win/;
my $touch = $win ? 'type nul >>' : 'touch';
my $cp;

if ($win) {
    ($cp) = `chcp` =~ /(\d+)/;
    $cp = 'cp' . $cp;
    binmode(STDERR, ":encoding($cp)");
} else {
    $cp = 'utf8';
    binmode STDERR, ":utf8";
}

# a filename with a non-ascii character
# this file is in encoding utf8
my $fn = decode utf8 => "Äri";

# in Linux the filenames are in utf8
# in Windows we use the codepage 1252

$cp = 'cp1252' if $win;

$fn = encode $cp => $fn;

 SKIP: {
     skip 'because on Windows', 2 if $win;
     ok(!utf8::is_utf8($fn), "Perl does not know the filename is in utf8");
     Encode::_utf8_on($fn); # turn the utf8 flag on
     ok(utf8::is_utf8($fn), "Now Perl knows the filename is in utf8");
};

system "$touch ./$fn"; # touch it

my $e = -e $fn;
ok($e, "After touch, file exists according to Perl"); # and it is there

# now use GDAL tools to check that the file exists
my %files = map {$_=>1} Geo::GDAL::VSIF::ReadDir('./');
ok($files{$fn}, "After touch, file exists according to VSIF");

Geo::GDAL::VSIF::Unlink($fn);
$e = -e $fn;
ok(!$e, "After VSIF Unlink, the file does not exist.");

system "$touch ./$fn"; # touch it again

$fn = "\xC4ri"; # same filename in Perl's internal format
ok(!utf8::is_utf8($fn), "Perl does not know the filename is in utf8");

$e = -e $fn;
if ($win) {
    ok($e, "But it does exist to it in Windows.");
} else {
    ok(!$e, "Thus it does not exist to it in Linux.");
}

 SKIP: {
     skip 'because on Windows', 2 if $win;
     $fn = encode $cp => $fn; # convert from internal format to utf8
     Encode::_utf8_on($fn); # turn the utf8 flag on
     ok(utf8::is_utf8($fn), "Now Perl knows the filename is in utf8");
     $e = -e $fn;
     ok($e, "An it exists also for it in Linux.");
};

$fn = "\xC4ri"; # internal format, no utf8 flag
Geo::GDAL::VSIF::Unlink($fn); # encoding is done in the bindings
$e = -e $fn;
ok(!$e, "encoding is done in the bindings");

$fn = decode utf8 => "Äri";
$fn = encode $cp => $fn;
system "$touch ./$fn"; # touch it again

for my $fn (Geo::GDAL::VSIF::ReadDir('./')) {
    ok(utf8::is_utf8($fn), "utf8 flag is set in the bindings");
    last;
}

 SKIP: {
     skip 'because on Windows', 2 if $win;
     system "echo Äri >Äri"; 
     $fn = `cat Äri`;
     chomp($fn);
     ok(!utf8::is_utf8($fn), "Perl does not know it has utf8");
     eval {
         Geo::GDAL::VSIF::Unlink($fn);
     };
     ok($@, "decoding utf8 to utf8 is not a good idea");
     Encode::_utf8_on($fn); # set utf8 flag on
};

$fn = decode utf8 => "Äri";
Geo::GDAL::VSIF::Unlink($fn);
$e = -e $fn;
ok(!$e, "Deleted the file.");
