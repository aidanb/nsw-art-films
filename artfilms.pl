#!/usr/bin/perl

#use strict;
use warnings;
use Net::Google::Calendar;
use DateTime::Format::RFC3339;
use Data::Dumper;

my $url = 'http://www.artgallery.nsw.gov.au/calendar/epic-america-film-series/';

#die "Usage: $0 password\n" if !@ARGV;

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
	elsif ($_ =~ '<h3>(Mon|Tue|Wed|Thur|Fri|Sat|Sun)' ) {
		s/\<h3\>//;
		s/\<span.*l\"\>//;
		s/\w*&ndash\;\w*//;
		s/\<\/span\>\<\/h3\>//;
		
		$time = getTime($_);

		$films{$title}{'time'}{$time}++;
				
		#print "$title:\t$films{$title}{'time'}\n";
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

#print Dumper(\%films);
#print_films();
upload_films();



# Returns a string for the start date/time for the event
sub getTime {
	my $time = shift;

	$time =~ s/ /-/;
	
	return convertTime($time);
}

# Change the date-time format to comply with RFC 3339 (as required by Google)
sub convertTime {
	my ($day, $date, $month, $year, $start, $end) = split;

	$date = "0"."$date" if $date =~ /^\d{1}$/;
	
	%mon2num = qw(
  					jan 01  feb 02  mar 03  apr 04  may 05  jun 06
  					jul 07  aug 08  sep 09  oct 10 nov 11 dec 12
				);

	$month = $mon2num{lc substr($month,0,3)};
	
	$start = convert24hr($start) if ($start =~ /.*pm/);
	$end = convert24hr($end) if ($end =~ /.*pm/);


	return "$year-$month-$date"."T"."$start-$end";
	#print "$year-$month-$date"."T"."$start-$end\n";
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


# Upload the films to a Google Calendar hosted by aidanb
sub upload_films {
	my $cal_url = "https://www.google.com/calendar/feeds/sgidcsi1fo1j3r4dukkj9sksno%40group.calendar.google.com/public/basic";

	my $username = 'nswartfilms';
	my $password = 'nswartfilms90210';

	my $cal = Net::Google::Calendar->new( url => $cal_url);
	$cal->login($username, $password);


	foreach my $title (keys %films) {
	

		foreach my $time (keys $films{$title}{'time'}) {

			# Create a new datetime object with Sydney UTC offset (+11 hours)
			my $start = $time;
			$start =~ s/-\d{2}:\d{2}$//;
			$start = $start.":00+11:00";
			$start = DateTime::Format::RFC3339->parse_datetime($start);


			my $end =  $time;
			$end =~ s/T\d{2}:\d{2}-/T/;
			$end = $end.":00+11:00";
			$end = DateTime::Format::RFC3339->parse_datetime($end);

			print "Uploading event:\n";
			print "$title\n";
			print DateTime::Format::RFC3339->format_datetime($start); print "\n";
			print DateTime::Format::RFC3339->format_datetime($end); print "\n\n";

			my $entry = Net::Google::Calendar::Entry->new();
			$entry->title($title);
			$entry->content("$films{$title}{description}");
			$entry->location('Art Gallery Of NSW');
			$entry->transparency('transparent');
			$entry->status('confirmed');
			$entry->when($start, $end);

			$cal->add_entry($entry);
		}
	}

}



# Print function - use for debugging
# Easier to see key parts than Data Dumper
sub print_films {

	#print "$film_series\n";

	foreach my $title (keys %films) {
		print "$title\n";
		
		foreach my $time (keys $films{$title}{'time'}) {
			print "$time\n";
		}
		#print "$films{$title}{description}\n\n";
	}
}

