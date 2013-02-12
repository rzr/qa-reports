#!/usr/bin/env perl

use strict;
use warnings;

use constant {
	SUITES 		 			=> 1,
	SETS   		 			=> 10,
	CASES_IN_SET 			=> 10,
	MEASUREMENTS_IN_CASE	=> 1
};

use constant RESULTS => [qw(PASS FAIL N/A MEASURED)];

print "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
print "<testresults>\n";

for (my $i = 0; $i < SUITES; $i++)
{
	print "<suite name=\"suite_" . $i . "\">\n";

	for (my $j = 0; $j < SETS; $j++)
	{
		print "<set name=\"set_" . $i . "_" . $j . "\">\n";

		for (my $k = 0; $k < CASES_IN_SET; $k++)
		{	
			print "<case name=\"case_" . $i . "_" . $j . "_" . $k . "\" result=\"" . RESULTS->[int(rand(@{&RESULTS}))] . "\">\n";

			for (my $l = 0; $l < MEASUREMENTS_IN_CASE; $l++)
			{
				print "<measurement name=\"ms_" . $i . "_" . $j . "_" . $k . "_" . $l . "\" unit=\"ms\" value=\"" . int(rand(10)) . "\" target=\"5\" fail=\"2\"/>\n";
			}

			print "</case>\n";
		}

		print "</set>\n";
	}

	print "</suite>\n";
}

print "</testresults>\n";
