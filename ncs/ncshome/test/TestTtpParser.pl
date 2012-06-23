#!/usr/bin/perl -w

use ncs::TtpParser;

my $ttpParser = ncs::TtpParser->new();
$ttpParser->setTtpFile('CoSim.ttp');
$ttpParser->parse();
print ">>>>>>>>>>>>>>>>>all values in ttp file\n";
foreach $val_name (keys %{$ttpParser->{'values'}}){
	print "$val_name : ";
	my $val = $ttpParser->{'values'}->{$val_name};
	$val = join("\n", @$val);
	print "$val\n";
}
print ">>>>>>>>>>>>>>>>>\n";

print ">>>>>>>>>>>>>>>>>file_ref in ttp file\n";
my $file_ref = $ttpParser->getValue('file_ref');
print "$file_ref\n";
print ">>>>>>>>>>>>>>>>>\n";

print ">>>>>>>>>>>>>>>>>ttcns in ttp file\n";
my @ttcns = $ttpParser->getTtcns();
$ttcns = join("\n", @ttcns);
print "$ttcns\n";
print ">>>>>>>>>>>>>>>>>\n";

my $root_module = $ttpParser->getRootModule();
print "root module: $root_module\n";

my $makefile = $ttpParser->getMakefile();
print "makefile: $makefile\n";

my $outputDir = $ttpParser->getOutputDirectory();
print "outputDir: $outputDir\n";
