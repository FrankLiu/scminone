#!/bin/bash
set -x

#export NCS_HOME=`dirname $0`
export NCS_HOME=$(cd "$(dirname "$0")"; pwd|tr -d '/r')
ncs_script=${NCS_HOME}/NCS.pl
conf_init_dir=${NCS_HOME}/conf.init
vcssettings_script_name=vcssettings_linux
#work_basedir=/tmp/ncsworkspace
work_basedir=${NCS_HOME}/work
log_basedir=/tmp/ncslog
ct=/usr/atria/bin/cleartool

usage()
{
	echo '''
    Usage:
		./NCS.sh product_version view_name [properties_file] &
			product_version: sm5.0|sm4.0|sfm4.0|sfm5.0
			view_name: your_view_name
			properties_file: ncs_sm5.0.properties|ncs_sm4.0.properties|ncs_sfm4.0.properties
		
	!!!!!Please read the Readme.txt file before you go!!!!!
	'''
    exit 1
}

parse_args()
{
	#simple parse options
	if [ -n "$1" ] && ([ "$1" == "--version" ] || [ "$1" == "-v" ]); then
		perl $ncs_script -v
		exit 0
	fi
	if [ -n "$1" ] && [ "$1" == "--dryrun" ]; then
		enable_dryrun=true
		shift
	fi
	if [ $# -lt 2 ]; then
		usage;
	fi
	#parse product
	case $1 in
	sm4.0|sm5.0|sfm4.0|sfm5.0)
		product=$1
		logdir=$log_basedir/$product
		;;
	*) usage;;
	esac
	#parse work view
	workview=$2;
	cronlog=$logdir/ncs_cron.${workview}.log
	workdir="$work_basedir/$workview";
	#parse current shell & decide which shell script will be used
	cur_shell=$(basename `echo $SHELL`)
	case $cur_shell in
		csh|tcsh)
			setup_env_script="${vcssettings_script_name}_ah.csh";;
		*)
			setup_env_script="${vcssettings_script_name}_ah.sh";;
	esac
	#parse standalone|crontab
	# if [ -n "$2" ] && [ "$2" == "standalone" ]; then
		# setup_env_script=.csh
		# shift
		# echo "script running standalone!"
	# else
		# setup_env_script=vcssettings_linux.sh
		# echo "script running by crontab!"
	# fi
	#parse property file
	if [ -n "$3" ]; then
		property_file=$2
	else
		property_file=ncs_${product}.properties
	fi
}

initialize_log()
{
	if [ ! -d "$logdir" ]; then
		echo "log dir not exists, need create"
		mkdir -p $logdir
		chmod -R 775 $log_basedir
		chmod -R 775 $logdir
	fi
	touch $cronlog
}

initialize_ncs()
{
	echo "Work view is: $workview"
	echo "Work dir is: $workdir"
	echo "Log dir is: $logdir"
	echo "Environment setup by script: $setup_env_script"
	echo "Property file is: $property_file"
	if [ ! -d $workdir ]; then
		echo "work dir not exists, need create"
		mkdir -p $workdir
		chmod -R 775 $workdir
	fi
	if [ ! -e $workdir/$property_file ]; then
		cp $conf_init_dir/$property_file $workdir/
	fi
	cp $conf_init_dir/$setup_env_script $workdir/
	chmod +x $workdir/$setup_env_script
	echo "initialized ncs"
	echo "please check log at: $cronlog"
}

start_ncs()
{
	echo "start ncs in work view: $workview"
	$ct setview -exec "(cd $workdir;source $setup_env_script $product;perl $ncs_script $property_file)" $workview
}

run()
{
	echo "========= NCS running =========="
	echo "NCS running at... `date`"
	initialize_ncs
	start_ncs
}

dryrun()
{
	echo "========= NCS dry running =========="
	echo "NCS dry running at... `date`"
	initialize_ncs
}

parse_args $@
initialize_log
echo "Please check log @ $cronlog"
if [ $enable_dryrun ]; then
	dryrun >>$cronlog 2>&1
else
	run >>$cronlog 2>&1
fi
exit 0
