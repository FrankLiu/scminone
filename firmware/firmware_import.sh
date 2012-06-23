#!/usr/bin/env bash

#set -x

export ORIGDIR=`dirname $0`
export COLUMNS=300
ct=/usr/atria/bin/cleartool
sed=/bin/sed
awk=/bin/awk
diff=/usr/bin/diff

if [ $# -ne 1 ]; then
    echo """
Usage:
	./firmware_import.sh 2x|4x
"""
    exit 1
fi
source ${ORIGDIR}/firmware.conf

case "${1}" in
	2x)
		install_dir=/vob/wibb_bts/platform/delivery/modem/phy_sap_api
		config_spec_tmp=${FIRMWARE_LOGDIR}/FIRMWARE_${FIRMWARE_RELEASE}/2x_config_spec_tmp
		config_spec=${FIRMWARE_LOGDIR}/FIRMWARE_${FIRMWARE_RELEASE}/2x_config_spec
		work_dir=${FIRMWARE_WORKDIR}/FIRMWARE_${FIRMWARE_RELEASE}/2x/phy_sap_api
		to_be_installed=(. include lib)
		label=APSW_PLAT_${FIRMWARE_RELEASE}
		;;
	4x)
		install_dir=/vob/wibb_bts/platform/delivery/4xmodem/phy_sap_api
		config_spec_tmp=${FIRMWARE_LOGDIR}/FIRMWARE_${FIRMWARE_RELEASE}/4x_config_spec_tmp
		config_spec=${FIRMWARE_LOGDIR}/FIRMWARE_${FIRMWARE_RELEASE}/4x_config_spec
		work_dir=${FIRMWARE_WORKDIR}/FIRMWARE_${FIRMWARE_RELEASE}/4x/phy_sap_api
		to_be_installed=(. include lib config)
		label=APSW_PLAT_4X_${FIRMWARE_RELEASE}
		;;
	*)
		echo "Please specify firmware modem type"
		exit 1
		;;
esac

echo "install firmware modem ${1}..."

validate_import(){
	echo "validate import..."
	label=$1
	chk_label=`cd /vob/wibb_bts && ${ct} lstype -short lbtype:${label}`
	echo "label = ${label}, chk_label = ${chk_label}"
	if [ "${chk_label}" == "${label}" ]; then
		echo "found label ${chk_label} already imported, you cannot import it again!"
		exit 1
	else
		echo "label is valid, will continue import label ${label}"
	fi
}

#validate import label
validate_import ${label}

#install modem
cd ${install_dir}

echo "update config spec to branch latest"
${ct} ls
#update config spec to comment modem rule
${ct} catcs | sed "s%element ${install_dir}%#element ${install_dir}%" > ${config_spec_tmp}
${ct} setcs ${config_spec_tmp}
echo "========"
echo "`${ct} catcs`"
echo "========"
${ct} ls

#get diff files by awk
cd ${install_dir}
echo "parse differs between ${install_dir} and ${work_dir}"
for tbi in ${to_be_installed[@]}; do
	echo "import dir ${tbi}"
	diffs=$(${diff} -q ${tbi} ${work_dir}/${tbi} | grep differ | awk '{print $2}')
	for i in ${diffs}; do
		if [ "$i" == "" ]; then
			continue
		fi
		echo "File ${work_dir}/'$i' and '$i' differ"
		echo "${ct} checkout -c 'Update with new firmware version: ${FIRMWARE_RELEASE}' '$i'"
		${ct} co  -c "Update with new firmware version: ${FIRMWARE_RELEASE}" "$i";
		echo "cp ${work_dir}/'$i' '$i'"
		cp ${work_dir}/"$i" "$i"
		echo "${ct} checkin -nc '$i'"
		${ct} ci -nc "$i"
	done
	#check the diff again
	echo "check differs again"
	echo "---------------------------"
	echo "`${diff} -q ${tbi} ${work_dir}/${tbi} | grep differ`"
	echo "imported dir ${tbi}"
done

#make label
cd ${install_dir}
echo "make label type ${label} and apply label recursively"
${ct} mklbtype -global -c "Uploaded new firmware version" ${label}
${ct} mklabel -recurse ${label} .
${ct} ls

#update config spec
echo "update config spec to label ${label}"
echo "--------------------------------"
${ct} catcs | sed "s%^#element ${install_dir}/...*$%element ${install_dir}/... ${label}%" > ${config_spec}
${ct} setcs ${config_spec}
echo "========"
echo "`${ct} catcs`"
echo "========"

#check the sum
echo "check the sum info?"
echo "--------------------------------"
for tbi in ${to_be_installed[@]}; do
	echo "`sum -r $tbi/*`"
	echo "`sum -r ${work_dir}/${tbi}/*`"
	echo "--------"
done

#check if config spec rule applyed
echo "check if config spec rule get applyed?"
echo "--------------------------------"
for tbi in ${to_be_installed[@]}; do
	echo "`${ct} ls $tbi`"
	echo "---------------------"
done

#check if differ
echo "check the differ again"
echo "--------------------------------"
for tbi in ${to_be_installed[@]}; do
	echo "`${diff} -q ${tbi} ${work_dir}/${tbi} | grep differ`"
	echo "---------------------"
done

echo "installed firmware modem ${1}..."

exit 0
