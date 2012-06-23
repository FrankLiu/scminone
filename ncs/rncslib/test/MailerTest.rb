#!/usr/bin/ruby -w

require 'test/unit'
require 'logger'
require 'ncs/Mailer'

class MailerTest < Test::Unit::TestCase
	@@ClassName = 'MailerTest'
	
	def setup
		@mailer = Mailer.new
		@mailer.mailserver = 'de01exm68.ds.mot.com'
		@mailer.from = 'hzcosim@wimax-cosim.mot.com'
		@mailer.tolist = ['cwnj74@motorola.com']
	end
	
	def test_sendhtml
		@mailer.subject = 'test ruby smtp lib'
		@mailer.body = [
			'<div style="color:red;">', 
			'test ruby smtp<br/>', 
			'test ruby sendmail',
			'</div>']
		@mailer.sendhtml()
	end
	
	def test_sendtext
		@mailer.subject = 'test ruby smtp lib'
		@mailer.body = [
			'test ruby smtp', 
			'test ruby sendmail',
			]
		@mailer.sendtext()
	end
	
	def teardown
		@mailer = nil
	end
end