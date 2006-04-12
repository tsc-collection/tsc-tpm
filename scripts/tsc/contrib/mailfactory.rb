# = Overview:
# A simple to use module for generating RFC compliant MIME mail
# ---
# = License:
# Author:: David Powers
# Copyright:: May, 2005
# License:: Ruby License
# ---
# = Usage:
# 	require 'net/smtp'
# 	require 'rubygems'
# 	require 'mailfactory'
#
#
# 	mail = MailFactory.new()
# 	mail.to = "test@test.com"
# 	mail.from = "sender@sender.com"
# 	mail.subject = "Here are some files for you!"
# 	mail.text = "This is what people with plain text mail readers will see"
# 	mail.html = "A little something <b>special</b> for people with HTML readers"
# 	mail.attach("/etc/fstab")
# 	mail.attach("/some/other/file")
#
# 	Net::SMTP.start('smtp1.testmailer.com', 25, 'mail.from.domain', fromaddress, password, :cram_md5) { |smtp|
# 		mail.to = toaddress
# 		smtp.send_message(mail.to_s(), fromaddress, toaddress)
# 	}
#---
# === 08-31-2005 Modified by: Gennady Bystritsky, Tone Software Corp.
# - Removed reference to pathname.rb so that it can be used in Ruby 1.6.8.
#   Using File.basename instead.
# - Removed reference to rubygems.rb
# - Refactored to remove code duplication in body content building. Checking
#   if the content (text or html) is specified before adding a correspondig
#   section.
# - Fixed base64 encoding not to print to stdout.
#   

require 'base64'

# try to bring in the mime/types module, make a dummy module if it can't be found
begin
  require 'mime/types'
rescue LoadError
  module MIME
    class Types
      def Types::type_for(filename)
        ''
      end
    end
  end
end

# An easy class for creating a mail message
class MailFactory
	
	def initialize()
		@headers = Array.new()
		@attachments = Array.new()
		@attachmentboundary = generate_boundary()
		@bodyboundary = generate_boundary()
	end
	
	
	# adds a header to the bottom of the headers
	def add_header(header, value)
		@headers << "#{header}: #{value}"
	end
	
	
	# removes the named header - case insensitive
	def remove_header(header)
		@headers.each_index() { |i|
			if(@headers[i] =~ /^#{Regexp.escape(header)}:/i)
				@headers.delete_at(i)
			end
		}
	end
	
	
	# sets a header (removing any other versions of that header)
	def set_header(header, value)
		remove_header(header)
		add_header(header, value)
	end
	

	def to=(newto)
                @to = newto
		remove_header("To")
		add_header("To", [ newto ].flatten.join(","))
	end
	
	def to()
		return @to
	end

	
	def replyto=(newreplyto)
		remove_header("Reply-To")
		add_header("Reply-To", newreplyto)
	end
	
	
	def replyto()
		return(get_header("Reply-To")[0])
	end
	
	
	# sets the plain text body of the message
	def text=(newtext)
		@text = newtext
	end
	
	
	# sets the HTML body of the message. Only the body of the
	# html should be provided
	def html=(newhtml)
		@html = "<html>\n<head>\n<meta content=\"text/html;charset=ISO-8859-1\" http-equiv=\"Content-Type\">\n</head>\n<body bgcolor=\"#ffffff\" text=\"#000000\">\n#{newhtml}\n</body>\n</html>"
	end
	
	
	# sets the HTML body of the message.  The entire HTML section should be provided
	def rawhtml=(newhtml)
		@html = newhtml
	end
	
	
	# implement method missing to provide helper methods for setting and getting headers.
	# Headers with '-' characters may be set/gotten as 'x_mailer' or 'XMailer' (splitting
	# will occur between capital letters or on '_' chracters)
	def method_missing(methId, *args)
		name = methId.id2name()
		
		# mangle the name if we have to
		if(name =~ /_/)
			name = name.gsub(/_/, '-')
		elsif(name =~ /[A-Z]/)
			name = name.gsub(/([a-zA-Z])([A-Z])/, '\1-\2')
		end
		
		# determine if it sets or gets, and do the right thing
		if(name =~ /=$/)
			if(args.length != 1)
				super(methId, args)
			end
			set_header(name[/^(.*)=$/, 1], args[0])			
		else
			if(args.length != 0)
				super(methId, args)
			end
			headers = get_header(name)
			return(get_header(name))
		end
	end

	
	# returns the value (or values) of the named header in an array
	def get_header(header)
		headers = Array.new()
		headerregex = /^#{Regexp.escape(header)}:/i
		@headers.each() { |h|
			if(headerregex.match(h))
				headers << h[/^[^:]+:(.*)/i, 1].strip()
			end
		}
		
		return(headers)
	end
	
	
	# returns true if the email is multipart
	def multipart?()
		if(@attachments.length > 0 or @html != nil)
			return(true)
		else
			return(false)
		end
	end
	
	
	# returns a formatted email
	def to_s()
		# all emails get a unique message-id
		remove_header("Message-ID")
		add_header("Message-ID", "<#{Time.now.to_f()}.#{Process.euid()}.#{String.new.object_id()}>")

		if(get_header("Date").length == 0)
			add_header("Date", Time.now.strftime("%a, %d %B %Y %H:%M:%S %Z"))
		end

		# Add a mime header if we don't already have one and we have multiple parts
		if(multipart?())
			if(get_header("MIME-Version").length == 0)
				add_header("MIME-Version", "1.0")
			end
			
			if(get_header("Content-Type").length == 0)
				if(@attachments.length == 0)
					add_header("Content-Type", "multipart/alternative;boundary=\"#{@bodyboundary}\"")
				else
					add_header("Content-Type", "multipart/mixed; boundary=\"#{@attachmentboundary}\"")
				end
			end
		end
		
		return("#{headers_to_s()}#{body_to_s()}")
	end
	
	
	# generates a unique boundary string
	def generate_boundary()
		randomstring = Array.new()
		1.upto(25) {
			whichglyph = rand(100)
			if(whichglyph < 40)
				randomstring << (rand(25) + 65).chr()
			elsif(whichglyph < 70)
				randomstring << (rand(25) + 97).chr()
			elsif(whichglyph < 90)
				randomstring << (rand(10) + 48).chr()
			elsif(whichglyph < 95)
				randomstring << '.'
			else
				randomstring << '_'
			end
		}
		return("----=_NextPart_#{randomstring.join()}")
	end
	
	
	# adds an attachment to the mail.  Type may be given as a mime type.  If it
	# is left off and the MIME::Types module is available it will be determined automagically.
	def add_attachment(filename, type=nil)
		attachment = Array.new()
		attachment[0] = File.basename(filename)
		if(type == nil)
			attachment[1] = MIME::Types.type_for(filename).to_s
		else
			attachment[1] = type
		end	
		
		# Open in rb mode to handle Windows, which mangles binary files opened in a text mode
		File.open(filename, "rb") { |fp|
			attachment[2] = encode(fp.read())
		}
		@attachments << attachment
	end
	
	
	# adds an attachment to the mail as emailfilename.  Type may be given as a mime type.  If it
	# is left off and the MIME::Types module is available it will be determined automagically.
	# file may be given as an IO stream (which will be read until the end) or as a filename.
	def add_attachment_as(file, emailfilename, type=nil)
		attachment = Array.new()
		attachment[0] = emailfilename
		if(!file.respond_to?(:stat) and type == nil)
			attachment[1] = MIME::Types.type_for(file.to_s()).to_s
		else
			attachment[1] = type
		end
		
		if(!file.respond_to?(:stat))		
			# Open in rb mode to handle Windows, which mangles binary files opened in a text mode
			File.open(file.to_s(), "rb") { |fp|
				attachment[2] = encode(fp.read())
			}
		else
			attachment[2] = encode(file.read())			
		end
		@attachments << attachment
	end
	
	
	alias attach add_attachment
	alias attach_as add_attachment_as
	
protected
	
	# returns the @headers as a properly formatted string
	def headers_to_s()
		return("#{@headers.join("\r\n")}\r\n\r\n")
	end
	
	
	# returns the body as a properly formatted string
	def body_to_s()
		body = Array.new()
		
		# simple message with one part
		if(!multipart?())
			return(@text)
		else
			body << "This is a multi-part message in MIME format.\r\n\r\n--#{@attachmentboundary}\r\nContent-Type: multipart/alternative; boundary=\"#{@bodyboundary}\""
			
			if(@attachments.length > 0)
                                populate_content(body)
				
				# and, the attachments
				if(@attachments.length > 0)
					@attachments.each() { |attachment|
						body << "#{buildattachmentboundary(attachment[1], 'base64', attachment[0])}\r\n\r\n#{attachment[2]}"
					}
					body << "\r\n--#{@attachmentboundary}--"
				end
			else
                          populate_content(body)
			end
			
			return(body.join("\r\n\r\n"))
		end
	end
	
	
	# builds a boundary string for including attachments in the body
	def buildattachmentboundary(type, encoding, filename)
		disposition = "\r\nContent-Disposition: inline; filename=\"#{filename}\""
		return("--#{@attachmentboundary}\r\nContent-Type: #{type}; name=\"#{filename}\"\r\nContent-Transfer-Encoding: #{encoding}#{disposition}")
	end
	
	
	# builds a boundary string for inclusion in the body of a message
	def buildbodyboundary(type, encoding)
		return("--#{@bodyboundary}\r\nContent-Type: #{type}\r\nContent-Transfer-Encoding: #{encoding}")
	end

  private
  #######
    def populate_content(body)
      # text part
      if @text
        body << "#{buildbodyboundary('text/plain; charset=ISO-8859-1; format=flowed', '7bit')}\r\n\r\n#{@text}"
      end
      
      # html part
      if @html
        body << "#{buildbodyboundary('text/html; charset=ISO-8859-1', '7bit')}\r\n\r\n#{@html}"
      end
      
      body << "--#{@bodyboundary}--"
    end

    def encode(content, len = 60)
      Base64.encode64(content).scan(/.{1,#{len}}/o).join("\r\n")
    end
end

