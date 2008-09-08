=begin

  rbbr/doc.rb - Document Referring

  $Author: mutoh $
  $Date: 2003/09/06 18:43:46 $

  Copyright (C) 2001 Hiroshi Igarashi <iga@ruby-lang.org>

  This program is free software.
  You can distribute/modify this program under
  the terms of the Ruby Distribute License.

=end

module RBBR
  module Doc

    class LookupError < StandardError; end

    class Database

      def initialize
      end

      def lookup_class( klass )
=begin
module:Module
(retval):String
=end
	raise
      end
      def lookup_module( modul )
=begin
module:Module
(retval):String
=end
	raise
      end

      def lookup_const( const )
=begin
const:Symbol
(retval):String
=end
	raise
      end

      def lookup_method( method )
=begin
method:Method
(retval):String
=end
	raise
      end

      def info
        raise
      end
    end      


    class MultiDatabase < Database

      DatabaseList = []

      def initialize
	@children = []
        path = File.join(RBBR::Config::LIB_DIR, "/rbbr/doc/*.rb")
        STDERR.puts("target directory: #{path}") if $DEBUG
	Dir.glob(path).sort.each do |feature|
	  begin
	    Kernel.require( feature )
	    STDERR.puts("found database: #{feature}") if $DEBUG
	  rescue LoadError
	  end
	end

	DatabaseList.each do |klass|
	  begin
	    database = klass.new
	    @children << database
	    STDERR.puts("found database class: #{klass}") if $DEBUG
	  rescue
	    # ignore
	  end
	end
      end

      def lookup_class( klass )
	@children.each do |db|
	  begin
	    return db.lookup_class(klass)
	  rescue LookupError
	    # ignore
	  end
        end
        ""
      end

      def lookup_method( method )
	@children.each do |db|
	  begin
	    return db.lookup_method(method)
	  rescue LookupError
	    # ignore
	  end
	end
        ""
      end

      def info
        ary = []
	@children.each do |db|
          ary << db.info if db.info
        end
        ary
      end
    end
  end
end
