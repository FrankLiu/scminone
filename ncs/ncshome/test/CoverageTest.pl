use ncs::Common;
#############################################################
################# merge coverage logs to one
sub merge_coverage_log
{
	print("begin to parse the two coverage file and merge them\n");
	my ($firstName,$secondName,$newName) = @_;
	print(" $firstName + $secondName = $newName \n");
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
			#print("the line left untouch for the 1st reason: $line1\n");
            print newFile "$line1";
        }
        else
        {
            if ($line1 =~ /(\s*)(\d+)(.*)/)
            {
                #now get the sum of the two numbers
                #print("the first number is: $2\n");
                $firstNumber = $2;
                
                $line2 =~ /(\s*)(\d+)(.*)/;
                $secondNumber =$2;
                #print("the second number is: $2\n");
                
                $thirdNumber = $firstNumber+$secondNumber;
				#print("the third number is: $thirdNumber\n");
                $line1 =~ s/(\s*)(\d+)(.*)/$1$thirdNumber$3/g;
                #print("$line1\n");
                print newFile "$line1";
            }
            else
            {
                #leave it in the new file
                #print("the line left untouch for the 2nd reason: $line1\n");
                print newFile "$line1";
            }
        }
    }
    
    close(firstFile);
    close(secondFile);
    close(newFile);
}

sub merge_coverage_logs
{
	print("begin to merge all coverage logs for label: $latest_project_label\n");
	my ($coverage_log_dir,$coverage_full_log) = @_;
	chdir($coverage_log_dir);
	my @cov_logs = ();
	opendir(COV_LOG_DIR, $coverage_log_dir) or die("cannot open dir: $coverage_log_dir");
	my @logs = readdir(COV_LOG_DIR);
	#filter the log
	foreach (@logs){
		if($_ =~ /Coverage_\d+/){
			print($_."\n");
			push(@cov_logs,$_);
		}
	}
	$coverage_full_log = "Cov_full.log" if(!defined($coverage_full_log));
	&merge_coverage_log($cov_logs[0],$cov_logs[1],$coverage_full_log);
	for(my $i=2,$size=scalar(@cov_logs);$i<$size;$i++){
		my $firstLog = $coverage_full_log;
		my $secondLog = $cov_logs[$i+1];
		my $newLog = "Cov_tmp.log";
		if(-e $secondLog){
			&merge_coverage_log($firstLog,$secondLog,$newLog);
			#store merge result into Cov_full.log
			system("mv $newLog $coverage_full_log");
		}
	}
	closedir(COV_LOG_DIR);
	print("end merge all coverage logs for label: $latest_project_label\n");
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
    print("begin to print the coverage statistics file\n");
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
            print("begin to process package $pkgName\n");
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
            print("begin to process active class $className\n");
            &processActiveClass();             
        }#if find an active class
        
        if ($line =~ /\d\s*Operation\s*(.*)/)
        {
            $opName = $1;
            $skip = 1;
            if ($1 =~ /.*_t0/ || $1 =~ /.*G\b/)  {$ignoreOperation = 1;}
            else {$ignoreOperation = 0;}
            print("begin to process operation $opName\n");                               
            &processOperation();
        }#if find an Operation
        
        if($line =~ /\d\s*Package\s*(.*)/)
        {
            $pkgName = $1;
            print("begin to process package $pkgName\n");
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
                    print("$opName,\:\:$pkgName\:\:$opName,Transitions,$Number,$Covered,$Povered\n");
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
                    print("$opName,\:\:$pkgName\:\:$opName,Statements,$Number,$Covered,$Povered\n");
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
                    print("begin to process operation $opName\n");
                    &processOperation();
                }
                elsif ($line =~ /\d\s*Active class\s*(.*)/)
                {
                    $className = $1;
                    print("begin to process active class $className\n");
                    &processActiveClass();    
                }
                elsif ($line =~ /\d\s*Package\s*(.*)/) 
                {
                    $pkgName = $1;
                    print("begin to process package $pkgName\n");
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
                    print("$className,\:\:$pkgName\:\:$className,Transitions,$Number,$Covered,$Povered\n");
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
                    print("$className,\:\:$pkgName\:\:$className,Statements,$Number,$Covered,$Povered\n");
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
                    print("begin to process operation $opName\n");
                    &processOperation();
                }
                elsif ($line =~ /\d\s*Active class\s*(.*)/)
                {
                    $className = $1;
                    print("begin to process active class $className\n");
                    &processActiveClass();    
                }
                elsif ($line =~ /\d\s*Package\s*(.*)/) 
                {
                    $pkgName = $1;
                    print("begin to process package $pkgName\n");
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

sub statistic_coverage
{
	print("statistic coverate...\n");
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
	print("total number: ${total}, covered number: ${covered}, coverage: ${statistics}\n");
	if (open(FH, ">> $coverage_csv")) {
		print FH ",,,$total,$covered,$statistics\n";
		close(FH);
	}
}

#merge_coverage_logs("/tmp/ncslog/sm5.0/WMX-AP_R5.0_BLD-1.20.01/coverage", "Cov_full.log");
#printCoverage("/tmp/ncslog/sm5.0/WMX-AP_R5.0_BLD-1.20.01/coverage/Cov_full.log", "/tmp/ncslog/sm5.0/WMX-AP_R5.0_BLD-1.20.01/coverage/Cov_full.csv");
statistic_coverage("Coverage_full.csv");
