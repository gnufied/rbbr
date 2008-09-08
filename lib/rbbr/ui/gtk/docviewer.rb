=begin
  rbbr/ui/gtk/docviewer.rb 

  $Author: mutoh $
  $Date: 2004/03/26 15:43:25 $

  Copyright (C) 2002,2003 Ruby-GNOME2 Project
  Copyright (C) 2000-2002 Hiroshi Igarashi <iga@ruby-lang.org>

  This program is free software.
  You can distribute/modify this program under
  the terms of the Ruby Distribute License.

=end

module RBBR
module UI
module GTK

  class DocViewer < Gtk::TextView
    type_register

    # link_clicked(widget, link)
    signal_new("link_clicked", GLib::Signal::ACTION,
               nil,
               GLib::Type["void"],
               GLib::Type["VALUE"])

    include GetText
    GetText.bindtextdomain("rbbr", nil, nil, "UTF-8")

    def initialize(database)
      super()
      @buffer = LinkedTextBuffer.new(RBBR::MetaInfo.link_regexp)
      set_buffer(@buffer)
      @database = database
      set_wrap_mode(Gtk::TextTag::WRAP_WORD)

      @buffer.create_tag('title', 
                        :foreground => '#005500')
      
      @buffer.create_tag("name", 
                        :foreground => '#994400')
      
      @buffer.create_tag("normal", :foreground => 'black')
      @buffer.create_tag("args", :foreground => '#005500')
      @buffer.create_tag("item", :foreground => '#000099')
      @buffer.create_tag("nodata", :foreground => 'darkgray')

      set_left_margin(3)
      set_editable(false)

      @press = nil
      signal_connect("button_press_event") do |w, event|
	@press = event.event_type
	false
      end

      signal_connect("button_release_event") do |w, event|
	if event.button == 1 and @press == Gdk::Event::BUTTON_PRESS
	  win, x, y, modtype = *event.window.pointer
	  if x and y
	    bx, by = window_to_buffer_coords(Gtk::TextView::WINDOW_TEXT, x, y)
	    if iter = get_iter_at_location(bx, by) 
	      if link = @buffer.get_link_at_iter(iter)
		Gtk.idle_add do
		  signal_emit("link_clicked", link)
		end
	      end
	    end
	  end
	end
	false
      end
    end

    def update(modul, specs = nil, args = [], desc = nil)
      freeze_notify
      @buffer.delete(*@buffer.bounds)
      iter = @buffer.delete_selection(true, false)
      
      spec = [modul, specs[0]].join(specs[1]) if specs
      begin
        unless desc
          if spec 
            desc = @database.lookup_method(spec)
          elsif modul
            desc = @database.lookup_class(modul.inspect)
            spec = modul.inspect
          end
        end
        iter = @buffer.get_iter_at_offset(0)
        if specs
          if args.size > 0
            if specs[0] == "[]"
              if specs[1] == "."
                @buffer.insert(iter, modul.inspect + "[", 'title')
              else
                @buffer.insert(iter, modul.inspect + specs[1] + "[", 'title')
              end
              @buffer.insert(iter, args.join(', '), 'args', 'title')
              @buffer.insert(iter, "]", 'title')
            elsif specs[0] == "[]="
              args.pop
              @buffer.insert(iter, modul.inspect + specs[1] + "[", 'title')
              @buffer.insert(iter, args.join(', '), 'args', 'title')
              @buffer.insert(iter, "]= val", 'title')
            elsif /^([\&\!\^\%\+\*\-\/<>\!]|<<|\=\=|\=~|<\=>)$/ =~ specs[0]
              @buffer.insert(iter, spec, 'title')
              @buffer.insert(iter, " val", 'args', 'title')
            else
              @buffer.insert(iter, spec, 'title')
              @buffer.insert(iter, "(", 'title')
              @buffer.insert(iter, args.join(', '), 'args', 'title')
              @buffer.insert(iter, ")", 'title')
            end
          else
            @buffer.insert(iter, spec, 'title')
          end
          @buffer.insert(iter, "\n\n")
        end
          
        if desc and desc.size > 0
          desc.split("\n").each do |line|
            if /^---/ =~ line
              @buffer.insert_linked(iter, "#{$'}\n", 'name')
            elsif /^\s*\*/ =~ line
              @buffer.insert_linked(iter, "   *#{$'}\n", 'item')
            elsif /^\s{4}/ =~ line
              @buffer.insert_linked(iter, "  #{$'}\n", 'normal')
            else
              @buffer.insert_linked(iter, "  #{line}\n", 'normal')
            end
          end
        elsif spec
          @buffer.insert(iter, _("(no document)\n"), 'nodata')
        end
      rescue RBBR::Doc::LookupError
      ensure
        thaw_notify
      end
      @buffer.move_mark("insert", @buffer.start_iter)
      @buffer.move_mark("selection_bound", @buffer.start_iter)
    end
  end
end;end;end
