#!/bin/bash
set -x

usage(){
	echo "Usage:"
    echo "$0 sm4.0|sm5.0|sfm4.0|sfm5.0"
    exit 1
}

echo "CoSim Setup start..."

#parse args
if [ $# -lt 1 ]; then
	usage;
fi
case $1 in
	sm*)
		PRODUCT=SM
		COSIM_SW_DIR=/opt/apps/cosim
		COSIM_KERNEL=/vob/wibb_bts/msm/code/SubscriberManager/pkgDeploymentArtifacts/cosim_kernel
		TIPC_DEV_ROOT=/mot/linux_cosim_h/1.1/src/h
		break
		;;
	sfm4*)
		PRODUCT=SFM
		COSIM_SW_DIR=/opt/apps/cosim-03-06-00
		COSIM_KERNEL=/vob/wibb_bts/msm/code/FlowManager/pkgFlowMgrDeployment/cosim_kernel
		TIPC_DEV_ROOT=/mot/linux_cosim_h/1.1/src/h
		break
		;;
	sfm*)
		PRODUCT=SFM
		COSIM_SW_DIR=/opt/apps/cosim
		COSIM_KERNEL=/vob/wibb_bts/msm/code/FlowManager/pkgFlowMgrDeployment/cosim_kernel
		TIPC_DEV_ROOT=/mot/proj/wibb_wr/pnele12ve32/linux-2.x/usermode-agent/1.1/src/h
		break
		;;
	*) usage;;
esac

CUR_DIR=`pwd`

#cp cosim software
if [ ! -d $CUR_DIR/cosim ]; then
	cp -r $COSIM_SW_DIR $CUR_DIR/cosim
fi

#initialize system envirables
export COSIM_DIR=$CUR_DIR/cosim
export COSIM_PATH=$CUR_DIR
export CLEARCASE_HOME=/opt/rational/clearcase
export MERGESTAT_HOME=/usr/prod/vobstore104/cmbp/WIMAX/cm-policy
export MOUSETRAP_HOME=/opt/apps/MT
export TAU_UML_DIR=/opt/apps/Tau 
export TAU_TTCN_DIR=/opt/apps/Tester
export TAU_TESTER=/opt/apps/Tester
export TEST_CDF=$COSIM_DIR/common/data/TestEnv.cfg
export DEBUG_LEVEL=4
export G2_GENERATE_MAPFILE=1
export AUTOGEN_EXTERNAL_OPS=FALSE
export CC=gcc
export OSTYPE=linux
export TAU_TESTER_MAJOR_VER=3
export TAU_TESTER_MINOR_VER=1
export LM_LICENSE_FILE=27030@csamlicna01.mot.com:27030@csamlicna02.mot.com:27030@csamlicea01.mot.com:19353@sail-a:19353@sail-b:19353@swim-b:19353@run-c:7143@zru03sun07:5280@ski-b:1700@zru03sun01:~ddts/license.dat:7144@scalpel:19353@sail-a:27000@zru11lic01
export TIPC_DEV_ROOT

#linke cosim kernel
ln -sf $COSIM_DIR/uml/kernel $COSIM_KERNEL

#initialize port
(cd /vob/wibb_bts/nm/code/libcmt/packUnpack; $CLEARCASE_HOME/bin/clearmake -f mt_cmt_lib)
unset sctdir
chmod +w $COSIM_DIR/env_int/src/appdata.txt
chmod +x $COSIM_DIR/tools/portCatch.pl
$COSIM_DIR/tools/portCatch.pl

#finish cosim setup
echo "$PRODUCT CoSim Setup finished!"


