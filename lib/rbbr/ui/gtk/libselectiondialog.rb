=begin

  rbbr/ui/gtk/windowutils.rb 

  $Author: mutoh $
  $Date: 2004/03/27 14:01:54 $

  Copyright (C) 2002 Ruby-GNOME2 Project

  Copyright (C) 2000-2002 Hiroshi Igarashi <iga@ruby-lang.org>

  This program is free software.
  You can distribute/modify this program under
  the terms of the Ruby Distribute License.

=end

module RBBR
module UI
module GTK
  class LibrarySelectionDialog < Gtk::Dialog
    include GetText
    GetText.bindtextdomain("rbbr", nil, nil, "UTF-8")

    def initialize(parent, confmanager, moduleviews)
      super(_("Select libraries"), parent, Gtk::Dialog::MODAL, 
            [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
            [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK])
      set_default_response(Gtk::Dialog::RESPONSE_CANCEL)
      set_default_size(400, 400)
      set_has_separator(false)
      set_border_width(6)
      vbox.spacing = 12

      treeview_title = Gtk::Label.new(_("Check target libraries:"))
      vbox.pack_start(treeview_title, false, false)
 
      treeview_scwin = Gtk::ScrolledWindow.new
      vbox.pack_start(treeview_scwin)
      treeview_scwin.set_policy(Gtk::POLICY_AUTOMATIC,
                                Gtk::POLICY_AUTOMATIC)
      @added_libs = []
      @removed_libs = []
      @confmanager = confmanager
      #text, type, toggle, visible, activatable
      @model = Gtk::TreeStore.new(String, String, TrueClass, TrueClass, TrueClass) 
      
      # first column
      toggled = Gtk::CellRendererToggle.new
      toggled.activatable = true
      toggled.signal_connect('toggled') do |cell, path|
        toggled_recursive(@model.get_iter(path))
      end
      text = Gtk::CellRendererText.new
      column = Gtk::TreeViewColumn.new
      column.title = _("Libraries Tree")
      column.pack_start(toggled, true)
      column.set_cell_data_func(toggled) do |column, cell, model, iter|
        cell.active = iter[2]
        cell.visible = iter[3]
        cell.activatable = ! iter[4]
      end
      column.pack_start(text, true)
      column.set_cell_data_func(text) do |column, cell, model, iter|
        cell.text = iter[0]
        cell.foreground = iter[4] ? "gray" : "black"
      end
      column.sort_column_id = 1

      # 2nd column
      renderer = Gtk::CellRendererText.new

      # TreeView
      treeview = Gtk::TreeView.new(@model)
      treeview.selection.mode = Gtk::SELECTION_SINGLE
      treeview.rules_hint = true
      treeview.grab_focus
      treeview.append_column(column)
      treeview.append_column(Gtk::TreeViewColumn.new(_("Type"), renderer, :text => 1))
      treeview_scwin.add(treeview)

      root = @model.append(nil)
      root.set_value(0, _("Libraries"))
      ($: - ["."]).sort.each do |path|
        build(path, root, true)
      end
      treeview.expand_row(root.path, false)

      show_all

      if run == Gtk::Dialog::RESPONSE_OK
        @confmanager.add_libs(@added_libs)
        @confmanager.remove_libs(@removed_libs)
        moduleviews.each do |moduleview|
          moduleview.update(RBBR::MetaInfo::ModuleDAG.full_module_dag)
        end
      end
      destroy
    end

    def build(path, parent, first = false)
      if File.file?(path)
        iter = nil
        if /(.*)\.(rb|so)$/ =~ File.basename(path)
          lm = Regexp.last_match
          if File.dirname(path) == parent[0]
            feature = lm[1]
          else
            feature = parent[0] + "/" + lm[1]
          end
          file_type = lm[2]
          iter = @model.append(parent)
          iter[0] = feature
          iter[1] = file_type
          iter[2] = @confmanager.include_lib?(feature)
          iter[3] = true
          iter[4] = parent[4] ? true : DEFAULT_LIBS.include?(feature)
        end
      else
        if first
          iter = @model.append(parent)
          iter[0] = path
          iter[3] = false
        elsif /^(rbbr|\d.\d|i686-linux)/ =~ File.basename(path)
          return
        else
          iter = @model.append(parent)
          iter[0] = File.basename(path)
          iter[3] = true
        end

        iter[1] = ""
        iter[2] = @confmanager.include_lib?(iter[0])
        iter[4] = parent[4] ? true : DEFAULT_LIBS.include?(iter[0])

        dirs = Dir.glob(path + "/*")
        dirs.select{|v| File.file?(v)}.sort.each do |v|
          build(v, iter)
        end
        dirs.select{|v| File.directory?(v)}.sort.each do |v|
          build(v, iter)
        end
      end
    end
    
    def toggled_recursive(iter, force = nil)
      return if iter[4]
      toggle_item = iter[2]
      if force == nil
        iter[2] = ! toggle_item
      else
        iter[2] = force
      end
      if iter[2]
        @added_libs -= [iter[0]]
        @added_libs << iter[0]
      else
        @removed_libs -= [iter[0]]
        @removed_libs << iter[0]
      end
      if iter.has_child?
        (0...iter.n_children).each do |i|
          toggled_recursive(iter.nth_child(i), iter[2])
        end
      end
    end
  end

end;end;end
