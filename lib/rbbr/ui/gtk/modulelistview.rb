=begin

  rbbr/ui/gtk/modulelistview.rb 

  $Author: mutoh $
  $Date: 2004/01/10 18:30:16 $

  Copyright (C) 2003 Ruby-GNOME2 Project

  This program is free software.
  You can distribute/modify this program under
  the terms of the Ruby Distribute License.

=end

module RBBR
module UI
module GTK

  class ModuleListView < ModuleView
    include GetText
    GetText.bindtextdomain("rbbr", nil, nil, "UTF-8")
    
    def initialize(search_entry)
      @model = Gtk::ListStore.new(String, Module)
      @column = Gtk::TreeViewColumn.new(_("Classes / Modules"), 
                                        Gtk::CellRendererText.new, :text => 0)
      @old_target = nil
      super(search_entry, @model, @column)
    end
    
    def search_impl(module_name, method_name)
      if @old_target != module_name
	build_tree(module_name)
	if iter = @model.iter_first
	  selection.select_iter(iter) 
	end
	@old_target = module_name
	ret = false
      end
      if method_name
	ret = true
	if iter = selection.selected
	  begin
	    path = iter.path
	    selection.select_path(path)
	    ret = signal_emit("next_search_method", method_name)
	    unless ret
	      scroll_to_cell(path, @column, true, 0.5, 0.5)
	      row_activated(path, @column)
	      set_cursor(path, @column, false)
	      return false
	    end 
	  end while(iter.next!)
	end
      end
      ret
    end
    
    def build_tree(target_name = nil)
      @model.clear
      freeze_notify
      
      subclasses = []
      @dag.each do |parent, klass, _|
        if /#{target_name}/i =~ klass.inspect and /^(RBBR|ReFe|RI|\#\<)(::)?/ !~ klass.inspect
          subclasses << klass
        end
      end
      subclasses.uniq.sort{|x, y| x.inspect <=> y.inspect}.each do |c|
        iter = @model.append
        iter[0] = c.inspect
        iter[1] = c
      end
      selection.signal_connect("changed") do |e|
        iter = selection.selected
        if iter
          klass = iter[1]
          if Module === klass
            changed
            notify_observers(klass)
          end
        else
          notify_observers(nil)
        end
      end
      thaw_notify
    end
  end

end;end;end
