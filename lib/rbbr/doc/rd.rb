=begin

  rbbr/doc/rd.rb - Document Referring for RD

  $Author: mutoh $
  $Date: 2004/03/27 17:47:03 $

  Copyright (C) 2003 Masao Mutoh

  This program is free software.
  You can distribute/modify this program under
  the terms of the Ruby Distribute License.

=end
require 'cgi'

module RBBR
  module Doc
    class RD < Database
      def initialize
	super()
        @db = Hash.new
        Dir.glob(RBBR::Config::DATA_DIR + "/rd/*") do |f|
          @db[File.basename(CGI::unescape(f))] = File.open(f).read.split("\n")
        end
      end

      def lookup_class( klass )
        data = @db[klass]
        ret = "" 
       if data
          data.each do |line|
            if /^= / =~ line
            elsif /^== / =~ line
              break
            elsif /- \(\(<.*>\)\)/ =~ line
              break
            else
              ret << line + "\n"
            end
          end
        end
        unless ret.size > 0
          raise LookupError, "Data was not found."
        end
        ret
      end
      
      def lookup_module( modul )
        raise LookupError, "module/class is not supported"
      end

      def lookup_const( const )
	raise LookupError, "constant is not supported"
      end
      
      def lookup_method( method )
        ary = /^(.*)(\.|\#|::)(.+)/.match(method).to_a
        if ary[2] == "."
          key = Regexp.escape(method)
        else
	  key = Regexp.escape(ary[3])
        end

        if ary[2] == "::" and ary[3] =~ /^[a-z]/
          #for signals
          regexp = /^--- #{key}:/i
        else
 	  if ary[3] == "[]"
	    regexp = /^--- \[.*\]/i
	  elsif ary[3] == "[]="
	    regexp = /^--- \[.*\]\s*\=/i
	  else
	    regexp = /^--- #{key}([\s\(:]|$)/i
	  end
        end

        data = @db[ary[1]]
        unless data
          raise LookupError, "Data was not found."
        end

        ret = ""
        flag = false
        item = false
        cnt = 0
        data.each do |line|
          if regexp =~ line
            flag = true
            cnt += 1
          elsif flag && /- \(\(<.*>\)\)/ =~ line
            break
          elsif flag && /^(---|=)/i =~ line
            break
          elsif flag && ! item && /^\s*\*/ =~ line
            ret << "\n"
            item = true
          end
          if flag
            if cnt == 2 && /^\s*$/ !~ line
              ret << "\n"
            end
            ret << line + "\n"
            cnt += 1
          end
        end
        unless ret.size > 0
          raise LookupError, "Data was not found."
        end
        strip_string(ret)
      end

      def info
        nil
      end

      private
      def strip_string(str)
        str.gsub(/\(\(<(.*?)\|(.*?)>\)\)/, "\\2")
      end

      MultiDatabase::DatabaseList << self

    end

  end
end
