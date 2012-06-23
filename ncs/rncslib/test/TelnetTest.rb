#!/usr/bin/env ruby

require 'net/telnet'  
 
tn = Net::Telnet.new('Host'       => '10.192.178.199',
                     'Port'       => 23,
                     'Timeout'    => 60,
                     'Telnetmode' => false)
tn.login "cwnj74", "liujun#0802"  
tn.cmd "date"  
