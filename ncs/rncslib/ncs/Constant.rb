#!/usr/bin/ruby -w

#global constant
$OS_NAME=%x{uname}.chomp()
$HOST_NAME=%x{uname -n}.chomp()
$CUR_PATH=%x{pwd}.chomp()

#ncs runner constant
$TESTCASE_RESULTS = {
	'testcase_ignored'			=> "Test case ignored",
    'finished_normally'         => "Test case summary",
    'address_not_mapped'        => "Description: Address not mapped to object",
    'model_is_not_startup'      => "CRITICAL ERROR: [CLIENT] Exiting",
    'log_is_not_opened'         => "Cannot open Testcase log",
    'time_out'                  => "Timeout"
}
$MODEL_RESULTS = {
    'uml_error'                 => "************ ERROR *************",
    'uml_warning'               => "************ WARNING ************",
    'address_already_in_use'    => "Exiting - bind error: Address already in use",
    'cmi_register_req'          => "OUTPUT of CMI_REGISTER_REQ",
    'log_is_not_opened'         => "Cannot open Model log",
}


