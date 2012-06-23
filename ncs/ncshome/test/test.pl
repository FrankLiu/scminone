sub check_test_stat
{
    my $filename = shift @_; 
    print("filename=$filename\n");
    my $last_mtime = localtime;
    my $last_size = 0;
    while(1){
        my($dev, $ino, $mode, $nlink, $uid, $gid, $rdev,
            $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat($filename);
        if($mtime eq $last_mtime && $size eq $last_size){
            return 1;
        }
        $last_mtime = $mtime;
        $last_size = $size;
        print("last_mtime=$mtime\n");
        print("last_size=$size\n");
        print("wait 10 seconds for next check...\n");
        sleep(10);
    }
}

sub print_out
{
    my ($first_name, $last_name) = @_;
    print("Hello, $first_name $last_name\n");
}

sub exec_times
{
    my ($times, $sub_name, @sub_params) = @_;
    print("sub_name: $sub_name\n");
    print("sub_params: @sub_params\n");
    print("$sub_name(@sub_params)\n");
    for($count=1; $count<=$times; $count++){
        print("exec_times: $count\n");
        eval("$sub_name(\@sub_params)");
        if($@){
            warn("exec_times error: $@");
        }
    }
}

sub pipe_test
{
    open(LOG4NCS, "<log4ncs.cfg");
    pipe (INPUT, OUTPUT);
    $retval = fork();
    if ($retval != 0) {
      # this is the parent process 
      close (INPUT);
      print ("Enter a line of input:\n");
      $line = <LOG4NCS>;
      print OUTPUT ($line);
    } 
    else {
      # this is the child process
      close (OUTPUT);
      $line = <INPUT>;
      print ($line);
      exit (0);
    }
    close(LOG4NCS);
}

sub int_tet
{
    my $aaa=0;                      #�Լ���������$aaa���и�ֵ
    while($aaa<3){ #����ѭ����
    print"Begin\n"; #��ӡ�ַ�����STDOUT
    sleep(5); #˯�ߺ���������Ϊ5��
    next unless $SIG{INT}=\&demon; #ѡ��ṹ��demon�ӳ���ֵ�����жϺ���
    }
    sub demon{ #demon�ӳ�����
    $aaa++; #�������Լ�
    print"Stop!\n"; #��ӡ�ַ�����STDOUT
    }
    exit 1; #�˳���
}

sub test_ref
{
	my $t = ();
	my $type = ref($t);
	print "$type\n";
}

&test_ref();
#my $file_stat = check_test_stat("log4ncs.log");
#print("file is staiable!!!");

#exec_times(3, "check_test_stat", ("log4ncs.log", "log4ncs.cfg"));
#exec_times(3, "print_out", ("Frank", "Liu"));

#pipe_test();


