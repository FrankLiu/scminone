# valid steps

updateOkMerge:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sUpdateOkMergeToCr

updateRVReminder:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sUpdateRVReminder

turnOffOkMerge:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sTurnOffOkMergeToCr

turnOnOkMerge:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sTurnOnOkMergeToCr

turnOffNBuild:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sTurnOffNBuild

turnOffRVReminder:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sTurnOffRVReminder

turnOnNBuild:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sTurnOnNBuild

turnOnRVReminder:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sTurnOnRVReminder

checkIns:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sCheckIns 

updateIns:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sUpdateIns 

updateAttr:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sUpdateAttr -attr $(ATTRIBUTE)

mergestat:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sMergeStat

sCreateReminderCron:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sCreateReminderCron

sRmViewReminder:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sRmViewReminder

swapWBView:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sSwapWBView

updateNBVer:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sUpdateNBVer

checkNBVer:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sCheckNBVer

lockTargetIntBr:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sLockTargetIntBr

createBldLb:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sCreateBldLb

labelTargetIntBr:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sLabelTargetIntBr

mkPrjDevPrjInt:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sMkPrjDevPrjInt

increNBVer:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sIncreNBVer

genCrStat:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sGenCrStat

loadCrStat:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sLoadCrStat

grantOkMergeToInt:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sGrantOkMergeToInt

mergeIntToRelMain:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sMergeIntToRelMain

createRelLb:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sCreateRelLb

labelRelMain:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sLabelRelMain

mkPrjDevPrjScm:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sMkPrjDevPrjScm

genIns:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sGenIns

genNextIns:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sGenNextIns

createTargetIntBr:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sCreateTargetIntBr

swapNBView:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sSwapNBView

pIntBuildBL:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step pIntBuildBL

pIntBL:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step pIntBL

pScmBL:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step pScmBL

pUpdateCQ:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step pUpdateCQ

pStartInt:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step pStartInt

pStartNextInt:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step pStartNextInt

pBLInOne:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step pBLInOne

pBuildBLInOne:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step pBuildBLInOne

build:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sBuild	

linkIntBlToPred:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sLinkIntBlP	

linkScmBlToPred:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sLinkScmBlP	

linkScmBlToChil:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sLinkScmBlC	

closeCr:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sCloseCr

closeIntBl:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sCloseIntBl

closeScmBl:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sCloseScmBl

blReport:
	$(BMC_HOME)/bin/bmc -instance $(TARGETINTLB) -step sBlReport
