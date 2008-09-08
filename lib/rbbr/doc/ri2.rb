=begin

  rbbr/doc/ri2.rb - Document Referring with ruby-1.8.0 or later.

  $Author: mutoh $
  $Date: 2004/03/28 14:23:35 $

  Copyright (C) 2004 Ruby-GNOME2 Project

  This program is free software.
  You can distribute/modify this program under
  the terms of the Ruby Distribute License.

=end

require 'rbbr/doc'
require 'rdoc/ri/ri_driver'

#
# RI wrapper
#
module RI
  class TextFormatter
    def puts(str = "")
      RI.write(str)
    end
    def print(str = "", str2 = "", str3 = "", str4 = "", str5 = "")
      RI.write(str + str2 + str3 + str4 + str5)
    end
  end

  @@out = ""

  def RI.clear
    @@out = ""
  end
  def RI.write(str)
    @@out << str << "\n"
  end
  def RI.out
    ret = @@out
    @@out = ""
    ret
  end
end
                                                                                     
class DefaultDisplay
  def page
    begin
      yield
    end
  end
end

class RiDriver
  attr_reader :ri_reader
end

#
# Main program
#

module RBBR
  module Doc
    class RI < Database

      def initialize
        @ri = ::RiDriver.new
	super()
      end

      def lookup_method(method)
	begin 
	  @ri.get_info_for(method.gsub(/\./, "::"))
	rescue Exception
	  raise LookupError
	end
	::RI.out
      end

      alias :lookup_const :lookup_method
      alias :lookup_module :lookup_method
      alias :lookup_class :lookup_method

      def info
        "ri #{::RI::VERSION_STRING}"
      end
      MultiDatabase::DatabaseList << self
    end
  end
end
