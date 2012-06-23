#/bin/sh

# this is a simple shell script for synchronize prj file from AH site to HZ site
# usage: ./syncprj.sh <label>

AH_HOST="isdlinux4.americas.nsn-net.net"
AH_PRJ_PATH=/mot/proj/wibb_bts/cmbp/prod/cm-policy/config/WIBB_BTS_projects/
HZ_PRJ_PATH=/usr/prod/vobstore102/cmbp/WIMAX/cm-policy/config/WIBB_BTS_projects

PROG_NAME=$0
prj_file=$1

if [ $# -lt 1 ]; then
   echo<<EOF
Usage:
   ./syncprj.sh <label>
EOF
   exit 1
fi

echo "synchronize prj $prj_file from AH site to HZ"
scp $AH_HOST:$AH_PRJ_PATH/${prj_file}.prj $HZ_PRJ_PATH/${prj_file}.prj

