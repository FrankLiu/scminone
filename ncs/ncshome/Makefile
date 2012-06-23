cur_dir=${shell pwd}
cur_date=${shell date +%Y%m%d}
versionfile=${cur_dir}/version
versiontmp=${cur_dir}/version.tmp
name=${shell perl NCS.pl -n}
version=${shell perl NCS.pl -v}
ncs_label=${name}${version}

src=ncslib NCS.pl NCS*.sh Readme.txt
deps=deps
target=${cur_dir}/target
blib=${target}/blib
install_dir=${HOME}/ncshome
svn_dir=/cygdrive/d/opensource/pine-mvc-appfuse/docs/DynamicLanguage/perl/ncs
utility_dir=/cygdrive/d/opensource/pine-mvc-appfuse-hg/utility
ncs_release_dir=ftp://10.192.178.202/ncsreleases/
ncs_release_uidpwd=cwnj74:liujun\#0124
ncs_srmap_dir=ftp://10.192.178.202/ncshome/conf/
ahftp_dir=ftp://isdmldlinux.comm.mot.com/

build: gen_bldver build_clean build_init build_src build_conf build_cs build_necb
build_with_test: build build_test
build_with_deps: build build_deps
	
gen_bldver:
	@echo "generate NCS build version"
	${shell sed -e 's/%BLDREV%/${cur_date}/' ${versionfile} > ${versiontmp}}
	@echo "NCS build version is ${cur_date}"
	
build_clean:
	@echo "cleanup NCS ..."
	rm -rf ${blib}
	-rm -rf ${target}/${ncs_label}.tar.gz
	
build_init:
	@echo "build NCS ..."
	mkdir -p ${target}
	mkdir -p ${blib}
build_src:
	cp -R ${src} ${blib}
	mv ${versiontmp} ${blib}/version
build_conf:
	cp -R conf conf.init ${blib}
build_cs:
	cp -R CS ${blib}
build_necb:
	cp -R necb ${blib}
build_test:
	cp -R test ${blib}
build_deps:
	cp -R deps ${blib}
    
package: build_clean build_with_test
	@echo "package NCS ${version} with test code"
	cd ${blib} && tar -cvf ${target}/${ncs_label}.tar *
	gzip -f ${target}/${ncs_label}.tar
	
install_local: package
	@echo "install NCS locally ..."
	mkdir -p ${install_dir}
	cp -r ${blib}/* ${install_dir}

install: install_local
	@echo "install NCS is depends on install_local for now..."
	@echo "TODO: implement remote deployment?"
	
release: build_clean build
	@echo "release NCS ${version} as a package without test code"
	cd ${blib} && tar -cvf ${target}/${ncs_label}.tar *
	gzip -f ${target}/${ncs_label}.tar
release_with_deps: build_clean build_with_deps
	@echo "release NCS ${version} as a package without test code"
	cd ${blib} && tar -cvf ${target}/${ncs_label}-deps.tar *
	gzip -f ${target}/${ncs_label}-deps.tar

deploydeps:
	@echo "deploy deps to ftp server ${ncs_release_dir}"
	tar -cvf ${name}-deps.tar deps/*
	gzip -f ${name}-deps.tar
	curl -T ${name}-deps.tar.gz -u ${ncs_release_uidpwd} ${ncs_release_dir}
	echo "deployed deps to ${ncs_release_dir}"
	rm -rf ${name}-deps.tar.gz
    
deploysrmapping:
	@echo "deploy WMX_CoSim_SR.xls to ftp server ${ncs_srmap_dir}"
	curl -T ${cur_dir}/conf/WMX_CoSim_SR.xls -u ${ncs_release_uidpwd} ${ncs_srmap_dir}
	echo "deployed NCS WMX_CoSim_SR.xls to ${ncs_srmap_dir}"

deployrelease: release
	@echo "release NCS as a package and deploy into the ftp server ${ncs_release_dir}"
	curl -T ${target}/${ncs_label}.tar.gz -u ${ncs_release_uidpwd} ${ncs_release_dir}
	echo "deployed NCS ${ncs_label}.tar.gz to ${ncs_release_dir}"
deployrelease_with_deps: release_with_deps
	@echo "release NCS as a package and deploy into the ftp server ${ncs_release_dir}"
	curl -T ${target}/${ncs_label}-deps.tar.gz -u ${ncs_release_uidpwd} ${ncs_release_dir}
	echo "deployed NCS ${ncs_label}-deps.tar.gz to ${ncs_release_dir}"
	
deploy2ahftp: release
	@echo "release NCS as a package and deploy into the ah ftp server ${ahftp_dir}"
	curl -T ${target}/${ncs_label}.tar.gz -u cwnj74:Apple123 ${ahftp_dir}
	echo "deployed NCS ${ncs_label}.tar.gz to ${ahftp_dir}"
	
deploy2svn: package
	@echo "release NCS as a package and deploy into the svn folder"
	cp ${target}/${ncs_label}.tar.gz ${svn_dir}/
	echo "deployed NCS ${ncs_label}.tar.gz to ${svn_dir}/"

deploy: deploy2svn deployrelease
	
clean: build_clean
	@echo "remove NCS installation ..."
	rm -rf ${target}/${ncs_label}.tar.gz
	rm -rf ${install_dir}/
	@echo "removed NCS installation!"
	
.PYONY :gen_bldver build build_clean build_init build_src build_conf build_cs build_necb build_test clean
.PYONY :package install_local install release deploysrmapping deployrelease deploy2ahftp deploy2svn deploy
