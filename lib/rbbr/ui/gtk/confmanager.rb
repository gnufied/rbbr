=begin

  rbbr/ui/gtk/confmanager.rb 

  $Author: mutoh $
  $Date: 2003/12/21 11:15:18 $

  Copyright (C) 2003 Ruby-GNOME2 Project

  This program is free software.
  You can distribute/modify this program under
  the terms of the Ruby Distribute License.

=end

require 'rbconfig'

module RBBR
module UI
module GTK
  DEFAULT_LIBS = %w{glib2 pango gdk_pixbuf2 gtk2 gconf2 gnomecanvas2 libart2 gnome2 rbconfig rbbr cgi ri observer refe}

  begin 
    require 'gconf2'
    class GConfDataStore
      APP_DIR = "/apps/rbbr/"
      def initialize
        @client = GConf::Client.new
        @client["/test"]
      end
      def [](key)
        @client[APP_DIR + key]
      end
      
      def []=(key, val)
        @client[APP_DIR + key] = val
      end
    end
    store = nil
    begin
      store = GConfDataStore.new
    rescue GConf::NoServerError
      p "GConf::NoServerError: Use PseudoDataStore instead." if $DEBUG
      raise LoadError.new
    end
    DATA_STORE = store
  rescue LoadError
    class PseudoDataStore
      @@app_dir = ENV["HOME"] || ENV["APPDATA"] || ENV["TEMP"] || ""
      if /mswin32|mingw/ =~ RUBY_PLATFORM 
        @@app_path = File.join(@@app_dir, "/rbbr/rbbr.conf")
      else
        @@app_path = File.join(@@app_dir, "/.rbbr")
      end
      @@conf = nil
      def initialize
        begin
          @@conf = eval(File.open(@@app_path).read) unless @@conf
        rescue
          @@conf = {}
          p $! if $DEBUG
        end
      end
      def [](key)
        @@conf[key]
      end
                                                                                
      def []=(key, val)
        @@conf[key] = val
        newdir = @@app_path.split("/")
        newdir.each_index{|i|
          if i > 1
            Dir.mkdir(newdir[0...i].join("/")) unless FileTest.exist?(newdir[0...i].join("/"))
          end
        }
        File.open(@@app_path, "w") do |io|
          io.print @@conf.inspect
        end
      end
    end
    DATA_STORE = PseudoDataStore.new
  end
  
  class ConfManager
    def initialize
      @client = DATA_STORE
      libs = self["libs"]
      if libs
        @libs = eval(libs)
      else
        @libs = DEFAULT_LIBS + %w{libglade2 gst gnomevfs gtkhtml2}
      end
      require_libs
    end
    
    def [](key)
      @client[key]
    end

    def []=(key, val)
      @client[key] = val
    end

    def add_libs(libs)
      libs.each do |lib|
        unless @libs.include?(lib)
          @libs << lib
          require_libs([lib])
        end
      end
      self["libs"] = @libs.inspect
    end

    def remove_libs(libs)
      @libs -= libs
      self["libs"] = @libs.inspect
    end

    def include_lib?(lib)
      @libs.include?(lib) or DEFAULT_LIBS.include?(lib)
    end

    attr_reader :libs

    def require_libs(libs = nil)
      libs = @libs unless libs
      libs.each do |lib|
        unless DEFAULT_LIBS.include?(lib)
          begin
            require lib
          rescue LoadError
            p "#{lib} is not found." if $DEBUG
          end
        end
      end
    end
  end
end;end;end
