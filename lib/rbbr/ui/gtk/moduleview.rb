=begin

  rbbr/ui/gtk/moduleview.rb

  $Author: mutoh $
  $Date: 2004/01/12 01:28:17 $

  Copyright (C) 2004 Ruby-GNOME2 Project

  This program is free software.
  You can distribute/modify this program under
  the terms of the Ruby Distribute License.

=end

module RBBR
  module UI
    module GTK

      class ModuleView < Gtk::TreeView
        type_register

        #Return true if "next_search_method" doesn't match with the method_name.
        signal_new("next_search_method", GLib::Signal::ACTION,
                   nil,
                   GLib::Type["gboolean"],
                   GLib::Type["VALUE"])

        include Undoable
        include Observable

        include GetText
        GetText.bindtextdomain("rbbr", nil, nil, "UTF-8")

        def initialize(search_entry, model, column)
          @search_entry = search_entry
          @model = model
          @column = column

          @first = true

          super()
          set_model(@model)
          append_column(@column)
          selection.set_mode(Gtk::SELECTION_SINGLE)

          signal_connect("cursor-changed") do |w|
            selected_object = selection.selected
            if selected_object
              data = selected_object.path.to_str
              if @first
                @first = false
                save_memento(nil)
              elsif data
                save_memento(data)
              end
            end
          end
        end

        def undo(data)
          iter = selection.selected
          cur_data = iter.path.to_str if iter
          if cur_data == data
            false
          else
            if data
              path = Gtk::TreePath.new(data)
              selection.select_path(path)
              notify_observers(eval(iter[0])) if iter
            else
              path = Gtk::TreePath.new("0")
              selection.select_path(path)
              selection.unselect_all
            end
            # scroll_to_cell(path, @column, true, 0, 0)
            scroll_to_point(0, -1)
            true
          end
        end

        def update(dag)
          @first = true
          @dag = dag
          build_tree
        end

        def search_impl(module_name, method_name)
          #Return true if it keeps to search next one.
          p "not implemented."
        end

        def search(module_name, method_name)
          @first = true
          if search_impl(module_name, method_name)

            dialog = Gtk::MessageDialog.new(nil, Gtk::Dialog::MODAL,
                                            Gtk::MessageDialog::INFO,
                                            Gtk::MessageDialog::BUTTONS_OK_CANCEL,
                                            _("The text you entered was not found. Wrap arround?"))
            ret = dialog.run
            dialog.destroy
            if ret == Gtk::Dialog::RESPONSE_OK
              if iter = @model.iter_first
                selection.select_iter(iter)
              end
              search(module_name, method_name)
            else
              @search_entry.grab_focus
            end
          end
        end

        def build_tree
          p "not implemented."
        end
      end

    end
  end
end
