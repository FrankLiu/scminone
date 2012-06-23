sub mergeCoverage()
{
    print "\nbegin to parse the two coverage file and merge them\n";

    my $firstName = "Coverage_full.log";
    my $secondName= "Coverage_part.log";
    my $newName   = "Coverage_new.log";
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
            print "\nthe line left untouch for the 1st reason: $line1\n";
            print newFile "$line1";
        }
        else
        {
            if ($line1 =~ /(\s*)(\d+)(.*)/)
            {
                #now get the sum of the two numbers
                print "\nthe first number is: $2\n";
                $firstNumber = $2;
                
                $line2 =~ /(\s*)(\d+)(.*)/;
                $secondNumber =$2;
                print "\nthe second number is: $2\n";
                
                $thirdNumber = $firstNumber+$secondNumber;
                print "\nthe third number is: $thirdNumber\n";
                $line1 =~ s/(\s*)(\d+)(.*)/$1$thirdNumber$3/g;
                print "\n$line1\n";
                print newFile "$line1";
            }
            else
            {
                #leave it in the new file
                print "\nthe line left untouch for the 2nd reason: $line1\n";
                print newFile "$line1";
            }
        }
    }
    
    close(firstFile);
    close(secondFile);
    close(newFile);
}

mergeCoverage();