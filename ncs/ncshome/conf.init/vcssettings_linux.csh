#!/bin/tcsh -x

alias usage 'echo "Usage:";echo "$0 sm4.0|sm5.0|sfm4.0|sfm5.0";exit 1'

echo "CoSim Setup start..."

# parse args
if ($# < 1) then
	usage
endif
switch ($argv[1])
	case sm*:
		set PRODUCT=SM
		set COSIM_SW_DIR=/opt/apps/cosim
		set COSIM_KERNEL=/vob/wibb_bts/msm/code/SubscriberManager/pkgDeploymentArtifacts/cosim_kernel
		set TIPC_DEV_DIR=/mot/linux_cosim_h/1.1/src/h
		breaksw
	case sfm4*:
		set PRODUCT=SFM
		set COSIM_SW_DIR=/opt/apps/cosim-03-06-00
		set COSIM_KERNEL=/vob/wibb_bts/msm/code/FlowManager/pkgFlowMgrDeployment/cosim_kernel
		set TIPC_DEV_DIR=/mot/linux_cosim_h/1.1/src/h
		breaksw
	case sfm*:
		set PRODUCT=SFM
		set COSIM_SW_DIR=/opt/apps/cosim
		set COSIM_KERNEL=/vob/wibb_bts/msm/code/FlowManager/pkgFlowMgrDeployment/cosim_kernel
		set TIPC_DEV_DIR=/mot/proj/wibb_wr/pnele12ve32/linux-2.x/usermode-agent/1.1/src/h
		breaksw
	default: 
		usage
		breaksw
endsw

set CUR_DIR=`pwd`

# cp cosim software
if (! -d $CUR_DIR/cosim) then
	cp -r $COSIM_SW_DIR $CUR_DIR/cosim
endif

# initialize system envirables
setenv COSIM_DIR $CUR_DIR/cosim
setenv COSIM_PATH $CUR_DIR
setenv CLEARCASE_HOME /opt/rational/clearcase
setenv MERGESTAT_HOME /usr/prod/vobstore104/cmbp/WIMAX/cm-policy
setenv MOUSETRAP_HOME /opt/apps/MT
setenv TAU_UML_DIR /opt/apps/Tau 
setenv TAU_TTCN_DIR /opt/apps/Tester
setenv TAU_TESTER /opt/apps/Tester
setenv TEST_CDF $COSIM_DIR/common/data/TestEnv.cfg
setenv DEBUG_LEVEL 4
setenv G2_GENERATE_MAPFILE 1
setenv AUTOGEN_EXTERNAL_OPS FALSE
setenv CC gcc
setenv OSTYPE linux
setenv TAU_TESTER_MAJOR_VER 3
setenv TAU_TESTER_MINOR_VER 1
setenv LM_LICENSE_FILE 27030@csamlicna01.mot.com:27030@csamlicna02.mot.com:27030@csamlicea01.mot.com:19353@sail-a:19353@sail-b:19353@swim-b:19353@run-c:7143@zru03sun07:5280@ski-b:1700@zru03sun01:~ddts/license.dat:7144@scalpel:19353@sail-a:27000@zru11lic01
setenv TIPC_DEV_ROOT $TIPC_DEV_DIR

# linke cosim kernel
ln -sf $COSIM_DIR/uml/kernel $COSIM_KERNEL

# initialize port
(cd /vob/wibb_bts/nm/code/libcmt/packUnpack; $CLEARCASE_HOME/bin/clearmake -f mt_cmt_lib)
unset sctdir
chmod +w $COSIM_DIR/env_int/src/appdata.txt
chmod +x $COSIM_DIR/tools/portCatch.pl
$COSIM_DIR/tools/portCatch.pl

# finish cosim setup
echo "$PRODUCT CoSim Setup finished!"


