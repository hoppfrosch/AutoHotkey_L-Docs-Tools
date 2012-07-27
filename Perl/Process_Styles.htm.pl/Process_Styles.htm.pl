#perl

# Analysis and Manipulation of file "misc/styles.htm"
# First purpose:
#  * Reads "WinUser.h" and "CommCtrl.h" and extracts all defined styles that match a certain pattern (files taken von WinSDK 7.01)
#  * Reads all documented Styles from "misc/styles.htm"
#  * Diffs both list and prints a result list containing all undocumented styles from "misc/styles.htm" which are defined in windows header
# Second purpose:
#  * Generate anchors (Attribute id) for all styles defined in "misc/styles.htm"
#  * Generate links to those anchors within page ""misc/styles.htm""
#
# Author: hoppfrosch (hoppfrosch at googlemail dot com) - 20120726

use strict;
use warnings;
use File::Copy;
use FindBin qw($Bin);

# Which file to analyse/manipulate
my $docBaseBath = $Bin."\\..\\..\\..\\AutoHotkey_L-Docs\\docs";
my $fileInp = $docBaseBath."\\misc\\Styles.htm";
# Where to store the unmanipulated original file
my $fileBackup = $docBaseBath."\\misc\\Styles_orig.htm";

# Prefixes of styles to be considered by this script
my $consideredStylePrefixes = "WS|SS|ES|UDS|BS|CBS|LBS|LVS|LVS_EX|TVS|DTS|MCS|TBS|PBS|TCS|SBARS";

my $FH;
my @lines;
my @lines_tmp;

# Read windows headers and put all lines from all files into one single perl array
foreach my $currFile ("WinUser.h", "CommCtrl.h") {
  open $FH, "<", $currFile;
  @lines_tmp = <$FH>;
  close $FH;
  push @lines, @lines_tmp;
}

# Extract all relevant constants from windows header to reference hash
my $reference;
foreach my $currLine (@lines) {
  if ($currLine =~ m{#define\s+(($consideredStylePrefixes)_[A-Z]+)\s+(0x\d+)?}) {
    $reference->{$2}->{$1} = $3;
  }
}


# Read styles.htm
open $FH, "<", $fileInp;
@lines = <$FH>;
close $FH;

# Extracted all described styles  (i.e styles who do have an own table row) to "described" hash
my $described;
for my $index (0 .. $#lines) {
  if ($index > 0) {
    # Previous line has to be a table row definition
    if ($lines[$index-1] =~ m{\<tr .*\>}i) {
      # Patterns for Styles to be extracted
      if ($lines[$index] =~ m{\>\s*(($consideredStylePrefixes)_[A-Z]+)\s*\<}) {
        my $prefix = $2;
        my $key = $1;
        my $value = $3;
        $described->{$prefix}->{$key} = $value;
        # Generate anchors (Attribute id) for all styles defined in "misc/styles.htm"
        if ($lines[$index-1] !~ m{ id=}) {
          $lines[$index-1] =~ s{(\<tr)(.*)}{$1 id=\"$key\"$2};
        }
        # Remove trailing whitespaces 
        $lines[$index] =~ s{\s+\<\/td\>}{\<\/td\>};
        }
    }
  }
}

# Transform quoted styles to links to anchors created above ... (Linkify)
for my $index (0 .. $#lines) {
  foreach my $key1 (keys(%{$described})) {
    foreach my $key2 (keys(%{$described->{$key1}})) {
      # Try to find all style keywords on the page ...
      if ($lines[$index] =~ m{[\>\s]+$key2[\n\s,\<\.:]{1}}) {
        # But not the ones which are already anchors! 2 Occurences should not be linkified: First the id-contents and second the contents of table column listing he style ....
        if ($lines[$index] !~ m{id=\"$key2\"|\>$key2\<}) {
          # Generate links to anchors anchors created above
          $lines[$index] =~ s{$key2}{\<a href=\"#$key2\"\>$key2\<\/a\>};
          my $i = 0;
        }
      }
    }
  }
}
  
# Print manipulated "misc/styles.htm" to file again!
move($fileInp, $fileBackup);
open $FH, ">", $fileInp;
print $FH @lines;
close $FH;

# Compare styles defined in windows header with styles defined in "misc/styles.htm"
# Generate difference list (list with styles missing on page "misc/styles.htm")
my @missing;
foreach my $key1 (keys(%{$reference})) {
  foreach my $key2 (keys(%{$reference->{$key1}})) {
    if (!exists($described->{$key1}->{$key2})) {
      push @missing, $key2;
    }
  }
}

# Print out the difference list
foreach (sort(@missing)) {
  print $_."\n";
}
1;