#!/usr/bin/perl
#
# Copyright Eric Windisch, 2003.
# Licensed under the MIT license.
#
use strict;
use Image::Magick;
use Getopt::Long;
use Config::IniFiles;

my ($config_file, $path, $tmppath, $generator,$verbose, $inherits,$tmpscheme,$shadow, $opacity, $shadowx, $shadowy, $shadowblur,$shadowblursigma);

# default for variables
$verbose=0;
$shadow=0;
$opacity=100;
$shadowx=2;
$shadowy=3;
$shadowblur=2;
$shadowblursigma=1;
$path="theme/";
$tmppath="tmp/";
$generator="/usr/bin/X11/xcursorgen";
# it seems that recursive inheritance does not yet exist.
$inherits="whiteglass";

sub process {
	print <<EOF;
Usage:
$0 [-v] [--inherits theme] [--shadow] [--shadow-x pixels] [--shadow-y pixels] [--shadow-blur size] [--shadow-blur-sigma size] [--generator xcursorgen-path] [--tmp temp-dir]
EOF
	exit 0;
};

GetOptions (
	'inherits=s'=>\$inherits,
	'tmp=s'=>\$tmppath,
	'shadow'=>\$shadow,
	'v'=>\$verbose,
	'generator=s'=>\$generator,
	'opacity=i'=>\$opacity,
	'<>' => \&process,
	'help'=>\&process,
	'shadow-x=i'=>\$shadowx,
	'shadow-y=i'=>\$shadowy,
	'shadow-blur=i'=>\$shadowblur,
	'shadow-blur-sigma=i'=>\$shadowblursigma
);

# make sure path and tmppath end in /
if ($path =~ /[^\/]$/) {
	$path=$path."/";
}
if ($tmppath =~ /[^\/]$/) {
	$tmppath=$tmppath."/";
}

if (! -d $path) {
	mkdir ($path);
}
if (! -d $path."cursors/") {
	mkdir ($path."cursors/");
}
if (! -d $tmppath) {
	mkdir ($tmppath);
}
$tmpscheme=$tmppath."Scheme.ini";

# I did this much nicer, but Perl < 5.8 choked.
open (INI, "< Scheme.ini") or die ("Cannot open Scheme.ini");
open (INF, ">", $tmpscheme);
while (<INI>) {
	unless (!/=/ && !/^\s*\[/) {
		#$config_file.=$_;
		print INF $_;
	}
}
close (INI);
close (INF);

my $cfg=new Config::IniFiles(-file=>$tmpscheme) or die ("Scheme.ini in wrong format? -".$@);
my @sections=$cfg->Sections;

my $filemap={
	Arrow=>["left_ptr","X_cursor","right_ptr",'4498f0e0c1937ffe01fd06f973665830'],
	Cross=>["tcross","cross"],
	Hand=>["hand1", "hand2",'9d800788f1b08800ae810202380a0822','e29285e634086352946a0e7090d73106'],
	IBeam=>"xterm",
	UpArrow=>"center_ptr",
	SizeNWSE=>["bottom_right_corner","top_left_corner",'c7088f0f3e6c8088236ef8e1e3e70000'],
	SizeNESW=>["bottom_left_corner","top_right_corner",'fcf1c3c7cd4491d801f1e1c78f100000'],
	SizeWE=>["sb_h_double_arrow", "left_side", "right_side",'028006030e0e7ebffc7f7070c0600140'],
	SizeNS=>["double_arrow","bottom_side","top_side",'00008160000006810000408080010102'],
	Help=>["question_arrow",'d9ce0ab605698f320427677b458ad60b'],
	Handwriting=>"pencil",
	AppStarting=>["left_ptr_watch", '3ecb610c1bf2410f44200f48c40d3599'],
	SizeAll=>"fleur",
	Wait=>"watch",
	NO=>"03b6e0fcb3499374a867c041f52298f0"
};

foreach my $section (@sections) {
	my ($filename);

	$filename=$section.".png";
	unless (-f $filename) {
		next;
	}

	my ($image, $x, $frames, $width, $height, $curout);

	$image=Image::Magick->new;
	$x=$image->Read($filename);
	warn "$x" if "$x";

        $frames=$cfg->val($section, 'Frames');
	$width=$image->Get('width')/$frames;
	$height=$image->Get('height');

	if (defined($filemap->{$section})) {
		$curout=$filemap->{$section};
	} else {
		$curout=$section;
	}

	my $array=-1;
	eval {
		if (defined (@{$curout}[0])) { };
	};
	unless ($@) {
		$array=0;
	} 

	LOOP:
	my $outfile;

	if ($array > -1) {
		if (defined (@{$curout}[0])) {
			$outfile=pop @{$curout};
		} else {
			next;
		}
	} else {
		$outfile=$curout;
	}
	$outfile=$path."cursors/".$outfile;

	if ($verbose) {
		print "Writing to $section -> $outfile\n";
	}

	open (FH, "| $generator > \"$outfile\"");

	for (my $i=0; $i<$frames; $i++) {
		my ($tmpimg, $outfile);
		$outfile=$tmppath.$section.'-'.$i.'.png';
		$tmpimg=$image->Clone();

		$x=$tmpimg->Crop(width=>$width, height=>$height, x=>$i*$width, y=>0);
		warn "$x" if "$x";



		if ($shadow) {
			my $shadow=$tmpimg->Clone();
			my $orig=$tmpimg->Clone();
			my $mask1; # shadow mask
			my $mask2=$tmpimg->Clone();

			$x=$orig->Crop(x=>0, y=>0, height=>$height, width=>$width);
			 warn "$x" if "$x";
			$orig->Set(size=>$width+$shadowx."x".$height+$shadowy);
			 warn "$x" if "$x";

			$x=$shadow->Quantize(colorspace=>"Gray");
			 warn "$x" if "$x";
			$x=$shadow->Level(level=>0, gamma=>0);
			 warn "$x" if "$x";
			$x=$shadow->Gamma(gamma=>0);
			 warn "$x" if "$x";
			$x=$shadow->Blur(radius=>$shadowblur, sigma=>$shadowblursigma);
			 warn "$x" if "$x";

			$mask1=$shadow->Clone();

			$x=$mask1->Channel('Matte');
			 warn "$x" if "$x";
			#$x=$mask2->Channel('Matte');
			# warn "$x" if "$x";
			$x=$mask2->Composite(image=>$mask1, compose=>"Over");
			 warn "$x" if "$x";

			#$x=$orig->Composite(image=>$shadow, compose=>"Over", x=>$shadowx, y=>$shadowy, opacity=>0, mask=>$mask2);
			 warn "$x" if "$x";
			#$x=$orig->Composite(image=>$tmpimg, compose=>"Over", x=>0, y=>0, opacity=>0, mask=>$mask2);
			 warn "$x" if "$x";
			#$x=$orig->Composite(image=>$tmpimg, compose=>"Over", x=>0, y=>0, opacity=>0, mask=>$mask1);
			 #warn "$x" if "$x";

			#$tmpimg=$shadow;
			$tmpimg=$orig;
		}

		# Opacity
		if (0) {
		my $tmpimg1=$tmpimg->Clone();
		my $x=$tmpimg1->Channel('Matte');
		warn "$x" if "$x";

		$tmpimg1->Set(type=>"GrayscaleMatte");
		$x=$tmpimg1->Quantize(colorspace=>"Gray");
		warn "$x" if "$x";
		
		$x=$tmpimg->Level(level=>0, gamma=>0);
		warn "$x" if "$x";

		$x=$tmpimg1->Gamma(gamma=>100);
		warn "$x" if "$x";

		$x=$tmpimg->Composite(image=>$tmpimg, compose=>"Over", mask=>$tmpimg1);
		warn "$x" if "$x";
		# end Opacity
		}

		$x=$tmpimg->Write($outfile);
		warn "$x" if "$x";

		print FH "1 ".
			$cfg->val($section,'Hot spot x')." ".
			$cfg->val($section,'Hot spot y')." ".
			$outfile." ".
			$cfg->val($section,'Interval')."\n";
	}

	if ($array > -1) {
		goto LOOP;
	}
}

print "Writing theme index.\n";
open (FH, "> ${path}index.theme");
print FH <<EOF;
[Icon Theme]
Inherits=$inherits
EOF
close (FH);

print "Done. Theme wrote to ${path}\n";
