#!/usr/bin/perl -w

#27479	11017	40.09243422
use ncs::Common;

sub export_coverage
{
    $log->info("export coverage...");
	#print coverage
	my $print_coverage = $props->get("ncs.option.print_coverage", 0);
	$log->debug("enable_print_coverage: $print_coverage");
    if(!$print_coverage){#disabled print coverage
        $log->warn("print coverage is disabled, NCS will ignore the coverage log!");
        return;
    }
    #print coverage enabled
	my $cov_log = $props->get('ncs.coverage.log');
	&merge_coverage_dir("$log_dir/$latest_project_label/coverage", "$store_dir/$latest_project_label/$cov_log");
	$log->info("merged runtime coverage log into one: $store_dir/$latest_project_label/$cov_log");
	my $enable_sendmail = $props->get("ncs.option.enable_sendmail", "0");
	return if(!$enable_sendmail);
	#only main server need to merge all parts
	my $merged_cov_log = $props->get('ncs.coverage.merged', "Coverage_full.log");
	if(&need_merge_coverages()){
        &merge_coverages();
    }
    else{
        system("mv $cov_log $store_dir/$latest_project_label/$merged_cov_log");
    }
    $log->info("merged coverage logs to $store_dir/$latest_project_label/$merged_cov_log");
    my $cov_report = $props->get("ncs.coverage.store", "Coverage_full.csv");
	&printCoverage("$store_dir/$latest_project_label/$merged_cov_log", "$store_dir/$latest_project_label/$cov_report");
    $log->info("exported coverage as $store_dir/$latest_project_label/$cov_report");
	sleep(5);
	&statistic_coverage("$store_dir/$latest_project_label/$cov_report");
}

sub statistic_coverage
{
	$log->info("statistic coverate...");
	my ($coverage_csv) = @_;
	my @lines = &read_as_array($coverage_csv);
	my $len = scalar(@lines);
	my $total = $covered = 0;
	for $line (@lines[1..$len]){
		chomp($line); #remove \n
		if($line =~ /^$/){ #blank line
            next;  
        }
		my @items = split(',', $line);
		$total += int($items[3]);
		$covered += int($items[4]);
	}
	my $statistics = sprintf("%.2f", $covered/$total*100);
	$log->info("total number: ${total}, covered number: ${covered}, coverage: ${statistics}");
	if(open(FH, ">>$coverage_csv")){
		print FH ",,,$total,$covered,$statistics";
		close(FH);
	}
}

sub need_merge_coverages
{
	$log->info("check if need merge coverages...");
	my @cov_depends = split(/[\s,;]+/, $props->get("ncs.coverage.depends"));
	if(scalar(@cov_depends) <= 0){
		$log->warn("No coverages depends on current script!");
		$log->warn("No coverages needs to merge!!");
		return $FALSE;
	}
	return $TRUE;
}

sub merge_coverages
{
    $log->info("start to merge coverages...");
	my @cov_depends = split(/[\s,;]+/, $props->get("ncs.coverage.depends"));
    $log->debug("coverages depends: @cov_depends");
	my $cov_log = $props->get('ncs.coverage.log');
	my $merged_cov_log = $props->get('ncs.coverage.merged', "Coverage_full.log");
	#waiting for coverages synchronization
	&sync_coverages();
    #merging coverage logs
    chdir("$store_dir/$latest_project_label");
    splice (@cov_depends, 0, 0, $cov_log);
    &merge_coverage_logs($merged_cov_log, @cov_depends);
    $log->info("merged coverages: @cov_depends");
}

sub sync_coverages
{
	$log->info("start to synchronize emails...");
	my $sync_coverages_option = $props->get('ncs.option.sync_coverages', 'locally');
	$log->info("sync coverages with option: $sync_coverages_option");
	local @cov_depends = split(/[\s,;]+/, $props->get("ncs.coverage.depends"));
	sub sync_coverages_locally{
		#sync coverages with server sync-up service
		foreach $cov (@cov_depends){
			$log->info("check if coverage log [$cov] exists?");
			while(!(-e "$store_dir/$latest_project_label/$cov")){
				#wait for other NCS scripts finished
				$log->info("sleep for 60 seconds for check $cov...");
				sleep(60);
				#check ncs timeout before go to next case
				&check_ncstimeout();
			}
			$log->info("found coverage log [$cov] exists!");
		}
	};
	sub sync_coverages_ftply{
		#sync mails with ftp service
		my $sync_dir = $props->get("ncs.ftp.sync_coverages_dir");
		foreach $cov (@cov_depends){
			$log->info("check if coverage log [$cov] exists?");
			my $ftp = &initialize_ftp();
			while(!($ftp->nlist("$sync_dir/$latest_project_label/$cov"))){
				#wait for other NCS scripts finished
				$log->info("sleep for 180 seconds for check $cov...");
				sleep(180);
			}
			$ftp->get("$sync_dir/$latest_project_label/$cov", "$store_dir/$latest_project_label/$cov");
			$ftp->quit();
			$log->info("found coverage log [$cov] exists!");
		}
	};
	sub sync_coverages_mailly{
		#sync coverages with mail service
		#TODO:
	};
	
	$log->info("waiting for other Coverage scripts to finish....");
	$log->info("waiting for depends coverages: @cov_depends");
	eval{eval("sync_coverages_".$sync_coverages_option);};
	if($@){
		$log->error("sync coverages error: $@");
		&terminate_ncs();
		exit 1;
	}
    $log->info("all of Coverage scripts finished now.");
	$log->info("finished synchronize coverages.");
	sleep(10);
}
#############################################################
################# merge coverage logs to one
sub merge_coverage_log
{
	$log->info("begin to parse the two coverage file and merge them");
	my ($firstName,$secondName,$newName) = @_;
    open (firstFile, "<$firstName") or die "\n Cannot open $firstName\n";
    open (secondFile, "<$secondName") or die "\n Cannot open $secondName\n";
    open (newFile, ">$newName") or die "\n Cannot create $newName\n";
    while(defined($firstLine = <firstFile>) && defined($secondLine = <secondFile>))  
    {
        $line1 = $firstLine;
        $line2 = $secondLine;
        
        if (($line1 =~ /\d\s*System/) || ($line1 =~ /\d\s*Package/) 
            || ($line1 =~ /\d\s*Active/) ||($line1 =~ /\d\s*Operation/))
        {
            #leave it in the new file
			#$log->debug("the line left untouch for the 1st reason: $line1");
            print newFile "$line1";
        }
        else
        {
            if ($line1 =~ /(\s*)(\d+)(.*)/)
            {
                #now get the sum of the two numbers
                #$log->debug("the first number is: $2");
                $firstNumber = $2;
                
                $line2 =~ /(\s*)(\d+)(.*)/;
                $secondNumber =$2;
                #$log->debug("the second number is: $2");
                
                $thirdNumber = $firstNumber+$secondNumber;
				#$log->debug("the third number is: $thirdNumber");
                $line1 =~ s/(\s*)(\d+)(.*)/$1$thirdNumber$3/g;
                #$log->debug("$line1");
                print newFile "$line1";
            }
            else
            {
                #leave it in the new file
                #$log->debug("the line left untouch for the 2nd reason: $line1");
                print newFile "$line1";
            }
        }
    }
    
    close(firstFile);
    close(secondFile);
    close(newFile);
}

sub merge_coverage_dir
{
	$log->info("begin to merge all coverage logs for label: $latest_project_label");
	my ($coverage_log_dir,$coverage_full_log) = @_;
	chdir($coverage_log_dir);
	my @cov_logs = ();
	opendir(COV_LOG_DIR, $coverage_log_dir) or die("cannot open dir: $coverage_log_dir");
	my @logs = readdir(COV_LOG_DIR);
	#filter the log
	foreach (@logs){
		if($_ =~ /Coverage_\d+/){
			#print($_."\n");
			push(@cov_logs,$_);
		}
	}
    closedir(COV_LOG_DIR);
	$coverage_full_log = "Cov_full.log" if(!defined($coverage_full_log));
	&merge_coverage_logs($coverage_full_log, @cov_logs);
	$log->info("end merge all coverage logs for label: $latest_project_label");
}

sub merge_coverage_logs
{
    my ($coverage_full_log,@coverage_logs) = @_;
    $log->info("Merge coverage logs: @coverage_logs");
    my $size = scalar(@coverage_logs);
    if($size == 1){
        system("mv $coverage_logs[0] $coverage_full_log");
    }
    elsif($size == 2){
        &merge_coverage_log($coverage_logs[0],$coverage_logs[1],$coverage_full_log);
    }
    else{
        &merge_coverage_log($coverage_logs[0],$coverage_logs[1],$coverage_full_log);
        for(my $i=2;$i<$size;$i++){
            my $firstLog = $coverage_full_log;
            my $secondLog = $coverage_logs[$i+1];
            my $newLog = "Cov_tmp.log";
            if(-e $secondLog){
                $log->debug(" $firstLog + $secondLog = $newLog \n");
                &merge_coverage_log($firstLog,$secondLog,$newLog);
                #store merge result into Cov_full.log
                system("mv $newLog $coverage_full_log");
            }
        }
    }
    $log->info("Finished merging coverage logs: @coverage_logs");
}

##########################################################################
################ print coverage table to a csv file
################
my $Number  = 0;   #total number of each operation or class
my $Covered = 0;   #
my $Povered = 0;
my $classTransition = 1;#as for class, it is a flag to indicate if it is counting transitions
my $opTransition = 1;
my $ignoreOperation = 0;   #ignore the operation end with G and _t0
my $pkgName; 
my $className;
my $opName;

sub printCoverage
{
    $log->info("begin to print the coverage statistics file");
	my ($newName,$covName) = @_;
    #my $newName   = "Coverage_total.log";
    #my $covName   = "Coverage_statistics_tran.csv";
    open (newFile, "<$newName") or die "\n Cannot open $newName\n";
    open (covFile, ">$covName") or die "\n Cannot create $covName\n";

    #print the table header
    print covFile "Operation,Path,Kind,Number,Covered,Povered\n";
    
    #find the 1st line to parse
    while(defined($line = <newFile>))
    {
        if (index ($line, "COVERAGE TABLE DETAILS") ne -1){last;}
    }
    
    while(defined($temp = <newFile>))  
    {
        $line = $temp;
        chop($line);
        
        if($line =~ /\d\s*Package\s*(.*)/)
        {
            $pkgName = $1;
            $log->info("begin to process package $pkgName");
            &processPackage();
        }
    }
    
    close(newFile);
    close(covFile);
}

sub processPackage()
{
    while(defined($temp = <newFile>))  
    {
        $line = $temp;
        chop($line);
         
        if ($line =~ /\d\s*Active class\s*(.*)/)
        {
            $className = $1;
            $log->debug("begin to process active class $className");
            &processActiveClass();             
        }#if find an active class
        
        if ($line =~ /\d\s*Operation\s*(.*)/)
        {
            $opName = $1;
            $skip = 1;
            if ($1 =~ /.*_t0/ || $1 =~ /.*G\b/)  {$ignoreOperation = 1;}
            else {$ignoreOperation = 0;}
            $log->info("begin to process operation $opName");                               
            &processOperation();
        }#if find an Operation
        
        if($line =~ /\d\s*Package\s*(.*)/)
        {
            $pkgName = $1;
            $log->info("begin to process package $pkgName");
            &processPackage();
        }#if find a package        
    }    
}

sub processOperation()
{
    while(defined($temp = <newFile>)) 
    {
        $line = $temp;
        chop($line);
        
        if (($line =~ /\d\s*Package\s*(.*)/) || (index ($line, "----") ne -1)
            || ($line =~ /\d\s*Active class\s*(.*)/) ||($line =~ /\d\s*Operation\s*(.*)/))
        {
            if($opTransition == 1  && (index ($line, "----") ne -1))
            {
                if ($Number != 0)
                {
                    $Povered = $Covered/$Number*100;
                    $log->info("$opName,\:\:$pkgName\:\:$opName,Transitions,$Number,$Covered,$Povered");
                    print covFile "$opName,\:\:$pkgName\:\:$opName,Transitions,$Number,$Covered,$Povered\n";
                }
                $Number = 0;
                $Covered= 0; 
                $opTransition = 0;                
            }
            else
            {
                if ($Number != 0)
                {
                    $Povered = $Covered/$Number*100;
                    $log->info("$opName,\:\:$pkgName\:\:$opName,Statements,$Number,$Covered,$Povered");
                    print covFile "$opName,\:\:$pkgName\:\:$opName,Statements,$Number,$Covered,$Povered\n";
                }
                $Number = 0;
                $Covered= 0; 
                $opTransition = 1;
                
                if ($line =~ /\d\s*Operation\s*(.*)/) 
                {
                    $opName = $1;
                    $skip =1;
                    if ($1 =~ /.*_t0/ || $1 =~ /.*G\b/)  {$ignoreOperation = 1;}
                    else {$ignoreOperation = 0;}
                    $log->info("begin to process operation $opName");
                    &processOperation();
                }
                elsif ($line =~ /\d\s*Active class\s*(.*)/)
                {
                    $className = $1;
                    $log->info("begin to process active class $className");
                    &processActiveClass();    
                }
                elsif ($line =~ /\d\s*Package\s*(.*)/) 
                {
                    $pkgName = $1;
                    $log->info("begin to process package $pkgName");
                    &processPackage();    
                }
            }
        }
        elsif ($line =~ /(\s*)(\d+)(.*)/ && $ignoreOperation == 0)
        {
            $Number++;
            if ($2 != 0) {$Covered++;} 
        }
    }    
}

sub processActiveClass()
{
    while(defined($temp = <newFile>)) 
    {
        $line = $temp;
        chop($line); 
                
        if (($line =~ /\d\s*Package/) || (index ($line, "----") ne -1)
            || ($line =~ /\d\s*Active/) ||($line =~ /\d\s*Operation/))
        {
            if($classTransition == 1  && (index ($line, "----") ne -1))
            {
                if ($Number != 0)
                {
                    $Povered = $Covered/$Number*100;
                    $log->info("$className,\:\:$pkgName\:\:$className,Transitions,$Number,$Covered,$Povered");
                    print covFile "$className,\:\:$pkgName\:\:$className,Transitions,$Number,$Covered,$Povered\n";
                }
                $Number = 0;
                $Covered= 0;  
                $classTransition = 0;
            }
            else
            {
                if  ($Number != 0)
                {
                    $Povered = $Covered/$Number*100;                
                    $log->info("$className,\:\:$pkgName\:\:$className,Statements,$Number,$Covered,$Povered");
                    print covFile "$className,\:\:$pkgName\:\:$className,Statements,$Number,$Covered,$Povered\n";
                }
                $Number = 0;
                $Covered= 0;                                
                $classTransition = 1;
                
                if ($line =~ /\d\s*Operation\s*(.*)/) 
                {
                    $opName = $1;
                    $skip =1;
                    if ($1 =~ /.*_t0/ || $1 =~ /.*G\b/)  {$ignoreOperation = 1;}
                    else {$ignoreOperation = 0;}  
                    $log->info("begin to process operation $opName");
                    &processOperation();
                }
                elsif ($line =~ /\d\s*Active class\s*(.*)/)
                {
                    $className = $1;
                    $log->info("begin to process active class $className");
                    &processActiveClass();    
                }
                elsif ($line =~ /\d\s*Package\s*(.*)/) 
                {
                    $pkgName = $1;
                    $log->info("begin to process package $pkgName");
                    &processPackage();    
                }                
            }
        }
        elsif ($line =~ /(\s*)(\d+)(.*)/)
        {
            $Number++;
            if ($2 != 0) {$Covered++;} 
        }
                            
    }     
}


1;
__END__
