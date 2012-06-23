name=rncs
bldversion=${shell cat ncs/bldver}
version=${shell ruby NCS.rb -v}
cur_dir=${shell pwd}
ncs_label=${name}${version}
src=ncs lib NCS.rb log4r.properties Makefile
target=${cur_dir}/target
blib=${target}/blib
install_dir=${HOME}/rncslib
release_dir=/cygdrive/d/opensource/pine-mvc-appfuse-hg/ncs/target
utility_dir=/cygdrive/d/opensource/pine-mvc-appfuse-hg/utility
ftp_dir=ftp://10.192.178.202/ncsreleases/

build: gen_bldver build_clean build_init build_src build_conf build_cs build_necb
	
gen_bldver:
	@echo "generate NCS build version"
	${shell date +%Y%m%d > ncs/bldver}
	@echo "NCS build version is ${bldversion}"
	
build_clean:
	@echo "cleanup NCS ..."
	-rm -rf ${blib}
build_init:
	@echo "build NCS ..."
	mkdir -p ${target}
	mkdir -p ${blib}
build_src:
	cp -R ${src} ${blib}
build_conf:
	cp -R ../ncshome/conf ../ncshome/conf.init ${blib}
build_cs:
	cp -R CS ${blib}
build_necb:
	cp -R necb ${blib}
build_test:
	cp -R test ${blib}
	
package: build build_test
	@echo "package NCS ${version} with test code"
	-rm -rf ${target}/${ncs_label}.tar.gz
	cd ${blib} && tar -cvf ${target}/${ncs_label}.tar *
	gzip -f ${target}/${ncs_label}.tar
	
install_local: package
	@echo "install NCS locally ..."
	mkdir -p ${install_dir}
	cp -r ${blib}/* ${install_dir}

install: install_local
	@echo "install NCS is depends on install_local for now..."
	@echo "TODO: implement remote deployment?"
	
release: build
	@echo "release NCS ${version} as a package without test code"
	-rm -rf ${target}/${ncs_label}.tar.gz
	cd ${blib} && tar -cvf ${target}/${ncs_label}.tar *
	gzip -f ${target}/${ncs_label}.tar

deploy2ftp: release
	@echo "release NCS as a package and deploy into the ftp server ${ftp_dir}"
	curl -T ${target}/${ncs_label}.tar.gz -u cwnj74:liujun#0802 ${ftp_dir}
	echo "deployed NCS ${ncs_label}.tar.gz to ${ftp_dir}"

deploy2hg: package
	@echo "release NCS as a package and deploy into the svn folder"
	cp ${target}/${ncs_label}.tar.gz ${release_dir}/
	echo "deployed NCS ${ncs_label}.tar.gz to ${release_dir}/"

deploy: deploy2hg deploy2ftp
	
clean:
	@echo "remove NCS installation ..."
	rm -rf ${target}/
	rm -rf ${install_dir}/
	@echo "removed NCS installation!"
	
.PYONY :gen_bldver build build_clean build_init build_src build_conf build_cs build_necb build_test clean
.PYONY :package install_local install release deploy2ftp deploy2hg deploy