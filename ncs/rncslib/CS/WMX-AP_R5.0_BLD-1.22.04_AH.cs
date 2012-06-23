# DO NOT REBUILD WITH THIS CONFIG SPEC.
# 
# This is a historical config spec, not intended for rebuilding.  If you need
# to rebuild from this build version, then create a new view with one of these
# CMBP mkview commands.
# 
#   mkview -cr <cr-number> -b WMX-AP_R5.0_BLD-1.22.04
#   mkview -tag <view-name> -b WMX-AP_R5.0_BLD-1.22.04
# 
#----------------------------------------------------------------------#
# CMBlueprint - ClearCase View Config Spec

#   (Using DevProject 'WMX-AP_R5.0_REL-1.22.00.prj' located at:
#    /mot/proj/wibb_bts/cmbp/prod/cm-policy/bin/script/../../config/WIBB_BTS_projects/WMX-AP_R5.0_REL-1.22.00.prj)


# Development rules:
#
element * CHECKEDOUT 

# This section is to pickup external components
element /vob/wibb_bts/nm/im/... WIMAXIM_05.00.01.09.03-BCCB3594_HAP-BASE_R3.7_REL-01.05-SDL -nocheckout                         
element /vob/wibb_bts/nm/CLAgent/e500-glibc_cgl/... CNEOMI-AGENT_R5.0_BLD-3_WIMAXIM_05.00.01.09.03 -nocheckout                  
element /vob/wibb_bts/nm/CLAgent/ppc_e500v2-glibc_cgl/... CNEOMI-AGENT_R5.0_BLD-3_WIMAXIM_05.00.01.09.03 -nocheckout
element * CNEOMI-AGENT_R5.0_BLD-3
element /vob/wibb/system_eng/uml_model/... WIMAXIM_05.00.01.09.03
element /vob/wimax_cneomi/... -none

# System Level Common Definitions (in iSL) 
element /vob/wibb/... WMX-COMMONSYS_R5.0_RB_PATCH17

# BTS-CAPC  Interface-Specific Definitions (in iSL) 
element /vob/wibb/... WMX-BTSCAPC_R5.0_RB_PATCH8
 
# BTS-BTS  Interface-Specific Definitions (in iSL) 
element /vob/wibb/... WMX-BTSBTS_R5.0_RB_PATCH2
 
# MSS-BTS  Interface-Specific Definitions (in iSL) 
element /vob/wibb_swa/... WMX-MSSBTS_R5.0_RB_PATCH8
 
# NWGR6 Interface-Specific Definitions (in iSL) 
element /vob/wibb/... WMX-NWGR6_R5.0_RB_PATCH11

#Set diagnotsitc flag, to catch WR license server error
element /vob/wuce/wuce/bin/wucenv    /main/tmp_emake-compat/dev-156121/apbld_wr_test_bld/2

# INDEV00169224 strip debug symbols from /usr/app/lib
## emake versions for WiMAX R5.0 #
element /vob/wuce/wuce/process/local_clib.mk   /main/dev-169224-emake/1
element /vob/wuce/wuce/process/local_cxxlib.mk /main/dev-169224-emake/1
element /vob/wuce/wuce/process/local_g2clib_cclink.mk /main/emake/dev-169224-emake/1
element /vob/wuce/wuce/process/local_g2lib.mk  /main/emake/dev-169224-emake/1
element /vob/wuce/wuce/bin/mkpkg /main/emake/dev-169224-emake/5
element /vob/wuce/wuce/bin/gen_strip   /main/dev-169224-emake/1
element /vob/wuce/wuce/bin/process_line.awk /main/dev-169224-emake/1

# CR INDEV00168085 prelink in wuce
element /vob/wuce/wuce/bin  /main/dev-168085/2 
element /vob/wuce/wuce/bin/build-retgz /main/dev-168085/4 
element /vob/wuce/wuce/bin/configure_fs.awk /main/dev-168085/6 
element /vob/wuce/wuce/bin/configure_install.awk /main/dev-168085/1 
element /vob/wuce/wuce/bin/configure_install_prelink.awk /main/dev-168085/2 
element /vob/wuce/wuce/bin/create_dirs.awk /main/dev-168085/1 
element /vob/wuce/wuce/bin/generate_post_install_script  /main/dev-168085/2

element /vob/wuce/wuce/bin/newcr /main/INDEV00157602/2
element /vob/wuce/wuce/process/local_vxmod.mk .../dev-169668/1
##### Emake specific changes starts here ###########
element /vob/wuce/... WUCE13.4G21A.EMAKE
##### Emake changes ends here       ###########

element /vob/sdl/... TAU_GSGH_4_0_REL1.5.1  
element /vob/sdl/... SAEI_GSGH_REL1.20

# for BCU-1 /vob/sdl/lib/lib_tau271/linux/wrlinppc (and for tau)

element /vob/sdl/... TAU_GSGH_4_0_REL1.5

element /vob/omp4g_bldtools/wrl30/... WRL30GA_PATCHLEVEL1
element /vob/omp4g_bldtools/pnele20wrl20ga/... PNELE20_WRL20_GA_PATCHLEVEL1
element /vob/omp4g_bldtools/pnele14ve32d/... PNELE14VE32D_PATCHLEVEL1_TIPC1.7.6

element /vob/omp4g/platform/delivery/... OMP_PLAT_DELIVERY_DIRS

element /vob/wibb_bts/platform/delivery/... APSW_PLAT_DEL_DIRS
element /vob/wibb_bts/platform/delivery/sc APSW_PLAT_DEL_DIRS
element /vob/wibb_bts/platform/delivery/sac APSW_PLAT_DEL_DIRS
element /vob/wibb_bts/platform/delivery/modem APSW_PLAT_DEL_DIRS
element /vob/wibb_bts/platform/delivery/4xmodem   APSW_PLAT_DEL_DIRS

element /vob/omp4g/platform/delivery/sac/bootloader/...                 4XBL00.04.16
element /vob/omp4g/platform/delivery/sac/bootmanager/...                4XBM00.04.02
element /vob/wibb_bts/platform/delivery/sac/fpga/... APSW_PLAT_SAC_FPGA_020E
element /vob/wibb_bts/platform/delivery/sac/kernel_and_fs -none

element /vob/omp4g_oss/platform/delivery/sac/kernel_and_fs/... LSPSAC01.00.07
element /vob/wibb_bts/platform/delivery/sac/supported_hals.txt  APSW_PLAT_SAC_HAL_COMP_0.1.0
element /vob/omp4g_oss/platform/delivery/sac/codeload_kernel/...        CLSAC00.00.10


element /vob/wibb_bts/platform/delivery/sc/kernel -none
element /vob/omp4g_oss/platform/delivery/sc/kernel_and_fs/... LSP03.00.25.L3BH.13
element /vob/omp4g_oss/platform/delivery/sc/codeload_kernel/...         IR01.02.03
element /vob/omp4g/platform/delivery/sc/bootrom/...                     BL03.02.12
element /vob/wibb_bts/platform/delivery/sc/fpga/... APSW_PLAT_SC_FPGA_0011
element /vob/wibb_bts/platform/delivery/sc/supported_hals.txt  APSW_PLAT_SC_HAL_COMP_1.3.0


element /vob/omp4g/platform/delivery/modem/bootrom/...                  BL03.02.12
element /vob/omp4g/platform/delivery/modem/kernel/...                   BS03.02.20_1_2
element /vob/omp4g/platform/delivery/modem/supported_modem_hals.txt     BS03.02.20_1_2
element /vob/omp4g/platform/code/vxkernel/config/...                    BS03.02.20_1_2
element /vob/omp4g/platform/code/vxkernel/...                           BS03.02.20_1_2
element /vob/omp4g/platform/code/2x_bsp/...                             BS03.02.20_1_2

element /vob/wibb_bts/platform/delivery/modem/phy_sap_api/... APSW_PLAT_WIBBFW_R5.0.1_REL-0.0.E

element /vob/wibb_bts/platform/delivery/modem/bootrom -none
element /vob/wibb_bts/platform/delivery/modem/kernel -none
element /vob/wibb_bts/platform/delivery/modem/supported_modem_hals.txt -none
element /vob/wibb_bts/platform/code/vxkernel -none
element /vob/wibb_bts/platform/delivery/modem/plat_bsp -none


element /vob/omp4g/platform/delivery/4xmodem/bootmanager/...            4XBM00.04.00
element /vob/omp4g/platform/delivery/4xmodem/bootloader/...             4XBL00.04.16
element /vob/omp4g/platform/delivery/4xmodem/kernel/...                 4XBS00.04.17_1_2
element /vob/omp4g/platform/delivery/4xmodem/supported_4xmodem_hals.txt 4XBS00.04.17_1_2
element /vob/omp4g/platform/code/4xkerndevel/config/...                 4XBS00.04.17_1_2
element /vob/omp4g/platform/code/4xkerndevel/...                        4XBS00.04.17_1_2
element /vob/omp4g/platform/code/4x_bsp/...                             4XBS00.04.17_1_2

element /vob/wibb_bts/platform/delivery/4xmodem/phy_sap_api/... APSW_PLAT_4X_WIBBFW_R5.0.1_REL-0.0.E

element /vob/wibb_bts/platform/delivery/4xmodem/bootmanager -none
element /vob/wibb_bts/platform/delivery/4xmodem/bootloader -none
element /vob/wibb_bts/platform/delivery/4xmodem/kernel -none
element /vob/wibb_bts/platform/delivery/4xmodem/supported_4xmodem_hals.txt -none
element /vob/wibb_bts/platform/delivery/4xmodem/4xkerndevel -none
element /vob/wibb_bts/platform/delivery/4xmodem/4x_bsp -none



element /vob/omp4g_oss/platform/code/pam_radius_auth-1.3.16/... PAM_RADIUS_AUTH-1.3.16_2
element /vob/omp4g_oss/platform/code/libedit/3.0-20090923/... LIBEDIT-3.0-20090923
element /vob/omp4g_oss/nm/code/drbd-8.0.6/... DRBD-8.0.6_3
element /vob/omp4g_oss/nm/code/mini_httpd-1.19/... MINI_HTTPD-1.19_5
element /vob/omp4g_rd_oss/... LKM-OMP4G_R1.0_REL-1.11.02
element /vob/omp4g_r1/... OMP-OMP4G_R1.0_INT-4.01.58
element /vob/omp4g/... OMP-OMP4G_R1.0_INT-4.01.58
element /vob/haprel_r3/... HAP-BASE_R3.7_REL-01.05
################################################
 
element * .../wmx-ap_r5.0_bld-1.23.00/LATEST 
element .../lost+found -none 
mkbranch wmx-ap_r5.0_bld-1.23.00 
element * WMX-AP_R5.0_REL-1.22.00 
element * .../wimax_r5.0-main/0 
element * R5.0 
element * /main/LATEST 
end mkbranch wmx-ap_r5.0_bld-1.23.00

#----------------------------------------------------------------------#
