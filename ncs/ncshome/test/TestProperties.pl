#!/usr/bin/perl -w

use ncs::Common;
use ncs::Properties;

my $props = ncs::Properties->new();
my $properties = $props->load("ncs_sm.properties");
# my $import = $props->get("ncs.import", "ncs_default.properties");
# if(-e $import){
	#$properties = $props->merge(ncs::Properties->new()->load($import));
	# $properties = $props->merge_with_file($import);
# }
foreach $prop (sort(keys(%$properties))){
   print("$prop = $$properties{$prop}\n");
}
print("==========properties list end================\n");
print("necb_sanity=".$props->get('ncs.test.necb_sanity')."\n");
print("MotoR6own_suite=".$props->get('ncs.test.motor6_suite')."\n");
print("isl.compile_process=".$props->get('ncs.isl.compile_process')."\n");
print("latest project pattern:".$props->get('ncs.prj.latestprj_pattern')."\n");

print "======set runtime value test======\n";
$props->set('test_key.a','test_val');
print("test_key.a=".$props->get('test_key.a')."\n");
print("test_key.b=".$props->get("test_key.b", "test_key.b.default.value")."\n");

print "========parse suite executable=============\n";
for $suite_type ('openr6','rrm','motor6','rrm_motor6'){
	my $test_exec = $props->get("ncs.test.${suite_type}.executable", $props->get("ncs.test.output_file"));
	print("$suite_type executable file is: $test_exec \n");
}

print "=======parse test suite========\n";
sub get_test_suite{
	my ($ori_suite) = @_;
	$ori_suite =~ s/-/../g;
	my @suite = eval($ori_suite);
	return @suite;
};
my $casenum = 0;
my @part_summary = ();
for $part ('part1','part2','part3','part4','part5'){
	my $partcasenum = 0;
	for $st ('openr6','rrm','motor6','rrm_motor6'){
		my $partsuite = $props->get("ncs.test.$part.${st}_suite");
		my @partcases = &get_test_suite($partsuite);
		$casenum+=scalar(@partcases);
		$partcasenum+=scalar(@partcases);
		print("***$part $st suite includes ".scalar(@partcases)." cases***\n");
		print("@partcases\n") if scalar(@partcases) > 0;
	}
	push(@part_summary, "###$part suite includes:".$partcasenum." cases###");
}
print("Test Suite & Case Summary: \n");
foreach (@part_summary){
	print $_."\n";
}
print("total includes $casenum cases");

