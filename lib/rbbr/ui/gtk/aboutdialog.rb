=begin

  rbbr/ui/gtk/about.rb 

  $Author: mutoh $
  $Date: 2004/03/28 14:34:06 $

  Copyright (C) 2002-2004 Ruby-GNOME2 Project

  This program is free software.
  You can distribute/modify this program under
  the terms of the Ruby Distribute License.

=end

require 'gtk2'

module RBBR
module UI
module GTK
  class AboutDialog < Gtk::Dialog
    include GetText
    GetText.bindtextdomain("rbbr", nil, nil, "UTF-8")

    def initialize(parent, db)
      about = %Q[<span size="xx-large" weight="bold" foreground="#440000">
<span foreground="#ff0000">R</span>u<span foreground="#ff0000">b</span>y <span foreground="#ff0000">Br</span>owser</span> <span foreground="#004400">Version #{RBBR::VERSION}</span>

<span foreground="#0000cc">Copyright (C) 2002-2004 Ruby-GNOME2 Project</span>
]

      ary = ["GLib #{GLib::VERSION.join(".")}", "GTK+- #{Gtk::VERSION.join(".")}"]
      with = ary.join("<span foreground=\"#002233\">, </span>")
      about << %Q[\n<span foreground="#ee0000">#{with}</span>]

      ary = ["Ruby #{RUBY_VERSION}", "Ruby/GLib #{GLib::BINDING_VERSION.join(".")}", "Ruby/GTK #{Gtk::BINDING_VERSION.join(".")}"]
      with = ary.join("<span foreground=\"#002233\">, </span>")
      about << %Q[\n<span foreground="#cc0000">#{with}</span>]

      with = ""
      ary = db.info
      if ary.size > 1
        with = ary.join("<span foreground=\"#002233\">, </span>")
      elsif ary.size == 1
        with = ary[0]
      end
      about << %Q[\n<span style="italic" foreground="#bb0000">#{with}</span>] if with.size > 0

      super(_("About this application"), parent, Gtk::Dialog::MODAL,  
            [Gtk::Stock::CLOSE, Gtk::Dialog::RESPONSE_DELETE_EVENT])
      set_default_size(520, 420)
      set_default_response(Gtk::Dialog::RESPONSE_DELETE_EVENT)
      set_has_separator(false)

      icon = Gtk::Image.new(File.join(RBBR::Config::DATA_DIR, "icon.png"))
      label = Gtk::Label.new.set_markup(about)
      label.set_padding(10, 10)
      label.set_justify(Gtk::JUSTIFY_CENTER)
      hbox = Gtk::HBox.new
      hbox.pack_start(icon, false, false, 20)
      hbox.pack_start(label, true, true, 0)
      hbox.set_border_width(6)
      vbox.pack_start(hbox, false, false, 0)

      scwin = Gtk::ScrolledWindow.new
      scwin.set_border_width(6)
      vbox.pack_start(scwin, true, true, 8)

      model = Gtk::ListStore.new(String, String)
      renderer = Gtk::CellRendererText.new

      list = Gtk::TreeView.new(model)
      list.set_rules_hint(true)
      column1 = Gtk::TreeViewColumn.new(_("Name"), renderer, {:text => 0})
      column1.sort_column_id = 0
      column2 = Gtk::TreeViewColumn.new(_("Value"), renderer, {:text => 1})
      column2.sort_column_id = 1
      list.append_column(column1)
      list.append_column(column2)
      ::Config::CONFIG.keys.sort.each do |k|
        iter = model.append
        iter.set_value(0, k)
        iter.set_value(1, ::Config::CONFIG[k].inspect)
      end
      scwin.add(list)
      show_all
    end
  end
end;end;end

if __FILE__ == $0 
  Gtk.init
  dialog = RBBR::UI::GTK::AboutDialog.new
  dialog.run
  dialog.destroy
end
