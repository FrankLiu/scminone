name=BMC
version=2.0.1
cur_dir=${shell pwd}
cur_date=${shell date +%Y%m%d}
bmc_label=${name}_${version}

src=bin conf lib test PKG-INFO setup.py
target=${cur_dir}/target
bmc_release_uid=apbld
bmc_release_pwd=
bmc_release_dir=zch66wmxbld05.china.nsn-net.net:/home/${bmc_release_uid}/bmc
ahftp_dir=ftp://isdlinux4.americas.nsn-net.net/bmc

clean:
	@echo "cleanup ${name} ..."
	rm -rf ${target}/${name}.tar.gz
	
package: 
	@echo "package ${name} ${version}"
	mkdir -p ${target}
	tar -cvf ${target}/${name}.tar ${src}
	gzip -f ${target}/${name}.tar
	
release: clean package
	@echo "release ${name} ${version}"
	mv ${target}/${name}.tar.gz ${target}/${bmc_label}.tar.gz

deploypkg: package
	@echo "deploy to ftp server ${bmc_release_dir}"
	scp ${target}/${name}.tar.gz ${bmc_release_uid}@${bmc_release_dir}
	echo "deployed ${name}.tar.gz to ${bmc_release_dir}"
	
deployrelease: release
	@echo "deploy to ftp server ${bmc_release_dir}"
	scp ${target}/${bmc_label}.tar.gz ${bmc_release_uid}@${bmc_release_dir}
	echo "deployed ${bmc_label}.tar.gz to ${bmc_release_dir}"

deploy2ahftp: release
	@echo "deploy to AH ftp server ${ahftp_dir}"
	curl -T ${target}/${bmc_label}.tar.gz -u cwnj74 ${ahftp_dir}
	echo "deployed ${bmc_label}.tar.gz to ${ahftp_dir}"
	
deploy: deploypkg
	
.PYONY :clean package release deploypkg deployrelease deploy2ahftp deploy

