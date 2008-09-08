=begin

  rbbr/doc/ri.rb - Document Referring with ri 0.8a

  $Author: mutoh $
  $Date: 2004/03/27 17:47:03 $

  Copyright (C) 2002-2004 Ruby-GNOME2 Project

  Copyright (C) 2001 Hiroshi Igarashi <iga@ruby-lang.org>

  This program is free software.
  You can distribute/modify this program under
  the terms of the Ruby Distribute License.

=end

require 'rbbr/doc'
require 'ri/ri'
require 'ri/op/Plain'

module RBBR
  module Doc
    class RI < Database

      def initialize
        @ri = ::RI.new
        @output = ""
        @ri.setOutputFormatter(Plain.new(@output, 10))
	super()
      end

      def lookup_class( klass )
        begin
          cl = nil
          val = catch(:exit) do
            cl = @ri.findClass(klass)
            0 # normal exit
          end
          raise LookupError if val > 0
          fragments(cl)
        rescue
          raise LookupError
        end
      end

      def lookup_module( modul )
        raise LookupError, "module/class is not supported"
      end

      def lookup_const( const )
	raise LookupError, "constant is not supported"
      end
      
      def lookup_method( method )
	begin
          ary = /^(#{::RI::CN_PATTERN})(\.|\#|::)(.+)/.match(method).to_a
          method_list = nil
          val = catch(:exit) do
            method_list = @ri.methods_matching(ary[1], ary[2], ary[3])
            0 # normal exit
          end
          raise LookupError if val > 0
          case method_list.size
          when 0
            raise LookupError
          when 1
            meth = method_list[0]
            "    " + strip_string(meth.callseq).split("\n").join("\n    ") + "\n\n" + fragments(meth)
          end
	rescue
	  raise LookupError
	end
      end

      def info
        "ri #{::RI_VERSION}"
      end

      private
      def strip_string(str)
        str.gsub!("<br></br>", "\n")
        1 while str.gsub!(/<([^>]+)>(.*?)<\/\1>/m, '\2')
        str
      end

      def fragments(meth)
        ret = ""
        meth.eachFragment do |f|
          case f
          when Verbatim
            ret += "\n    " + f.to_s.split("\n").join("\n    ") + "\n"
          when Paragraph
            ret += "  " + f.to_s.split("\n").join("\n  ") + "\n"
          end
        end
        strip_string(ret)
      end        

      MultiDatabase::DatabaseList << self

    end

  end
end
