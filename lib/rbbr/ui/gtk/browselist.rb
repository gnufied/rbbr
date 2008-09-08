=begin

  rbbr/ui/gtk/browselist.rb 

  $Author: mutoh $
  $Date: 2004/01/28 17:57:22 $

  Copyright (C) 2002,2003 Ruby-GNOME2 Project

  Copyright (C) 2000-2002 Hiroshi Igarashi <iga@ruby-lang.org>

  This program is free software.
  You can distribute/modify this program under
  the terms of the Ruby Distribute License.

=end

module RBBR
module UI
module GTK

  class BrowseList < Gtk::TreeView
    include Undoable
    include Observable
    include GetText
    GetText.bindtextdomain("rbbr", nil, nil, "UTF-8")

    def initialize(labels)
      @model = create_model(labels)
      super(@model)
      
      renderer = Gtk::CellRendererText.new
      @columns = []
      labels.each_index do |cnt|
	column = create_column(labels[cnt], renderer, cnt)
        column.sort_column_id = cnt
	@columns << column
        append_column(column)
	@first = true
      end
      
      selection.mode = Gtk::SELECTION_SINGLE
      selection.signal_connect('changed') do |e|
        iter = selection.selected
        changed
        notify_selection(@modul, iter) if iter
      end

      signal_connect("cursor-changed") do
	data = selection.selected.path.to_str
	if @first
	  @first = false
	  save_memento(nil)
	elsif data
	  save_memento(data)
	end
      end

      set_rules_hint(true)
    end

    def undo(data)
      @first = true
      iter = selection.selected
      cur_data = iter.path.to_str if iter
      if cur_data == data
	false
      else
	if data
	  path = Gtk::TreePath.new(data)
	  selection.select_path(path)
	else
	  path = Gtk::TreePath.new("0")
	  selection.select_path(path)
	  selection.unselect_all
	  unselect_all
	end
	scroll_to_cell(path, @columns[0], true, 0.5, 0.5)
	true
      end
    end

    private
    def notify_selection(m, text)
      # should be overridden in sub classes
    end

    def create_model(labels)
      Gtk::ListStore.new(*labels.collect{|label| label.class})
    end

    def create_column(label, renderer, cnt)
      Gtk::TreeViewColumn.new(label, renderer, :text => cnt)
    end

    public
    def update(modul)
      @first = true
      freeze_notify
      @model.clear
      update_list(modul)
      thaw_notify
      @modul = modul
    end
    
    def append(data)
      iter = @model.append
      data.each_index do |cnt|
        iter[cnt] = data[cnt]
      end
    end
    
    def update_list(modul)
      # should be overridden in sub classes
    end

    def search(target_name, start_iter = nil)
      @first = true
      start_iter = selection.selected unless start_iter
      start_iter = @model.iter_first unless start_iter
      started = false
      @model.each do |m, path, iter|
        if started
          if /#{target_name}/i =~ iter[0]
            expand_path = ""
            path.indices.each {|v|
              expand_path += ":" if expand_path.size > 0
              expand_path += v.to_s
              expand_row(Gtk::TreePath.new(expand_path), false)
            }
            selection.select_path(path)
            scroll_to_cell(path, @columns[0], true, 0.5, 0.5)
            row_activated(path, @columns[0])
            set_cursor(path, @columns[0], false)
            return false
          end
	elsif iter == start_iter
	  started = true
        end
      end
      true
    end

    def selected
      iter = selection.selected
      iter ? iter[0] : nil
    end
  end

  class SignalList < BrowseList
    def initialize
      super([_("Name"), _("Return type"), _("Parameters")])
    end
    
    def update_list(modul)
      if modul < GLib::Instantiatable or modul < GLib::Interface
        modul.signals(false).each{|signal_name|
	  signal = modul.signal(signal_name)
          append([signal.name, signal.return_type.name,
                   signal.param_types.map{|t| t.name}.join(", ") ])
        }
      end
    end
    def notify_selection(modul, iter)
      notify_observers(modul, [iter.get_value(0), '::'])
    end
  end

  class PropertyList < BrowseList
    def initialize
      super([_("Name"), _("Type"), _("GType"), _("Flags"), _("Default")])
    end
    
    def append_prop(prop)
      flags = ''
      flags << 'r' if prop.readable?
      flags << 'w' if prop.writable?
      append([prop.name, prop.value_type.to_class.inspect,
               prop.value_type.name, flags,
               prop.value_default.inspect])
      
    end

    def update_list(modul)
      if modul <= GLib::Object
        modul.properties(false).sort.each do |prop_name|
          append_prop(modul.property(prop_name))
        end
      end
    end

    def notify_selection(modul, iter)
      name = iter[0]
      str = modul.property(name).blurb || ''
      notify_observers(modul, [iter.get_value(0), '::'], [], GLib.locale_to_utf8(str))
    end
  end

  class StyleList < PropertyList
    def update_list(modul)
      if modul <= Gtk::Widget
        modul.style_properties(false).sort.each do |prop_name|
          append_prop(modul.style_property(prop_name))
        end
      end
    end
    def notify_selection(modul, iter)
      name = iter[0]
      str = modul.style_property(name).blurb || ''
      notify_observers(modul, [iter.get_value(0), '::'], [], GLib.locale_to_utf8(str))
    end
  end

  class ChildPropertyList < PropertyList
    def update_list(modul)
      if modul <= Gtk::Container
        modul.child_properties(false).sort.each do |prop_name|
          append_prop(modul.child_property(prop_name))
        end
      end
    end
    def notify_selection(modul, iter)
      name = iter[0]
      str = modul.child_property(name).blurb || ''
      notify_observers(modul, [iter.get_value(0), '::'], [], GLib.locale_to_utf8(str))
    end
  end
end;end;end
