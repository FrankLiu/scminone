#!/usr/bin/ruby -w

class NcsVersion
	attr_accessor :major_version, :minor_version, :version_extra 
	def initialize
		@ncs_name = 'Nightly Cosim Script'
		@ncs_short_name = 'ncs'
		@major_version = 2
		@minor_version = 1
		@version_extra = ''
		@build_version = %x{date +%Y%m%d}.chomp!()
	end
	
	def get_ncs_name
		return @ncs_name
	end
	def get_ncs_sname
		return @ncs_short_name
	end
	
	def get_ncs_version
		curdir=File::dirname(__FILE__)
		@build_version = %x{cat "#{curdir}/bldver"}.chomp!() if File.exist?("#{curdir}/bldver") 
		ncs_version = "#{@major_version}.#{@minor_version}-#{@build_version}"
		ncs_version = "#{ncs_version}-#{@version_extra}" if not @version_extra.empty?
		return ncs_version
	end
	
	def get_ncs_release
		return get_ncs_sname()+get_ncs_version()
	end
	
	def print_ncs_verbose
		ncs_release = get_ncs_release()
		ncs_version = get_ncs_version();
		puts <<EOF
NCS(#{@ncs_name}) 
---------------------------
NCS Release: #{ncs_release}
NCS Version: #{ncs_version}
EOF
	end
end

