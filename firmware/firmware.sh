#!/usr/bin/env bash

set -x

export ORIGDIR=`dirname $0`
export ABSDIR=`cd ${ORIGDIR} && pwd`
export COLUMNS=300
ct=/usr/atria/bin/cleartool
sed=/bin/sed
awk=/bin/awk
diff=/usr/bin/diff

if [ $# -ne 2 ]; then
    echo """
Usage:
	./firmware.sh r4.0.firmware validate|init|unpack|install|all
"""
    exit 1
fi
source ${ORIGDIR}/firmware.conf

if [ -e "$1" ]; then
    source $1
	export FIRMWARE_RELEASE
else
    echo "Firmware file $1 not found."
    exit 1
fi

#check if the software from website is uploaded to specified folder
firmware_validate_upload(){
	if [ ! -e "${FIRMWARE_UPLOADDIR}" ]; then
		echo "firmware upload dir ${FIRMWARE_UPLOADDIR} not exist, will create it automatically"
		mkdir -p ${FIRMWARE_UPLOADDIR}
	fi
	if [ ! -e "${FIRMWARE_UPLOADDIR}/FIRMWARE_${FIRMWARE_RELEASE}" ]; then
		echo "firmware upload dir ${FIRMWARE_UPLOADDIR}/FIRMWARE_${FIRMWARE_RELEASE} not exist, will create it automatically"
		mkdir -p ${FIRMWARE_UPLOADDIR}/FIRMWARE_${FIRMWARE_RELEASE}
	fi
	firmware_updir=${FIRMWARE_UPLOADDIR}/FIRMWARE_${FIRMWARE_RELEASE}
	#check Wi4_RFH_pkg.bin
	if [ ! -e "${firmware_updir}/Wi4_RFH_pkg.bin" ]; then
		echo "${firmware_updir}/Wi4_RFH_pkg.bin not exists!"
		exit 1
	fi
	#check 2x installation package
	if [ ! -e "${firmware_updir}/2x/physap_${FIRMWARE_PKG_PATTERN}_pkg.zip" ]; then
		echo "${firmware_updir}/2x/physap_${FIRMWARE_PKG_PATTERN}_pkg.zip not exists!"
		exit 1
	fi
	if [ ! -e "${firmware_updir}/2x/Wi4_2s_DSP_pkg.bin" ]; then
		echo "${firmware_updir}/2x/Wi4_2s_DSP_pkg.bin not exists!"
		exit 1
	fi
	if [ ! -e "${firmware_updir}/2x/Wi4_2s_MFPGA_pkg.bin" ]; then
		echo "${firmware_updir}/2x/Wi4_2s_MFPGA_pkg.bin not exists!"
		exit 1
	fi
	#check 4x installation package
	if [ ! -e "${firmware_updir}/4x/physap4x_${FIRMWARE_PKG_PATTERN}_pkg.zip" ]; then
		echo "${firmware_updir}/4x/physap4x_${FIRMWARE_PKG_PATTERN}_pkg.zip not exists!"
		exit 1
	fi
	if [ ! -e "${firmware_updir}/4x/Wi4_4s_DSP_pkg.bin" ]; then
		echo "${firmware_updir}/4x/Wi4_4s_DSP_pkg.bin not exists!"
		exit 1
	fi
	if [ ! -e "${firmware_updir}/4x/Wi4_4s_MFPGA_pkg.bin" ]; then
		echo "${firmware_updir}/4x/Wi4_4s_MFPGA_pkg.bin not exists!"
		exit 1
	fi
	echo "Firmware release ${FIRMWARE_RELEASE} is uploaded under ${FIRMWARE_UPLOADDIR}/FIRMWARE_${FIRMWARE_RELEASE}"
	echo "Firmware release ${FIRMWARE_RELEASE} is a valid upload"
}

#initialize the firmware work dir and log dir
firmware_init(){
        echo "initialize firmware installation"
        if [ ! -e "${FIRMWARE_WORKDIR}" ]; then
			echo "firmware upload dir ${FIRMWARE_WORKDIR} not exist, will create it automatically"
            mkdir -p ${FIRMWARE_WORKDIR}
        fi
        if [ -e "${FIRMWARE_WORKDIR}/FIRMWARE_${FIRMWARE_RELEASE}" ]; then
			echo "Firmware release already installed, please check again!"
			exit 1
        fi

        echo "initialize firmware work dir"
        cd ${FIRMWARE_WORKDIR}
        mkdir "FIRMWARE_${FIRMWARE_RELEASE}"
        chmod 777 "FIRMWARE_${FIRMWARE_RELEASE}"

        #initialize 2x
        cd ${FIRMWARE_WORKDIR}/FIRMWARE_${FIRMWARE_RELEASE}
        mkdir 2x
        chmod 777 2x
        cd 2x
        mkdir phy_sap_api
        cd phy_sap_api
        mkdir lib
        mkdir include
        #initialize 4x
        cd ${FIRMWARE_WORKDIR}/FIRMWARE_${FIRMWARE_RELEASE}
        mkdir 4x
        chmod 777 4x
        cd 4x
        mkdir phy_sap_api
        cd phy_sap_api
        mkdir lib
        mkdir include
        mkdir config

        #initialize log dir
		echo "initialize firmware log dir"
		if [ ! -e "${FIRMWARE_LOGDIR}/FIRMWARE_${FIRMWARE_RELEASE}" ]; then
			echo "Firmware log dir not exist, will create it automatically"
			mkdir -p ${FIRMWARE_LOGDIR}/FIRMWARE_${FIRMWARE_RELEASE}
			chmod 777 ${FIRMWARE_LOGDIR}/FIRMWARE_${FIRMWARE_RELEASE}
        fi
		
        echo "firmware working dir is initialized."
}

#unpack the software
firmware_unpack(){
        echo "unpack firmware..."
		
		if [ ! -e "${FIRMWARE_WORKDIR}/FIRMWARE_${FIRMWARE_RELEASE}/2x/phy_sap_api" ]; then
			echo "Please invoke firmeate init method at first"
			exit 1
		fi 
		
		#copy package to working dir
		echo "copy package to working dir ${FIRMWARE_WORKDIR}/FIRMWARE_${FIRMWARE_RELEASE}"
		cp ${FIRMWARE_UPLOADDIR}/FIRMWARE_${FIRMWARE_RELEASE}/Wi4_RFH_pkg.bin ${FIRMWARE_WORKDIR}/FIRMWARE_${FIRMWARE_RELEASE}/2x/phy_sap_api
		cp ${FIRMWARE_UPLOADDIR}/FIRMWARE_${FIRMWARE_RELEASE}/2x/* ${FIRMWARE_WORKDIR}/FIRMWARE_${FIRMWARE_RELEASE}/2x/phy_sap_api
		cp ${FIRMWARE_UPLOADDIR}/FIRMWARE_${FIRMWARE_RELEASE}/Wi4_RFH_pkg.bin ${FIRMWARE_WORKDIR}/FIRMWARE_${FIRMWARE_RELEASE}/4x/phy_sap_api
		cp ${FIRMWARE_UPLOADDIR}/FIRMWARE_${FIRMWARE_RELEASE}/4x/* ${FIRMWARE_WORKDIR}/FIRMWARE_${FIRMWARE_RELEASE}/4x/phy_sap_api
		
        #unpack 2x
        cd ${FIRMWARE_WORKDIR}/FIRMWARE_${FIRMWARE_RELEASE}/2x/phy_sap_api
        if [ ! -e "physap_${FIRMWARE_PKG_PATTERN}_pkg.zip" ]; then
                echo "Firmware package has not been uploaded, please upload it before go ahead."
                exit 1
        fi
        #ls -ltr
        unzip physap_${FIRMWARE_PKG_PATTERN}_pkg.zip
        #ls -ltr
        rm physap_${FIRMWARE_PKG_PATTERN}_pkg.zip
        rm physap_lib.a
        mv physap.out lib/
        #ls -ltr lib/
        mv physap_inc.zip include/
        #ls -ltr
        cd include/
        unzip physap_inc.zip
        rm physap_inc.zip
        #ls -ltr

        #unpack 4x
        cd ${FIRMWARE_WORKDIR}/FIRMWARE_${FIRMWARE_RELEASE}/4x/phy_sap_api
		if [ ! -e "physap4x_${FIRMWARE_PKG_PATTERN}_pkg.zip" ]; then
			echo "Firmware package has not been uploaded, please upload it before go ahead."
			exit 1
        fi
        #ls -ltr
        unzip physap4x_${FIRMWARE_PKG_PATTERN}_pkg.zip
        rm physap4x_${FIRMWARE_PKG_PATTERN}_pkg.zip
        mv physap4s.out lib/
        #ls -ltr lib/
        mv physap4s.cfg config/
        #ls -ltr config/
        mv physap4x_inc.zip include/
        #ls -ltr
        cd include/
        unzip physap4x_inc.zip
        rm physap4x_inc.zip
        #ls -ltr
        echo "unpacked firmware to ${FIRMWARE_WORKDIR}/FIRMWARE_${FIRMWARE_RELEASE}"
}

import_modem(){
	modem=$1
	if [ ! -e "${FIRMWARE_LOGDIR}/FIRMWARE_${FIRMWARE_RELEASE}" ]; then
		echo "Firmware log dir not exist, will create it automatically"
		mkdir -p ${FIRMWARE_LOGDIR}/FIRMWARE_${FIRMWARE_RELEASE}
		chmod 777 ${FIRMWARE_LOGDIR}/FIRMWARE_${FIRMWARE_RELEASE}
	fi
	log=${FIRMWARE_LOGDIR}/FIRMWARE_${FIRMWARE_RELEASE}/${modem}.log
	touch ${log}
	nohup time ${ct} setview -exec "${ABSDIR}/firmware_import.sh ${modem}" ${FIRMWARE_VIEW} > ${log} 2>&1
	if [ $? == 1 ]; then
		cat ${log}
		echo "modem ${modem} failed to be imported, please check log ${log}"
		exit 1
	fi
	echo "modem ${modem} is imported, please check log ${log}"
}

#install the firmware, should running with apbld
firmware_import(){
	echo "install firmware..."
	import_modem '2x'
	import_modem '4x'
	echo "installed firmware..."
}

case "${2}" in
	validate)
		firmware_validate_upload
		;;
	init)
		firmware_init
		;;
	unpack)
		firmware_unpack
		;;
	import)
		firmware_import
		;;
	all)
		firmware_validate_upload
		firmware_init
		firmware_unpack
		firmware_import
		;;
	*)
		echo "Please specify validate,init,unpack,install or all as the second arg"
		exit 1
		;;
esac

exit 0
