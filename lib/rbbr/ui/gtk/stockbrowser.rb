=begin

  rbbr/ui/gtk/stockview.rb 

  $Author: mutoh $
  $Date: 2004/03/25 14:47:28 $

  Copyright (C) 2002 Ruby-GNOME2 Project

  This program is free software.
  You can distribute/modify this program under
  the terms of the Ruby Distribute License.

=end

if __FILE__ == $0 
  # If you use this file directly, you need to 
  #install Ruby-GetText-Package.
  require 'gettext'
end

require 'gtk2'
require 'observer'

module RBBR
module UI
module GTK
  class StockCont < Gtk::Frame
    include GetText
    GetText.bindtextdomain("rbbr", nil, nil, "UTF-8")

    def initialize
      super(_("Selected Item - Gtk::IconSize"))
      set_height_request(130)
      box = Gtk::HBox.new
      @image = Hash.new
      @size_type = ["DIALOG", "DND", "LARGE_TOOLBAR", "BUTTON", "SMALL_TOOLBAR", "MENU"]
      table = Gtk::Table.new(2, 6, true)
      cnt = 0
      @size_type.each do |size|
        @image[size] = Gtk::Image.new
        table.attach(@image[size], cnt, cnt + 1, 0, 1)
        table.attach(Gtk::Label.new(@size_type[cnt]), cnt, cnt + 1, 1, 2)
        cnt += 1
      end
      @table = table
      add(table)
    end
    def update(iter)
      if iter[1]
        stock = eval(iter[1])
        @size_type.each do |size|
          @image[size].set(stock, Gtk::IconSize.module_eval(size))
        end
      end
    end
  end

  class StockView < Gtk::TreeView
    include GetText
    GetText.bindtextdomain("rbbr", nil, nil, "UTF-8")

    include Observable
    def initialize
      @model = Gtk::ListStore.new(Gdk::Pixbuf, String, String, String, String)
      super(@model)

      # first column
      @pix = Gtk::CellRendererPixbuf.new
      @text = Gtk::CellRendererText.new
      @column = Gtk::TreeViewColumn.new
      @column.title = _("Constants")
      @column.pack_start(@pix, true)
      @column.set_cell_data_func(@pix) do |column, cell, model, iter|
        cell.pixbuf = iter[0] 
      end
      @column.pack_start(@text, true)
      @column.set_cell_data_func(@text) do |column, cell, model, iter|
        cell.text = iter[1]
      end
      @column.sort_column_id = 1
      append_column(@column)
      
      # other columns
      renderer = Gtk::CellRendererText.new
      labels = [_("Label"), _("Accel"), _("ID")]
      labels.each_index do |cnt|
        @column = Gtk::TreeViewColumn.new(labels[cnt], renderer, :text => cnt + 2)
        @column.sort_column_id = cnt + 2
        append_column(@column)
      end
      selection.mode = Gtk::SELECTION_SINGLE
      selection.signal_connect('changed') do
        iter = selection.selected
        changed
        notify_observers(iter) if iter
      end
      set_height_request(200)
      set_rules_hint(true)
      append_list
    end
      
    def append_list
      freeze_notify
      stocks = [Gtk::Stock]
      stocks << Gnome::Stock if $GNOME_SUPPORTED
    
      stocks.each do |mod_stock|
        mod_stock.constants.sort.each do |name|
          stock = mod_stock.module_eval(name)
          value = ""
          accel = ""
          begin
            stockinfo = Gtk::Stock.lookup(stock)
            value = stockinfo[1]
            value = "" unless value
            accel = Gtk::Accelerator.to_name(stockinfo[3], stockinfo[2])
            accel = "" unless accel
          rescue ArgumentError
          end
          append([render_icon(stock, Gtk::IconSize::MENU, value), 
                   mod_stock.name + "::" + name, 
                   value, accel, ":" + mod_stock.const_get(name).to_s
                 ])
        end
      end
      thaw_notify
    end

    def append(data)
      iter = @model.append
      iter[0] = data[0] if data[0]
      iter[1] = data[1]
      iter[2] = data[2]
      iter[3] = data[3]
      iter[4] = data[4]
    end
  end

  class StockWindow < Gtk::Window
    include GetText
    GetText.bindtextdomain("rbbr", nil, nil, "UTF-8")

    def initialize(conf)
      @conf = conf
      @conf["stockbrowser.x"] ||= 0
      @conf["stockbrowser.y"] ||= 0

      super()
      set_title(_("Stock Item and Icon Browser"))
      move(@conf["stockbrowser.x"], @conf["stockbrowser.y"])

      vbox = Gtk::VBox.new
      stockcont = StockCont.new
      stockcont.set_border_width(6)
      stockview = StockView.new
      stockview.add_observer(stockcont)

      # automatically select the first stock item 
      if iter = stockview.model.iter_first
        stockview.selection.select_iter(iter)
      end
      
      scroll = Gtk::ScrolledWindow.new
      scroll.set_policy(Gtk::POLICY_NEVER, Gtk::POLICY_AUTOMATIC)
      scroll.set_border_width(6)
      scroll.add(stockview)

      vbox.pack_start(scroll, true, true, 6)
      vbox.pack_start(stockcont, false, false, 6)

      hbox = Gtk::HButtonBox.new
      hbox.layout_style = Gtk::ButtonBox::END
      hbox.border_width = 10
      button = Gtk::Button.new(Gtk::Stock::CLOSE)
      button.signal_connect("clicked") do
	destroy
      end
      hbox.pack_end(button)
      vbox.pack_start(hbox)
      add(vbox)
      signal_connect("delete-event") do
	save_conf
	false
      end
    end

    def save_conf
      p "save config..." if $DEBUG
      x, y = window.root_origin
      @conf["stockbrowser.x"] = x < 0 ? 2 : x
      @conf["stockbrowser.y"] = y < 0 ? 2 : y
    end
  end
     
end;end;end

if __FILE__ == $0 
  Gtk.init
  stockdialog = RBBR::UI::GTK::StockWindow.new(Hash.new)
GC.start
  stockdialog.show_all
  Gtk.main
end
