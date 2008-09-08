=begin

  rbbr/ui/gtk/modulelabel.rb 

  $Author: mutoh $
  $Date: 2004/01/14 18:18:44 $

  Copyright (C) 2002 Ruby-GNOME2 Project

  Copyright (C) 2000-2002 Hiroshi Igarashi <iga@ruby-lang.org>

  This program is free software.
  You can distribute/modify this program under
  the terms of the Ruby Distribute License.

=end

module RBBR
module UI
module GTK

  class ModuleLabel < DocViewer

    include GetText
    GetText.bindtextdomain("rbbr", nil, nil, "UTF-8")

    def initialize(database)
      super(database)
      @database = database
      set_pixels_above_lines(5)
      set_pixels_below_lines(5)
      set_left_margin(10)
      @buffer.create_tag('large', 
			 :weight => Pango::FontDescription::WEIGHT_BOLD,
			 :scale => Pango::AttrScale::LARGE)
      @buffer.insert(@buffer.start_iter, _("Select a class/module"), 
			       'large')
    end

    def update(modul)
      @buffer.delete(*@buffer.bounds)
      iter = @buffer.start_iter
      if Class === modul
	@buffer.insert(iter, "class ", 'title', 'large')
      else # Module
	@buffer.insert(iter, "module ", 'title', 'large')
      end
      @buffer.insert(iter, modul.name, 'link', 'large')

      if Class === modul and Object != modul
	@buffer.insert(iter, " < ", 'title', 'large')
	@buffer.insert(iter, modul.superclass.name, 'link', 'large')
      end

      included_modules_at = modul.included_modules_at
      unless included_modules_at.empty?
	@buffer.insert(iter, "; include ", 'title', 'large')
	first = true
	included_modules_at.each do |mod|
	  if first
	    first = false
	  else
	    @buffer.insert(iter, ", ", 'title', 'large')
	  end
	  @buffer.insert(iter, mod.name, 'link', 'large')
	end
      end
    end
  end

end;end;end
