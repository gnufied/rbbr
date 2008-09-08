=begin

  rbbr/ui/gtk/searchentrybox.rb 

  $Author: mutoh $
  $Date: 2004/01/14 18:18:44 $

  Copyright (C) 2002-2004 Ruby-GNOME2 Project

  This program is free software.
  You can distribute/modify this program under
  the terms of the Ruby Distribute License.

=end

module RBBR
module UI
module GTK
  class SearchEntryBox < Gtk::HBox
    type_register

    signal_new("search", GLib::Signal::ACTION,
               nil,
               GLib::Type["void"],
               GLib::Type["VALUE"], GLib::Type["VALUE"])

    include Undoable
    include WindowUtils
    include GetText
    GetText.bindtextdomain("rbbr", nil, nil, "UTF-8")

    if RUBY_VERSION > "1.8.0"
      def regexp_warn?(str)
        class << (warning = "")
          alias write <<
        end 
        verbose, $VERBOSE = $VERBOSE, true
        stderr, $stderr = $stderr, warning
        Regexp.compile(str)
        warning[__FILE__.size..-1].sub(/\A:\d+:\s*/, '').chomp unless warning.empty?
      rescue RegexpError
        $!
      ensure
        $stderr = stderr
        $VERBOSE = verbose
      end
    else
      def regexp_warn?(str)
        Regexp.compile(str)
        nil
      rescue RegexpError
        $!
      end
    end

    attr_reader :entry, :button

    def initialize
      super()
      set_spacing(0)
      set_homogeneous(false)

      @entry = Gtk::Entry.new
      @entry.activates_default = true
      label = Gtk::Label.new(_("_Search Term:"))
      label.use_underline = true
      label.mnemonic_widget = @entry
      pack_start(label, true, true, 5)
      pack_start(@entry, true, true, 0)
      @button = Gtk::Button.new(_("Search"))
      pack_start(@button, true, true, 5)

      @button.signal_connect("clicked") do 
	ret = search(@entry.text)
	save_memento(ret) if ret
      end
      @button.set_flags(Gtk::Widget::CAN_DEFAULT|Gtk::Widget::HAS_DEFAULT)
    end

    def search(target)
      if /[\.\#]/ =~ target
	module_name = "^" + $` + "$"
	method_name = "^" + $'
      elsif /\s+/ =~ target
	module_name = $`
	method_name = $'
      else
	module_name = target
	method_name = nil
      end
      
      if str = regexp_warn?(module_name) || str = regexp_warn?(method_name.to_s) 
	show_warn_message(_("Could not compile \"%s\"") % target, str)
	return nil
      else
	signal_emit("search", module_name, method_name)
	return target
      end
    end

    def undo(data)
      if @entry.text == data
	false
      else
	@entry.text = data
	search(data)
	true
      end
    end

  end
end;end;end
