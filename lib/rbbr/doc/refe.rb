=begin

  rbbr/doc/refe.rb - Document Referring with ReFe

  $Author: mutoh $
  $Date: 2004/03/26 16:21:41 $

  Copyright (C) 2002 Ruby-GNOME2 Project

  Copyright (C) 2001 Hiroshi Igarashi <iga@ruby-lang.org>

  This program is free software.
  You can distribute/modify this program under
  the terms of the Ruby Distribute License.

=end
require 'rbbr/doc'
require 'refe/database'
require 'refe/info'

module RBBR
  module Doc

    class ReFe < Database
      def refe_version_8_or_later?
        ver = ::ReFe::Version.split(".").map{|v| v.to_i}
        ver[0] >= 0 and ver[1] > 7
      end
      def convert(str)
        begin
          ret = GLib.convert(str, "UTF-8", "EUC-JP")
        rescue RuntimeError
          if $DEBUG
            print "can't converted from #{charset} to UTF-8\n"
            print "String = #{str}\n"
          end
        end
        ret
      end
 
      def initialize
	super()
	@db = ::ReFe::Database.new(::ReFe::REFE_DATA_DIR, true)
      end

      def lookup_class( klass )
        begin
          doc = @db.class_document
          convert(doc[klass])
        rescue
          raise LookupError, $!.message
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
          doc = @db.method_document
          ret = doc[method].split("\n").collect!{ |line|
            if /^\s{4}/ =~ line
              $'
            else
              line
            end
          }.join("\n")
          convert(ret)
        rescue
          raise LookupError, $!.message
        end
      end

      def info
        "ReFe #{::ReFe::Version}"
      end

      MultiDatabase::DatabaseList << self

    end

  end
end
