=begin

  rbbr/ui/gtk.rb - Meta-Level Information Browser User Interface with GTK+

  $Author: mutoh $
  $Date: 2004/03/26 13:04:14 $

  Copyright (C) 2002 Ruby-GNOME2 Project

  Copyright (C) 2000-2002 Hiroshi Igarashi <iga@ruby-lang.org>

  This program is free software.
  You can distribute/modify this program under
  the terms of the Ruby Distribute License.

=end

require 'observer'
require 'gtk2'
begin
  require 'gnome2'
  $GNOME_SUPPORTED = true
rescue LoadError
  $GNOME_SUPPORTED = false
end
require 'rbbr/config'
require 'rbbr/metainfo'
require 'rbbr/doc'
require 'rbbr/ui/gtk/undo'
require 'rbbr/ui/gtk/windowutils'
require 'rbbr/ui/gtk/browselist'
require 'rbbr/ui/gtk/methodlist'
require 'rbbr/ui/gtk/constlist'
require 'rbbr/ui/gtk/linkedtextbuffer'
require 'rbbr/ui/gtk/docviewer'
require 'rbbr/ui/gtk/moduleview'
require 'rbbr/ui/gtk/modulelistview'
require 'rbbr/ui/gtk/moduletreeview'
require 'rbbr/ui/gtk/browser'
require 'rbbr/ui/gtk/moduledisplay'
require 'rbbr/ui/gtk/modulelabel'
require 'rbbr/ui/gtk/stockbrowser'
require 'rbbr/ui/gtk/aboutdialog'
require 'rbbr/ui/gtk/libselectiondialog'
require 'rbbr/ui/gtk/confmanager'
require 'rbbr/ui/gtk/searchentrybox'

module RBBR
module UI
module GTK
  def self.main
    if $GNOME_SUPPORTED
      Gnome::Program.new("rbbr", RBBR::VERSION) 
    else
      Gtk.init
    end
    window = Browser.new
    window.show_all
    GLib::Log.set_handler("Gtk", 1|2|4|8) do |domain, level, message|
      # ignore log message
    end

	GC.start
    Gtk.main
  end

end
end
end

if $0 == __FILE__
  RBBR::UI::GTK.main
end
