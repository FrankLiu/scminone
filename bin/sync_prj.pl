#!/usr/bin/perl
## .SS Author
## fcgd46@motorolasolutions.com create for sync the prj files between HZ and AH machines
use Net::FTP;

# the enviroment variable
my $AH_PRJ_DIR="/mot/proj/wibb_bts/cmbp/prod/cm-policy/config/WIBB_BTS_projects";
my $HZ_PRJ_DIR="/usr/prod/vobstore104/cmbp/WIMAX/cm-policy/config/WIBB_BTS_projects";
my $AH_SERVER="isdlinux4.americas.nsn-net.net";
my $AH_FTP_USER="apbld";
my $AH_FTP_PASSWD="Bc-j!jp";
my $FILE_FILTER="*.prj";
my @remote_file_list=();
my @local_file_list=();
my @difference=();

sub GetRemoteFileList()
{
  local $ftp = Net::FTP->new($AH_SERVER) or die "Could not connect: $AH_SERVER\n";
  $ftp->login($AH_FTP_USER,$AH_FTP_PASSWD) or die "Could not login.\n";
  $ftp->cwd($AH_PRJ_DIR);
  local $filter = "-1at $FILE_FILTER";
  @remote_file_list = $ftp->ls($filter);
#  foreach $element (@remote_file_list){
#    print "$element \n";
#  }
  print "Remote site file number ";
  print scalar(@remote_file_list);
  print "\n";
  $ftp->quit();
}

sub GetLocalFileList()
{
        chdir($HZ_PRJ_DIR);
  local @local_file = `ls -1at |grep prj`;
  foreach $local_element (@local_file){
        chomp($local_element);
        push @local_file_list,$local_element;
  }
#  foreach $element (@local_file_list){
#   print "$element \n";
#  }
  print "Local site file number ";
  print scalar(@local_file_list);
  print scalar(@local_file_list);
  print "\n";
}

sub diff{
  local $exist_flag = 0;
  foreach $remote_element (@remote_file_list) {

          foreach $local_element (@local_file_list) {

              if ($remote_element eq $local_element){
                  $exist_flag=1;
                  next;
                }
          }
          if ($exist_flag == 0){
            push @difference, $remote_element;
          }
          else{
                $exist_flag =0;
          }
  }
  foreach $need_load (@difference){
    print "Need download $need_load \n";
  }
}

sub GetFile{
        chdir($HZ_PRJ_DIR);
  local $ftp = Net::FTP->new($AH_SERVER) or die "Could not connect: $AH_SERVER\n";
  $ftp->login($AH_FTP_USER,$AH_FTP_PASSWD) or die "Could not login.\n";
  $ftp->cwd($AH_PRJ_DIR);
  foreach $element (@difference){
     $ftp->get($element,$element) or die "Could not get remotefile:$remotefile\n";
  }
  $ftp->quit();
}

#---------------------------------
# MAIN PART
#---------------------------------
$localtime = localtime;
print "****$localtime****\n";

GetRemoteFileList();
GetLocalFileList();
diff();

my $differentnum=@difference;

if ( $differentnum > 0 ){
  GetFile();
}else{
  print "Nothing need to download \n";
}
