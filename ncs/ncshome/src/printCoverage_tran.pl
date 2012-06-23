$Number  = 0;   #total number of each operation or class
$Covered = 0;   #
$Povered = 0;
$classTransition = 1;#as for class, it is a flag to indicate if it is counting transitions
$opTransition = 1;
$ignoreOperation = 0;   #ignore the operation end with G and _t0
$pkgName; 
$className;
$opName;

sub printCoverage()
{
    print "begin to print the coverage statistics file\n";

    my $newName   = "Coverage_total.log";
    my $covName   = "Coverage_statistics_tran.csv";
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
            print "begin to process package $pkgName\n";
            processPackage();
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
            print "begin to process active class $className\n";
            processActiveClass();             
        }#if find an active class
        
        if ($line =~ /\d\s*Operation\s*(.*)/)
        {
            $opName = $1;
            $skip = 1;
            if ($1 =~ /.*_t0/ || $1 =~ /.*G\b/)  {$ignoreOperation = 1;}
            else {$ignoreOperation = 0;}
            print "begin to process operation $opName\n";                               
            processOperation();
        }#if find an Operation
        
        if($line =~ /\d\s*Package\s*(.*)/)
        {
            $pkgName = $1;
            print "begin to process package $pkgName\n";
            processPackage();
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
                    print "$opName,\:\:$pkgName\:\:$opName,Transitions,$Number,$Covered,$Povered\n";
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
                    print "$opName,\:\:$pkgName\:\:$opName,Statements,$Number,$Covered,$Povered\n";
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
                    print "begin to process operation $opName\n";
                    processOperation();
                }
                elsif ($line =~ /\d\s*Active class\s*(.*)/)
                {
                    $className = $1;
                    print "begin to process active class $className\n";
                    processActiveClass();    
                }
                elsif ($line =~ /\d\s*Package\s*(.*)/) 
                {
                    $pkgName = $1;
                    print "begin to process package $pkgName\n";
                    processPackage();    
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
                    print "$className,\:\:$pkgName\:\:$className,Transitions,$Number,$Covered,$Povered\n";
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
                    print "$className,\:\:$pkgName\:\:$className,Statements,$Number,$Covered,$Povered\n";
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
                    print "begin to process operation $opName\n";
                    processOperation();
                }
                elsif ($line =~ /\d\s*Active class\s*(.*)/)
                {
                    $className = $1;
                    print "begin to process active class $className\n";
                    processActiveClass();    
                }
                elsif ($line =~ /\d\s*Package\s*(.*)/) 
                {
                    $pkgName = $1;
                    print "begin to process package $pkgName\n";
                    processPackage();    
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

printCoverage();