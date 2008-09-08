=begin

  rbbr/ui/gtk/moduletreeview.rb 

  $Author: mutoh $
  $Date: 2004/01/10 18:30:16 $

  Copyright (C) 2003,2004 Ruby-GNOME2 Project

  This program is free software.
  You can distribute/modify this program under
  the terms of the Ruby Distribute License.

=end

module RBBR
module UI
module GTK

  class ModuleTreeView < ModuleView
    include GetText
    GetText.bindtextdomain("rbbr", nil, nil, "UTF-8")
   
    def initialize(search_entry)
      @model = Gtk::TreeStore.new(String, Module)
      @column = Gtk::TreeViewColumn.new(_("Classes / Modules"), 
					Gtk::CellRendererText.new, :text => 0)
      super(search_entry, @model, @column)
    end

    def search_impl(module_name, method_name)
      start_iter = selection.selected
      start_iter = @model.iter_first unless start_iter
      started = false
      @model.each do |m, path, iter|
        started = true if iter == start_iter && method_name
        if started
          if /#{module_name}/i =~ iter[0]
            expand_path = ""
            path.indices.each {|v|
              expand_path += ":" if expand_path.size > 0
              expand_path += v.to_s
              expand_row(Gtk::TreePath.new(expand_path), false)
            }
            selection.select_path(path)
                                                                                     
            ret = signal_emit("next_search_method", method_name)
            unless ret
              scroll_to_cell(path, @column, true, 0.5, 0.5)
              row_activated(path, @column)
              set_cursor(path, @column, false)
              return false
            end
          end
        elsif iter == start_iter && ! method_name
          started = true
        end
      end
      true
    end
    
    def build_tree
      @model.clear
      freeze_notify
      root = @model.append(nil)
      root.set_value(0, _("<root>"))
      root.set_value(1, nil)
      append_children(root, Object)
      
      root_module_iter = @model.append(root)
      root_module_iter.set_value(0, _("<modules>"))
      root_module_iter.set_value(1, nil)
      
      root_modules = (@dag.roots - [Object]).sort{|x, y| x.inspect <=> y.inspect}
      root_modules.each do |root_module|
        append_children(root_module_iter, root_module)
      end

      selection.signal_connect("changed") do |e|
        iter = selection.selected
        if iter
	  klass = iter.get_value(1)
	  if Module === klass
	    changed
	    notify_observers(klass)
	  end
        end
      end
      
      expand_row(root.path, false)
      thaw_notify
    end
    
    def append_children(titer, klass)
      return if klass.inspect =~ /^(RBBR|ReFe|RI)(::)?/
      child_iter = @model.append(titer)
      child_iter.set_value(0, klass.inspect)
      child_iter.set_value(1, klass)
      subclasses = @dag.arc(klass)
      subclasses.sort{|x, y| x.inspect <=> y.inspect}.each do |c|
        append_children(child_iter, c)
      end
    end
end

end;end;end
