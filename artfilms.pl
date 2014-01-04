#!/usr/bin/perl

#use strict;
use warnings;
#use Data::Dumper;

my $url = 'http://www.artgallery.nsw.gov.au/calendar/epic-america-film-series/';

die "No args neccessary" if @ARGV;

open F, "wget -q -O- $url|" or die "Could not open $url\n";

my %films;
my $film_series;

# Data structure:
# %films
#		-> FILM_TITLE
#					-> "time"
#							-> Wed 12th December 
#												-> 1
#					-> 'description'
#							-> text



# Parse the film details step by step
while (<F>) {

	s/^\w*//;

	# Film series title
	# <title>Epic America film series :: Art Gallery NSW</title>
	if ($_ =~ /\<title\>/) {
		s/\<?\/title\>//;
		$film_series = $_;
	}

	# Film title
	if ($_ =~ '<h3 class="toggle">'){

		s/\<h3 class=\"toggle\"\>//;
		s/<\/h3\>//;
		s/^\s*//;
		s/\s*$//;

		$title = $_;
		#$films{$title}++;

		#print "title: $title\n";
	}

	# Dates/times (multiple values, stored as VALUES)
	# 	ie FILM_TITLE -> "TIME" -> WED 12 December -> 1
	elsif ($_ =~ '<h3>We' or $_ =~ '<h3>Sun') {
		s/\<h3\>//;
		s/\<span.*l\"\>//;
		s/\w*&ndash\;\w*//;
		s/\<\/span\>\<\/h3\>//;
		$start = getStart($_);
		$end = getEnd($_);
		$films{$title}{"time"}{$time}++;
		
		#print "$title(time): $_\n";
	}

	# Description (including director, release date, rating, length, etc)
	elsif ($_ =~ '<p>Dir') {
		s/<\/?p>//g;
		s/<br\s*\/>//g;
		s/<\/?cite>//g;
		
		$films{$title}{"description"}=$_;

		#print "$title(desc): $_\n";
	}
	else {next;}
}

#print_films();
upload_films();

# Uploads the collected data to a Google Calendar
# Creates a new calendar if one matching the film series title does not exist
sub upload_films {

}

sub getStart {
	$time = shift;
}

# Change the date-time format to comply with RFC 3339 (as required by Google)
sub convertTime {
	my ($day, $date, $month, $year, $start, $end) = split;
	
	%mon2num = qw(
  					jan 1  feb 2  mar 3  apr 4  may 5  jun 6
  					jul 7  aug 8  sep 9  oct 10 nov 11 dec 12
				);

	$month = $mon2num{lc substr($month,0,3)};
	
	$start = convert24hr($start) if ($start =~ /.*pm/);
	$end = convert24hr($end) if ($end =~ /.*pm/);


	print "$start - $end\n";

	#print "$year-$month-$date"."T"."$start\n";
}

sub convert24hr {
	$time = shift;

	if ($time =~ /^(\d)pm$/) {
			$hour = $1+12;
			$time = "$hour".":00";

		} elsif ($time =~ /(\d):(\d*)pm/) {
			$hour = $1+12;
			$time = "$hour".":"."$2";
		}
return $time;
}

# Print function - use for debugging
# Easier to see key parts than Data Dumper
sub print_films {

	print "$film_series\n";

	foreach my $title (keys %films) {
		print "$title\n";

		#print "$films{$title}{description}\n";

		foreach my $time (keys $films{$title}{'time'}) {
			print "\t:$time\n";
		}
	}
}

