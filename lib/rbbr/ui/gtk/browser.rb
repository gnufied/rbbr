=begin

  rbbr/ui/gtk/browser.rb 

  $Author: mutoh $
  $Date: 2004/03/25 14:57:35 $

  Copyright (C) 2002,2003 Ruby-GNOME2 Project

  Copyright (C) 2000-2002 Hiroshi Igarashi <iga@ruby-lang.org>

  This program is free software.
  You can distribute/modify this program under
  the terms of the Ruby Distribute License.

=end

module RBBR
module UI
module GTK
  class Browser < Gtk::Window
    include WindowUtils
    include GetText
    GetText.bindtextdomain("rbbr", nil, nil, "UTF-8")

    def create_menubar
      cal_req = Proc.new{ 
        LibrarySelectionDialog.new(self, @conf, [@modulelist, @moduletree])
      }

      cal_load = Proc.new{
        fs = Gtk::FileSelection.new(_("Select a Ruby script"))
        fs.set_transient_for(self)
        filename = nil
        fs.show_all
        if fs.run == Gtk::Dialog::RESPONSE_OK
          filename = fs.filename
          begin
            if FileTest.file?(filename)
              load(filename)
              dag = RBBR::MetaInfo::ModuleDAG.full_module_dag
              @moduleview.get_nth_page(@moduleview.page).child.update(dag)
            else
              raise _("A folder was selected when a file was expected.")
            end
          rescue Exception
            show_error_message(_("Could not load the script '%s'") % filename, $!)
          end
        end
        fs.destroy
      }

      cal_quit = Proc.new{ save_conf; Gtk.main_quit }
      cal_expand = Proc.new{ @moduletree.expand_all }
      cal_fold = Proc.new{ @moduletree.collapse_all }
      cal_goback = Proc.new{ @undomanager.undo }
      cal_gonext = Proc.new{ @undomanager.redo }
      cal_update = Proc.new{ @moduletree.update(RBBR::MetaInfo::ModuleDAG.full_module_dag) }
      cal_stockbrowser = Proc.new{
        RBBR::UI::GTK::StockWindow.new(@conf).show_all
      }
      cal_about = Proc.new{
        aboutdialog = RBBR::UI::GTK::AboutDialog.new(self, @database)
        aboutdialog.run
        aboutdialog.destroy
      }

      accelgroup = Gtk::AccelGroup.new
      add_accel_group(accelgroup)
      ifp = Gtk::ItemFactory.new(Gtk::ItemFactory::TYPE_MENU_BAR, "<main>", accelgroup)

      ifp.create_items([
                         [_("/_File")],
                         [_("/_File/_Require Library..."), "<StockItem>", "<control>L", Gtk::Stock::ADD, cal_req],
                         [_("/_File/_Load Script..."), "<StockItem>", "<control>O", Gtk::Stock::OPEN, cal_load],
                         [_("/_File/_Separator"), "<Separator>"],
                         [_("/_File/_Quit"), "<StockItem>", "<control>Q", Gtk::Stock::QUIT, cal_quit],
                         [_("/_View")],
                         [_("/_View/_Expand All"), "<StockItem>", "<control>E", Gtk::Stock::GOTO_BOTTOM, cal_expand],
                         [_("/_View/_Collapse All"), "<StockItem>", "<control>C", Gtk::Stock::GOTO_TOP, cal_fold],
                         [_("/_View/_Separator1"), "<Separator>"],
                         [_("/_View/Go _Back"), "<StockItem>", "<control>B", Gtk::Stock::GO_BACK, cal_goback],
                         [_("/_View/Go _Forward"), "<StockItem>", "<control>F", Gtk::Stock::GO_FORWARD, cal_gonext],
                         [_("/_View/_Separator2"), "<Separator>"],
                         [_("/_View/_Refresh"), "<StockItem>", "<control>R", Gtk::Stock::REFRESH, cal_update],
                         [_("/_View/_Separator"), "<Separator>"],
                         [_("/_View/_Stock Item and Icon Browser..."), "<Item>", "<control>I", "", cal_stockbrowser],
                         [_("/_Help")],
                         [_("/_Help/_About"), "<StockItem>", "", "", cal_about]
                       ])
   
      @back_menu = ifp.get_widget(_("/_View/Go _Back").gsub(/_/, ""))
      @forward_menu = ifp.get_widget(_("/_View/Go _Forward").gsub(/_/, ""))
      @back_menu.sensitive = false
      @forward_menu.sensitive = false

      @expand_menu = ifp.get_widget(_("/_View/_Expand All").gsub(/_/, ""))
      @collapse_menu = ifp.get_widget(_("/_View/_Collapse All").gsub(/_/, ""))

      ifp.get_widget("<main>")
    end

    def create_toolbar
      toolbar = Gtk::Toolbar.new
      toolbar.toolbar_style = Gtk::Toolbar::ICONS
      @back = toolbar.append(Gtk::Stock::GO_BACK, _("Go back")) do 
	@undomanager.undo
      end
      @forward = toolbar.append(Gtk::Stock::GO_FORWARD, _("Go forward")) do 
	@undomanager.redo
      end

      @back.sensitive = false
      @forward.sensitive = false

      toolbar.append_space
      # create search entry box
      @search_box = RBBR::UI::GTK::SearchEntryBox.new
      @search_box.signal_connect("search") do |w, name_space, method_name|
	@moduleview.get_nth_page(@moduleview.page).child.search(name_space, method_name)
      end
      toolbar.append(@search_box, _("Enter search class/module and method/constant"))  
      Gtk::HandleBox.new.add(toolbar)
    end

    def initialize 
      super

      @conf = ConfManager.new
      @undomanager = UndoManager.new

      @conf["main.x"] ||= 0
      @conf["main.y"] ||= 0
      @conf["main.width"] ||= 500
      @conf["main.height"] ||= 400
      @conf["leftpane.width"] ||= 250
      
      signal_connect("delete-event") do
        save_conf
        false
      end
      
      signal_connect("destroy") do
        Gtk.main_quit
      end

      # set title
      set_title(_("Ruby Browser"))

      # setting size, position
      set_default_size(@conf["main.width"], @conf["main.height"])
      move(@conf["main.x"], @conf["main.y"])

      # create document @database
      @database = Doc::MultiDatabase.new

      # create vbox
      vbox = Gtk::VBox.new(false, 0)
      add(vbox)

      # create menu
      menubar = create_menubar
      vbox.pack_start(menubar, false, false, 0)

      # create toolbar
      vbox.pack_start(create_toolbar, false, false, 0)

      # create main box
      main_paned = Gtk::HPaned.new
      vbox.pack_start(main_paned, true, true, 0)
      @index_paned = Gtk::VBox.new
      @index_paned.set_size_request(@conf["leftpane.width"], -1)
      main_paned.add(@index_paned)

      # create left pane
      @moduleview = Gtk::Notebook.new
      @index_paned.pack_start(@moduleview)
      dag = RBBR::MetaInfo::ModuleDAG.full_module_dag
      @modulelist = ModuleListView.new(@search_box.entry)
      @moduletree = ModuleTreeView.new(@search_box.entry)

      # create module display
      @module_display = ModuleDisplay.new(@database, @conf)

      [[@modulelist, _("_List")], [@moduletree, _("_Tree")]].each do |widget, text|
        scwin = Gtk::ScrolledWindow.new
        scwin.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
        scwin.add(widget)
	label = Gtk::Label.new(text)
	label.use_underline = true
        @moduleview.append_page(scwin, label)
	label.mnemonic_widget = widget
        Thread.start do
          widget.realize
	  widget.window.set_cursor(Gdk::Cursor.new(Gdk::Cursor::WATCH)) 
          widget.update(dag)
          widget.window.set_cursor(nil)
        end
	widget.signal_connect("next_search_method") do |w, method_name|
	  @module_display.search_method(method_name)
	end
	widget.add_observer(@module_display)
      end

      main_paned.add2(@module_display)

      @moduleview.signal_connect("switch-page") do |notebook, page, pagenum|
        # enable expand/collapse menu items when tree if choosed
        @expand_menu.sensitive = @collapse_menu.sensitive = pagenum == 1
      end

      # set icon
      set_icon(Gdk::Pixbuf.new(File.join(RBBR::Config::DATA_DIR, "icon.png")))

      @search_box.button.grab_default
      set_default(@search_box.button)
      @search_box.entry.grab_focus

      @undomanager.signal_connect("changed") do |w, undo_, redo_|
	@back.sensitive = undo_
	@forward.sensitive = redo_
	@back_menu.sensitive = undo_
	@forward_menu.sensitive = redo_
      end

      # Add Keyboard accelerations.
      ag = Gtk::AccelGroup.new
      ag.connect(Gdk::Keyval::GDK_Left, Gdk::Window::CONTROL_MASK,
		 Gtk::ACCEL_VISIBLE) do
	@moduleview.grab_focus
      end
      ag.connect(Gdk::Keyval::GDK_Right, Gdk::Window::CONTROL_MASK,
		 Gtk::ACCEL_VISIBLE) do
	@module_display.notebook.grab_focus
      end
      ag.connect(Gdk::Keyval::GDK_Down, Gdk::Window::CONTROL_MASK,
		 Gtk::ACCEL_VISIBLE) do
	if @module_display.module_label.has_focus?
	  @module_display.notebook.grab_focus
	else
	  @module_display.docviewer.grab_focus
	end
      end
      ag.connect(Gdk::Keyval::GDK_Up, Gdk::Window::CONTROL_MASK,
		 Gtk::ACCEL_VISIBLE) do
	if @module_display.docviewer.has_focus?
	  @module_display.notebook.grab_focus
	else
	  @module_display.module_label.grab_focus
	end
      end
      add_accel_group(ag)
    end

    def save_conf
      p "save config..." if $DEBUG
      #Save config
      @module_display.save_conf

      @conf["main.width"] = allocation.width
      @conf["main.height"] = allocation.height
      @conf["leftpane.width"] = @index_paned.allocation.width

      x, y = window.root_origin
      @conf["main.x"] = x < 0 ? 2 : x
      @conf["main.y"] = y < 0 ? 2 : y
    end
  end
end;end;end
