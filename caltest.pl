#!/usr/bin/perl

#use strict;
use warnings;
use Net::Google::Calendar;

die "Usage: $0 password\n" if !@ARGV;

my $cal_url = "https://www.google.com/calendar/feeds/sgidcsi1fo1j3r4dukkj9sksno%40group.calendar.google.com/public/basic";

my $username = 'nswartfilms';
my $password = $ARGV[0];

my $cal = Net::Google::Calendar->new( url => $cal_url);
$cal->login($username, $password);


my $title = 'test2';

my $entry = Net::Google::Calendar::Entry->new();
$entry->title($title);
$entry->content("My content");
$entry->location('NSW Art Gallery');
$entry->transparency('transparent');
$entry->status('confirmed');
$entry->when(DateTime->now, DateTime->now() + DateTime::Duration->new( hours => 6 ) );

$cal->add_entry($entry);