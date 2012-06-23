#!/usr/bin/env ruby -w

require 'net/smtp'
require 'ncs/Template'

class Mailer
	attr_accessor :mailserver, :from, :tolist
	attr_accessor :cclist, :bcclist
	attr_accessor :subject, :body, :mail
	def initialize(mailserver=nil,from=nil,*tolist)
		@mailserver = mailserver
		@from = from
		@tolist = *tolist||[]
		@cclist = []
		@bcclist = []
		@msg = []
		@body = []
	end
	
	def build_email(mailmsgs, mailtemplate)
		template = Template.new(mailtemplate)
		@body = template.render(mailmsgs||{})
		return @body
	end
	
	def store_email(dst)
		File.open(dst, 'w'){|f|
			@body.each do |line|
				f.write(line)
			end
		} if not @body.empty?
	end
	
	def send(ishtml=true)
		prepare_mail(ishtml)
		smtp = Net::SMTP.new(@mailserver)
		Net::SMTP.start(@mailserver, 25) do |smtp|
			smtp.sendmail(@msg.join("\n"), @from, @tolist)
		end
	end
	
	def sendhtml
		send
	end
	def sendtext 
		send(false)
	end
	
	private 
	def prepare_mail(ishtml=true)
		raise "mailserver should be defined!" if not defined?(@mailserver) or @mailserver.empty?
		raise "from should be defined!" if not defined?(@from) or @from.empty?
		raise "tolist should be defined!" if not defined?(@tolist) or @tolist.empty?
		raise "subject should be defined!" if not defined?(@subject) or @subject.empty?
		raise "either body or mail should be defined!" if not defined?(@body) and not defined?(@mail)
		@msg.push("To: "+@tolist.join(','))
		@msg.push("Cc: "+@cclist.join(',')) if @cclist.length > 0
		@msg.push("Bcc: "+@bcclist.join(',')) if @bcclist.length > 0
		@msg.push("From: #{@from}")
		@msg.push("Subject: #{@subject}")
		@msg.push("Content-Type: text/html") if ishtml
		if not @body.empty? #body from a message array
			@msg.push(@body)
		elsif not @mail.empty? #body from a file
			raise "mail not exists!" if File.exists?(@mail)
			IO::foreach(@mail) do |line|
				@msg.push("#{line}")
			end
		end
	end
end

