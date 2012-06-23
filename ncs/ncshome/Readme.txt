NCS Script Readme
Author: cwnj74@motorola.com
============================
1. How to install NCS?
	mkdir -p /opt/apps/ncshome && cd /opt/apps/ncshome
	gunzip ncs2.0-20100708.tar.gz
	tar -xvf ncs2.0-20100708.tar
	chmod -R 755 /opt/apps/ncshome
	
2. Before moving forward, you should configure you runtime configure file!!!
	- initialize runtime configuration
		cd /opt/apps/ncshome
		./NCS.sh --dryrun sfm4.0 ${your_view_name}
		vi work/${your_view_name}/ncs_sfm4.0.properties
	- in order to let other team members run with your NCS, you should extend the permission
		cd /opt/apps/ncshome
		chmod -R 755 *
		chmod -R 775 work
		
3. How to configure NCS?
	3.1 Configure files location
		Configure files configure the NCS runtime parameters, in includes 3 parts.
		Default configure files is located at ${NCS_HOME}/conf, don't change it if there is no specific request!!!
		Default init configure files is located at ${NCS_HOME}/conf.init
		Runtime configure file is located at ${NCS_HOME}/work/${view_name}/
	e.g.
		WMX5.0 SM:
			Default configure file: 		${NCS_HOME}/conf/ncs_sm5.0.properties
			Default init configure file: 	${NCS_HOME}/conf.init/ncs_sm5.0.properties
			Runtime configure file: 	 	${NCS_HOME}/work/${your_view_name}/ncs_sm5.0.properties
		WMX4.0 SM:
			Default configure file: 		${NCS_HOME}/conf/ncs_sm4.0.properties
			Default init configure file: 	${NCS_HOME}/conf.init/ncs_sm4.0.properties
			Runtime configure file: 	 	${NCS_HOME}/work/${your_view_name}/ncs_sm4.0.properties
		WMX4.0 SFM:
			Default configure file: 		${NCS_HOME}/conf/ncs_sfm4.0.properties
			Default init configure file: 	${NCS_HOME}/conf.init/ncs_sfm4.0.properties
			Runtime configure file: 	 	${NCS_HOME}/work/${your_view_name}/ncs_sfm4.0.properties
			
	3.2 How to initalize configure file?
		NCS.sh provider a way to initialize your project runtime by invoke
			./NCS.sh --dryrun [sm5.0|sm4.0|sfm4.0] ${your_view_name}
		it will copy the default init configure file to your work dir
		at runtime, your runtime configure file will override default configure file
		e.g.
			${NCS_HOME}/work/${your_view_name}/ncs_sm5.0.properties 
						|	override  |
				${NCS_HOME}/conf/ncs_sm5.0.properties
			
	3.3 How to configure your own suite?
		All of supported configureable parameters are listed under default configure file.
		Please check into the default configure files under ${NCS_HOME}/conf for detail information.
		!!!But you always should change the runtime configure file under ${NCS_HOME}/work/${your_view_name}!!!
		e.g.
			WMX5.0 SM: ncs_sm5.0.properties 
				ncs.test.suite=openr6,rrm,motor6,rrm_motor6
				ncs.test.openr6_suite=${ncs.test.sanity.openr6_suite}
				ncs.test.rrm_suite=
				ncs.test.motor6_suite=${ncs.test.sanity.motor6_suite}
				ncs.test.rrm_motor6_suite=
			WMX4.0 SM: ncs_sm4.0.properties 
				ncs.test.suite=motor6
				ncs.test.motor6_suite=${ncs.test.sanity_suite}
			WMX4.0 SFM: ncs_sfm4.0.properties  
				ncs.test.suite=motor6
				ncs.test.motor6_suite=${ncs.test.sanity_suite}
		
		++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
						!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		Before you go, please configure your own suite you want to run.
		Do remember, don't change the ${ncs.test.suite} directly!!!
		WMX4.0:
			${ncs.test.motor6_suite} -> your own suite goes here!
		WMX5.0:
			${ncs.test.openr6_suite} -> your own openr6 suite goes here!
			${ncs.test.rrm_suite} -> your own rrm suite goes here!
			${ncs.test.motor6_suite} -> your own motor6 suite goes here!
			${ncs.test.rrm_motor6_suite} -> your own rrm_motor6 suite goes here!
						!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
	3.4 More about suite type
		NCS only support the following suite types:	openr6,rrm,motor6,rrm_motor6
		and each suite type has his own NECB file.
		that's why you cannot edit the suite type at [3.3 section] by yourself.
		the key ${ncs.test.suite} is not configure the test cases, it is used for configure suite type!
		
	3.5 How to configure your own suite type?
		Just like [3.4 section] mentioned, each suite type has its corresponding NECB file.
		e.g.
			ncs.test.necb_openr6=NECB.xml
			ncs.test.necb_motor6=NECB_MotR6.xml
			ncs.test.necb_rrm=NECB_RRM.xml
			ncs.test.necb_rrm_motor6=NECB_RRM_MotR6.xml
		So configure suite type includes 2 ways:
		- reuse NECB files in /vob
			make sure if you edit ncs.test.suite with "sanity", 
			you should also add necb part with ncs.necb.sanity
			e.g.
				#necb
				ncs.necb.path=/vob/wibb_bts/msm/test/sm_regression/necb
				ncs.necb.openr6=NECB.xml
				ncs.necb.motor6=NECB_MotR6.xml
				ncs.necb.rrm=NECB_RRM.xml
				ncs.necb.rrm_motor6=NECB_RRM_MotR6.xml
				#ncs.necb.sanity=${ncs.necb.openr6}
				
				#test suite
				#ncs.test.suite=sanity
				#ncs.test.sanity_suite=20001-20003
		- use your own NECB files
			e.g.
				#necb
				ncs.test.necb_path=/your/own/path/to/necb/files
				ncs.necb.openr6=NECB.xml
				ncs.necb.motor6=NECB_MotR6.xml
				ncs.necb.rrm=NECB_RRM.xml
				ncs.necb.rrm_motor6=NECB_RRM_MotR6.xml
				#ncs.necb.sanity=${ncs.necb.openr6}

				#test suite
				#ncs.test.suite=sanity
				#ncs.test.sanity_suite=20001-20003
	
	3.6 How to configure project label you want to test?
		edit runtime configure file and add the below lines
		e.g. 
			WMX5.0:
				#project
				ncs.prj.latestprj_pattern=WMX-AP_R5.0_BLD-*.prj
			WMX4.0:
				#project
				ncs.prj.latestprj_pattern=WMX-AP_R4.0_BLD-*.prj
			SC:
				#project
				ncs.prj.latestprj_pattern=SC-AP_R5.0_DEVINT-*.prj
		
	3.7 How to run NCS with your own config spec?
		edit runtime configure file and add the below lines
		e.g.
			#uncomment it to run by config-spec
			ncs.option.run_with_cs=$ENV{NCS_HOME}/CS/WMX-AP_R5.0_BLD-1.23.01.cs
	
	3.8 How to do if you want to run specific label the NCS ignored?
		- cp config spec file to the folder
			cp your_cs_file $ENV{NCS_HOME}/CS/
		- enable run by config spec
			ncs.option.run_with_cs=$ENV{NCS_HOME}/CS/WMX-AP_R5.0_BLD-1.23.01.cs
			
	3.9 How to add ttp files into?
		ncs.test.ttp_files=${ncs.test.compile_path}/CoSim.ttp,${ncs.test.compile_path}/CoSim_MotR6.ttp
	
	3.10 How to get NCS email?
		update the following to your own mailbox
		ncs.mail.tolist=fcgd46@motorola.com cwnj74@motorola.com
		ncs.mail.informlist=fcgd46@motorola.com cwnj74@motorola.com
		
4. How to run NCS on HZ server?
	/opt/apps/ncshome/NCS.sh ${product_version} ${your_view_name}
		${product_version} can be sm5.0|sm4.0|sfm4.0
	e.g
		/opt/apps/ncshome/NCS.sh sm5.0 ncs_sm5.0_part1 &
		
5. How to run NCS on AH server?
	/opt/apps/ncshome/NCS_AH.sh ${product_version} ${your_view_name}
		${product_version} can be sm5.0|sm4.0|sfm4.0
	e.g
		/opt/apps/ncshome/NCS_AH.sh sm5.0 ncs_sm5.0_part1 &
		
6. How to configure crontab for NCS?
	Before you go, please make sure the crond service is turned on!!!
	add below line into crontab
	00 18 * * 0,1,2,3,4,5,6 /opt/apps/ncshome/NCS.sh ${product_version} ${your_view_name}

7. How to configure crontab for NCS on AH server?
	Before you go, please make sure the crond service is turned on!!!
	add below line into crontab
	00 18 * * 0,1,2,3,4,5,6 /opt/apps/ncshome/NCS_AH.sh ${product_version} ${your_view_name}

8. How to check NCS runtime log?
	NCS runtime log includes 3 parts, 
	- crontab log: ncs_cron.${your_view_name}.log
		check your cron log under /tmp/ncslog/${product}
		e.g.
			tail -f /tmp/ncslog/sm5.0/ncs_cron.${your_view_name}.log
	- NCS log: ncs.log
		check your log dir under ${NCS_HOME}/work/${your_view_name}/ncs_sm5.0.propertiess
		e.g. 	
			ncs.log.dir=/tmp/ncslog/sm5.0
			tail -f /tmp/ncslog/sm5.0/ncs.log
	- Compile log: compile_model.log,compile_test.log
		keep tracking the ncs log after you started it
		then you will found the log like below:
		[2010-07-30 15:44:34] [INFO] /opt/apps/Tau/bin/taubatch -B -p SM.ttp -o pkgDeploymentArtifacts::Cosim_Linux 1>/tmp/ncslog/sm5.0/WMX-AP_R5.0_BLD-1.29.13/buildlog/compile_model.log 2>&1
		it shows the compile log is under /tmp/ncslog/sm5.0/WMX-AP_R5.0_BLD-1.29.13/buildlog/compile_model.log
		then you can check the model compile progress with
		tail -f /tmp/ncslog/sm5.0/WMX-AP_R5.0_BLD-1.29.13/buildlog/compile_model.log
	
9. How to setup NCS on a new environment?
	Since NCS depends on some of tools like clearcase, mousetrap, tau, tester, mergestat ...
	All of these tools are configurable with vcssetting_linux files.
	NCS.sh as default main script running with vcssetting_linux.sh or vcssettings_linux.csh
	NCS_AH.sh as AH environment main script running with vcssetting_linux_ah.sh or vcssettings_linux_ah.csh	
	so there is 2 ways to help you setup NCS in your environment:
	9.1 change the vcssetting_linux.sh or vcssettings_linux.csh
		COSIM_SW_DIR=/opt/apps/cosim
		export CLEARCASE_HOME=/opt/rational/clearcase
		export MERGESTAT_HOME=/usr/prod/vobstore104/cmbp/WIMAX/cm-policy
		export MOUSETRAP_HOME=/opt/apps/MT
		export TAU_UML_DIR=/opt/apps/Tau 
		export TAU_TTCN_DIR=/opt/apps/Tester
		export TAU_TESTER=/opt/apps/Tester
		
		if you do this way, you should run main script NCS.sh
		e.g
			/opt/apps/ncshome/NCS.sh sm5.0 ncs_sm5.0_part1 &
	9.2 add own main script and vcssettings_linux files
		cd /opt/apps/ncshome
		cp NCS.sh NCS_${your_own_name}.sh
		update the following line in NCS_${your_own_name}.sh 
			case $cur_shell in
				csh|tcsh)
					setup_env_script="${vcssettings_script_name}_ah.csh";;
				*)
					setup_env_script="${vcssettings_script_name}_ah.sh";;
			esac
		update the ${vcssettings_script_name}_ah.csh to your own name 
		e.g
			case $cur_shell in
				csh|tcsh)
					setup_env_script="${vcssettings_script_name}_test.csh";;
				*)
					setup_env_script="${vcssettings_script_name}_test.sh";;
			esac
		cp conf.init/vcsettings_linux.sh conf.init/vcsettings_linux_${your_own_name}.sh
		cp conf.init/vcsettings_linux.csh conf.init/vcsettings_linux_${your_own_name}.csh
		repeat the 9.1 and update the software you environment installed.
		
	after you have done these 2 steps, then you can continue with step 2
	2. Before moving forward, you should configure you runtime configure file!!!

10. Still have questions?
	Please send mail to me, my mail is cwnj74@motorola.com


