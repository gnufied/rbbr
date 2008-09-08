=begin

  rbbr/ui/gtk/windowutils.rb 

  $Author: lrz $
  $Date: 2003/12/26 21:11:14 $

  Copyright (C) 2002 Ruby-GNOME2 Project

  Copyright (C) 2000-2002 Hiroshi Igarashi <iga@ruby-lang.org>

  This program is free software.
  You can distribute/modify this program under
  the terms of the Ruby Distribute License.

=end

module RBBR
module UI
module GTK
  module WindowUtils
    module_function

    def show_error_message(title, error)
      show_message(title, error, Gtk::Stock::DIALOG_ERROR)
    end

    def show_warn_message(title, error)
      show_message(title, error, Gtk::Stock::DIALOG_WARNING)
    end

    def show_message(title, error, dialog_stock)
      ary = error.to_s.split(/\n/)
      if ary.size > 15
        message = ary[0...15].join("\n")
      else
        message = ary.join("\n")
      end

      dialog = Gtk::Dialog.new("",
                               nil,
                               Gtk::Dialog::DESTROY_WITH_PARENT,
                               [ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ])
      dialog.border_width = 6
      dialog.resizable = false
      dialog.has_separator = false
      dialog.default_response = Gtk::Dialog::RESPONSE_OK
      dialog.vbox.spacing = 12
     
      hbox = Gtk::HBox.new(false, 12)
      hbox.border_width = 6
      dialog.vbox.pack_start(hbox)

      image = Gtk::Image.new(dialog_stock, Gtk::IconSize::DIALOG)
      image.set_alignment(0.5, 0)
      hbox.pack_start(image)

      vbox = Gtk::VBox.new(false, 6)
      hbox.pack_start(vbox)

      label = Gtk::Label.new
      label.set_alignment(0.5, 0)
      label.wrap = true
      label.markup = "<b><big>#{title}</big></b>"
      vbox.pack_start(label)

      label = Gtk::Label.new(message.strip)
      label.set_alignment(0.5, 0)
      label.wrap = true
      vbox.pack_start(label)
     
      dialog.show_all
      dialog.run
      dialog.destroy
    end
  end
end;end;end
