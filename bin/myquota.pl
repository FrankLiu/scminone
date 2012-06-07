#!/apps/public/bin/perl -U
##!/usr/bin/perl -U
##!/usr/bin/perl -w
# When testing, use -w. The -U is needed to use the setgid
# so the script is unreadable by all, but executable with
# the setgid ksh frontend script.
#
# -----------------------------------------------------------------------------
#                     S C R I P T   S P E C I F I C A T I O N
#                          COPYRIGHT 2004 MOTOROLA INC.
# -----------------------------------------------------------------------------
#
# NAME
#       myquota     -   Lists a user's quota for the selected machine.
#                           
#
# REVISION HISTORY
#       2004 Feb 24 Curt Danielsen      original
#       2004 Mar 18 Curt Danielsen      Updated to work with new server.
#       2004 Jul 21 Curt Danielsen      Updated server list.
#       2004 Jul 29 Curt Danielsen      Changed rsync host.
#       2004 Sep 13 Curt Danielsen      Allows view or home option and have
#                                       script "find" your home or view storage.
#	2005 Sep 14 Amol Dalvi		Added wsdd2105 as a validviewserver
#	2006 Mar 25 Curt Danielsen	Remove zc2002 and wsdd2101 as view servers
#					and wsdd2301 as home server.
#	2007 May 22 Curt Danielsen	Updated to work in Networks system.
#	2007 Jun 16 Curt Danielsen	Not removing a temporary "dirfile".
#	2007 Jun 25 Curt Danielsen	Add unlinks to address ksh set -o noclobber
#
# USAGE
#       myquota [help|view|<server>]
#
#
# DESCRIPTION
#       This script was originally designed to list a user's quota on
#       a view server. It can be used to list a user's quota on any
#       server, so it could be extended to other types of server.
#
#       The script verifies the server is on an internal list,
#       then sets up a TCP socket connection to the server, requesting
#       it provide the quota results for the current user.
#
# PARAMETERS
#
#       option          -   Either help, home, view or server name
#
# RETURN CODE
#       SUCCESS     Sucessful return code.
#                   Error code returned to the calling script/shell.
#                   
#
# ******************************** MAIN SCRIPT ********************************
#
# ---------------------------- LIBRARY DECLARATIONS ---------------------------
#
require 5.002;
use sigtrap;
use Socket;
#
# ---------------------------- CONSTANT DECLARATION ---------------------------
#
# The only difference between CONSTANT and VARIABLE declarations is that
# CONSTANTS should never be changed (obviously).
# <var_type>c_<var_name> = <value>;
$SUCCESS = 0;
$HELP = 1;
$USAGE = 2;
$NOROOT = 3;
$NOHOMEQUOTA = 4;
$NOVIEWSTORAGE = 5;
$MULTIPLELOCATIONS = 6;
$CALLSERVERFAILED = 7;
#
@validservers = (   "il27cndview01",
                    "il27view02",
                    "il27view03",
                 );

@validviewservers = ( "il27cndview01",
                      "il27view02",
                      "il27view03",
                     );   
$SERVERDOMAIN = "americas.nsn-net.net";
#
$EUID = $>;
# $REALUID = $<;
#
$REMOTEPORT = 1371;
#
# Set boolean values.
#
$TRUE = 1;
$FALSE = 0;
#
#
# ---------------------------- VARIABLE DECLARATION ---------------------------
#
# <variable> = <value>;
$exit_code = $SUCCESS;
#
#
$cmd = "";
$server = "";
$viewserver = "";
$viewpath = "";
#
$found = $FALSE;
#
# ---------------------------- PARAMETER DECLARATION --------------------------
#
#   WHAT:   Check parameter input.
#   WHY:    We have a certain expectation for information.
#
if ( $exit_code == $SUCCESS ) {
    if ($#ARGV < 0 || $#ARGV > 0) {
        print "Usage: myquota [help|view|<server>]\n";
        $exit_code = $USAGE;
    }
    else {
        $cmd = $ARGV[0];
        SWITCH: {
            if ( "$cmd" eq "help" ) {
                print "myquota [help | view | <server>]\n";
                print "  help: This option.\n";
                print "  view: List quota for your view storage.\n";
                print "  <server>: List any quota you have on this server.\n";
                print "myquota is used to list your current quota and\n";
                print "usage on the type of server requested (home or view),\n";
                print "or for a specific server. If an invalid server is listed,\n";
                print "the script displays the valid list.\n";
                $exit_code = $HELP;
            last SWITCH;
            }
            if ( "$cmd" eq "view" ) {
                $exit_code = $SUCCESS;
            last SWITCH;
            }
            #   WHAT:   Assume the "cmd" is a viewserver. Look through the list
            #           of valid view servers and ensure it exists.
            #   WHY:    Command doesn't work unless it's for one of the view
            #           servers.
            #
            foreach $server (@validservers) {
            if ( $server eq $cmd ) {
                $found = $TRUE;
                $viewserver = $server;
                }
            }
            if ( ! $found ) {
                print "Server: $cmd not found.\n";
                print "Valid list of servers are:\n";
                foreach $server (@validservers) {
                    print "$server\n";
                }
                print "Usage: myquota [help|view|<server>]\n";
                $exit_code = $USAGE;
            }
        }
    }
}
#
# ---------------------------- SUBROUTINE DECLARATION --------------------------
#
#   INT call_server (vobserver, port)
#
sub call_server ($$);
#
#
#   STRING socketreadln (PTR SOCKET);
#
sub socketreadln (*);
#
#
#   STRING get_server (STRING global_view_storage_path)
#
sub get_server ($);
#
#
#   STRING locate_view (PTR viewserver, serverdomain)
#
sub locate_view (\@$);
#
#
#   BOOLEAN connection_verified (PTR SOCKET)
#
sub connection_verified (*);
#
#
# ---------------------------------- SCRIPT -----------------------------------
#
#   WHAT:   If exit_code is success, then we can proceed.
#   WHY:    We have a valid request. Call the right server and
#           pass it on, or process the home or view request.
#
if ( $exit_code == $SUCCESS ) {
    #   WHAT:   Check to see if Root is requesting quota access.
    #   WHY:    Root should never be requesting this info. This
    #           utility is for users. If root is requesting, this
    #           is from the "outside". Don't allow it!
    if ( $EUID == 0 ) {
        $exit_code = $NOROOT;
        print "ERROR: Root not allowed to query for quotas.\n";
        print "Usage: myquota [help|home|view|<server>]\n";
    }
    else {
        SWITCH: {
            if ( "$cmd" eq "view" ) {
                $viewpath = locate_view (@validviewservers, $SERVERDOMAIN);
                $viewserver = get_server($viewpath);
                if ( $viewpath eq "" ) {
                    $exit_code = $NOVIEWSTORAGE;
                }
                if ( $viewpath eq "MORETHANONE" ) {
                    $exit_code = $MULTIPLELOCATIONS;
                }
            last SWITCH;
            };
        }
        if ( $exit_code == $SUCCESS ) {
            $exit_code = call_server ($viewserver, $REMOTEPORT);
        }
    }
}
exit($exit_code);
#
#
# ************************ SUBROUTINE DEFINITION *****************************
#
# NAME
#       socketreadln    -   Read a line, looking for \n to terminate EOL.
#
# USAGE
#       STRING socketreadln socket
#
#       socket          -   Socket to read from.
#       
#
# DESCRIPTION
#       This subroutine calls RECV, getting one character at a time,
#       looking for \n to note the end of a line. The string is then
#       returned to the calling routine.
#
# RETURNS
#
sub socketreadln (*) {

    #   WHAT:   Declare private variables for the passed in arguements.
    #   WHY:    So it's clear.
    my ($thesocket) = @_;

    #   Private Variable Definitions.
    #
    my ($char, $theline);

    $theline = "";
    recv $thesocket, $char, 1, 0x40;
    # MSG_WAITALL
    while ("$char" ne "\n") {
        $theline = $theline . $char;
        recv $thesocket, $char, 1, 0x40;
    }
    return ($theline);
}

#
# ************************ SUBROUTINE DEFINITION *****************************
#
# NAME
#       get_server  -   Returns the server where the view is located.
#
# USAGE
#       STRING get_server (global_view_stoage_path)
#
#
# DESCRIPTION
#       This routine takes the global view storage path,
#       which is of the form /net/<server>.<domain>/<localpath>
#       and returns the <server>.<domain> portion.
#
# RETURNS
#       <server>.<domain> where the view storage is located.
#
sub get_server ($) {

    #   WHAT:   Declare private variables for the passed in arguements.
    #   WHY:    So it's clear.
    my ($viewpath) = @_;

    #   Private Variable Definitions.
    #
    my ($VIEWPREFIX, $viewlocation, $TRUE, $FALSE, $SUCCESS, $found, $server);
    my ($returnserver, $return_code, $returnpath, $leftover);

    $SERVERDOMAIN = "americas.nsn-net.net";
    $LOCALVIEWPATH = "/export";

    $viewdir = $viewpath;
    $viewdir =~ s/(.*)\/(.*)/$1/;




    $return_code = system ("/usr/bin/ksh", "-c", "cd $viewdir;(/bin/df -k . | /bin/grep $LOCALVIEWPATH >/tmp/dirfile.$$ 2>/dev/null)");

    open (DIRFILE, "/tmp/dirfile.$$");
    $returnpath = <DIRFILE>;
    chomp ($returnpath);
    ($returnserver, $leftover) = split (':', $returnpath);
    close (DIRFILE);
    unlink "/tmp/dirfile.$$";

    #   WHAT:   Need to eliminate any <host>-<interface> names.
    #   WHY:    Makeview will fail. Need just the hostname. Grr.
    #
    $returnserver =~ s/(.*)-(.*)/$1/g;
    $returnserver = $returnserver . '.' . $SERVERDOMAIN;

    return ($returnserver);
}

# ************************ SUBROUTINE DEFINITION *****************************
#
# NAME
#       locate_view     -   Locate view directory for this user.
#
# USAGE
#       STRING locate_view
#
#
# DESCRIPTION
#       This subroutine returns the view directory for this user.
#       We have two error conditions to detect. One is if the person has
#       no view storage directory. It is possible that accounts exist with
#       no view storage. Could be a remote user who does not need view storage.
#
#       The second condition is if multiple view servers are found.
#       This would happen if an admin created more than one storage
#       location (e.g. moved a storage location and forgot to delete
#       the old one). In this case, we inform the user and direct
#       them to enter a ticket to have this situation addressed.
#
# RETURNS
#       String which is the storage path of the person's view directory.
#       It is the global path. e.g. /mot/ccase/<viewpartition>/<coreid>
#
sub locate_view (\@$) {

    #   WHAT:   Declare private variables for the passed in arguements.
    #   WHY:    So it's clear.
    my ($viewserverlist, $serverdomain) = @_;

    #   Private Variable Definitions.
    #
    my ($VIEWPREFIX, $viewlocation, $TRUE, $FALSE, $SUCCESS, $found, $server);
    my ($returnserver, $returnpath, $netgrp);

    $TRUE = 1;
    $FALSE = 0;
    $SUCCESS = 0;
    $found = $FALSE;

    # $VIEWPREFIX = "/export/vws";
    $VIEWPREFIX = "/export/view";
    $ESCAPEVIEWPREFIX = "\/export\/";
    $GLOBALVIEWPREFIX = "/usr/prod/";
    $acctname = getpwuid ($>);
    # $viewlocation = $VIEWPREFIX . $acctname;
    $returnpath = "";

    #   WHAT:   Find the list of exported partitions on the view server. After that,
    #           we translate by taking the leaf of the exported partition and pre-append
    #           that to the global view prefix, add the suffix of '/*/<coreid>, then cycle
    #           through those on the view server to see if we get a hit. So the global path
    #           will be /mot/ccase/<view_partition>/*/<coreid>
    #   WHY:    Looking for this user's view directory. Need to try them all to find it.
    #

    foreach $server (@{$viewserverlist}) {
        $return_code = system ("/usr/bin/ksh", "-c", "/usr/sbin/showmount -e $server | grep $VIEWPREFIX >/tmp/exportlist.$$ 2>/dev/null");

        open (EXPORTFILE, "/tmp/exportlist.$$");
            while ($line = <EXPORTFILE>) {
                ($viewlocation, $netgrp) = split (' ', $line);
                $viewlocation =~ s/$ESCAPEVIEWPREFIX//;
                $viewlocation = $GLOBALVIEWPREFIX . $viewlocation . '/*/' . $acctname; 
                $return_code = system ("/usr/bin/ksh", "-c", "/bin/ls -d $viewlocation >/tmp/dirpath.$$ 2>/dev/null");
                #   WHAT:   First time, we've found the first path. Found will be false, life is good.
                #           Second time through, found is true, check returnpath. If not MORETHANONE,
                #           this is the original first path we found. Print it. returnpath now set to
                #           MORETHANONE. We don't print the original path found, just subsequent paths.
                #   WHY:    Comes out right on the screen listing all paths found.
                #
                if ( ($return_code / 256) == $SUCCESS ) {
                    if ($found) {
                        if ($returnpath ne "MORETHANONE") {
                            print "ERROR: Multiple view directories: $returnserver\n";
                            print "ERROR: Path: $returnpath\n";
                        }
                        print "ERROR: Multiple view directories: $server\n";
                        open (DIRFILE, "/tmp/dirpath.$$");
                        $returnpath = <DIRFILE>;
                        chomp ($returnpath);
                        close (DIRFILE);
                        print "ERROR: Path: $returnpath\n";
                        $returnpath = "MORETHANONE";
                    }
                    else {
                        open (DIRFILE, "/tmp/dirpath.$$");
                        $returnpath = <DIRFILE>;
                        chomp ($returnpath);
                        close (DIRFILE);
                        $returnserver = $server;
                        $found = $TRUE;
                    }
                }
                unlink "/tmp/dirpath.$$";
            }
        close (EXPORTFILE);
        unlink "/tmp/exportlist.$$";
    }
    if ($returnpath eq "") {
        print "No quota based view storage exists for you!\n";
    }
    if ($returnpath eq "MORETHANONE") {
        print "Please enter a ticket at http://rc.mot.com/clearcase/contact\n";
        print "and report that you have more than one view storage\n";
        print "location exists as previously displayed.\n";
    }
    unlink "/tmp/dirpath.$$";
    unlink "/tmp/exportlist.$$";
    return ($returnpath);
}
# ************************ SUBROUTINE DEFINITION *****************************
#
# NAME
#       call_server     -   Call appropriate server using tcp socket.
#
# USAGE
#       call_server vobserver command vobtag remotereplica
#
#       viewserver      -   viewserver to contact
#       port            -   Port to use.
#       thekey          -   Server will look for this valid key.
#       
#
# DESCRIPTION
#       This routine sets up a TCP socket to the appropriate server.
#       It passes the parameters, and waits for output from the quota
#       command from the server.
#
# RETURNS
#
sub call_server ($$) {

    #   WHAT:   Declare private variables for the passed in arguements.
    #   WHY:    So it's clear.
    my ($viewserver, $port) = @_;

    #   Private Variable Definitions.
    #
    my ($myexitcode, $inetaddr, $packedaddr, $proto, $line);

    $myexitcode = $SUCCESS;

    if ( $inetaddr = inet_aton($viewserver) ) {
        $packedaddr = sockaddr_in ($port, $inetaddr);
        $proto = getprotobyname ('tcp');
        if (socket (SOCK, PF_INET, SOCK_STREAM, $proto)) {
            if (connect (SOCK, $packedaddr)) {
                #
                #   WHAT:   Negociate connection.
                #   WHY:    It lets the server know we are legitimate.
                #
                if ( connection_verified (*SOCK) ) {
                    #   Send command
                    send SOCK, "quota\n", 0x8;
                    # MSG_EOR
                    #   Get response

                    $linecount = socketreadln (*SOCK);

		    if ($linecount == 0) {
                        #   WHAT:   No quota exists on the server for
                        #           this user. Tell him/her.
                        #   WHY:    No output may confuse the user. Be clear.
                        printf "No quotas exist for you on $viewserver\n";
                    } 
                    else {
                        printf "Server: $viewserver\n";
                        for ($count = 0; $count < $linecount ; $count++) {
                            $line = socketreadln (*SOCK);
                            printf "$line\n";
                        }
                    }
                }
            }
            else {
                print "ERROR: Unable to connect to remote server $viewserver!\n";
                $myexitcode = $CALLSERVERFAILED;
            }
        }
        else {
            print "ERROR: Socket creation failed!\n";
            $myexitcode = $CALLSERVERFAILED;
        }
    }
    else {
        #   WHAT:   inetaddr is undefined (does not exist).
        #   WHY:    Couldn't find server. Report the error
        #           to calling routine.
        #
        print "ERROR: Could not resolve IP address for $viewserver!\n";
        $myexitcode = $CALLSERVERFAILED;
    }
    return $myexitcode
}
# ************************ SUBROUTINE DEFINITION *****************************
#
# NAME
#       connection_verified -   Verifies connection with server.
#
# USAGE
#       connection_verified socket
#
#       socket          -   Socket connection to the server.
#
# DESCRIPTION
#       The server wants to verify who we are. This routine does this.
#       It uses an intermediate rsync server to act as a third party to
#       validate the connection and the requesting client. This routine
#       uses a random generated password and salt key to create an
#       encrypted file. The file is rsync'ed to the thirdparty server.
#       The server is sent our hostname, UID of the requesting user,
#       the generated password and salt key. The server will then use
#       the encrypted password on the thirdpart server to verify the
#       data stream we sent. The server will also verify the UID of
#       the requesting user. If anything fails, we get a non-zero return
#       code. If zero is returned, the server has validated this client
#       and we can proceed with our requests to the server.
#
# RETURNS
#       0   -   connected verified.
#       1   -   some failure occurred.
#
sub connection_verified (*) {

    #   WHAT:   Declare private variables for the passed in arguements.
    #   WHY:    So it's clear.
    my ($serversocket) = @_;

    #   Private Variable Definitions.
    #
    my $TRUE = 1;
    my $FALSE = 0;
    my $SUCCESS = 0;
    my $EUID = $>;
    my $thishost;
    my $verified;
    my $return_code;
    my $ENCRYPTFILEPATH;
    my $THIRDPARTYHOST="nisah101.americas.nsn-net.net";
    #  Use logger to put entries in syslog. LOGGER is the name
    #  used in the syslog file.
    my $LOGCMD = "/usr/bin/logger";
    my $LOGGER = "myquota";

    #   WHAT:   Get the hostname of this machine.
    #   WHY:    We need it later for transfering the file to the
    #           thirdparty server.
    system ("/usr/bin/ksh", "-c", "hostname >/tmp/thehostname.$$");
    open (HOSTFILE, "/tmp/thehostname.$$");
    $thishost = <HOSTFILE>;
    chomp ($thishost);
    close (HOSTFILE);
    unlink "/tmp/thehostname.$$";
    $ENCRYPTFILEPATH="/tmp/$thishost.$$";

    #   WHAT:   Here's the real deal. Setup the srand routine to generate
    #           two random numbers between 0 and 1. Use the first as a
    #           password and the second as the key or salt value. Finally,
    #           create an encrypted file of the password entry.
    #   WHY:    This is the means by which the server will verify we 
    #           are a trusted client and it will perform what we request.
    #
    srand ( time () ^ ($$ + ($$ << 15)) );
    $clearpassword = rand;
    $salt_key = rand;
    $encryptedpassword = crypt ($clearpassword, $salt_key);

    open (ENCRYPTFILE, ">$ENCRYPTFILEPATH");
    print ENCRYPTFILE $encryptedpassword;
    close (ENCRYPTFILE);

    #   WHAT:   Send the encrypted file to the predetermined location on
    #           the thirdparty server.
    #   WHY:    This is where our server will look for this encrypted file.
    #
    $return_code = system ("/usr/bin/ksh", "-c", "/apps/public/bin/rsync -a $ENCRYPTFILEPATH $THIRDPARTYHOST\:\:tokens");
    if ( ($return_code / 256) != $SUCCESS ) {
        $verified = $FALSE;
        print "FATAL ERROR: Unable to verify connection with server.\n";
        print "Please report this via a MONET ticket: http://rc.mot.com/clearcase/contact\n";
        system ("$LOGCMD", "-i", "-t", "$LOGGER", "rsync failed! status=$return_code");
    }
    else {
        #   WHAT:   With the encrypted file on the thirdparty server, send
        #           the server our host.processID, UID, and password.
        #   WHY:    This is what the server wants to validate our identity.
        #           Then wait for the server to return a code.
        #
        send $serversocket, "$thishost.$$ $EUID $clearpassword\n", 0x8;

        $return_code = socketreadln ($serversocket);

        if ( $return_code == $SUCCESS ) {
            $verified = $TRUE;
        }
        else {
            $verified = $FALSE;
            print "FATAL ERROR: Server validation failed.\n";
            print "Please report this via a MONET ticket: http://rc.mot.com/clearcase/contact\n";
            system ("$LOGCMD", "-i", "-t", "$LOGGER", "validation failed!");
        }
        unlink $ENCRYPTFILEPATH;
    }
    return $verified;
}
