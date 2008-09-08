=begin
  pre-setup.rb

  Copyright(c) 2003 Masao Mutoh <mutoh@highway.ne.jp>
  This program is licenced under the same licence as Ruby.

  $Author: mutoh $
  $Date: 2004/03/26 16:21:41 $
                                                                                
  Original file is pre-setup.rb from Ruby-GetText-Package. 
    Copyright(c) 2001-2003 Masao Mutoh <mutoh@highway.ne.jp>
    This program is licenced under the same licence as Ruby.
=end

podir = srcdir_root + "/po/"
modir = srcdir_root + "/data/locale/%s/LC_MESSAGES/"
ruby = File.join(Config::CONFIG['bindir'], Config::CONFIG['RUBY_INSTALL_NAME'])
rmsgfmt = File.join(Config::CONFIG['bindir'], 'rmsgfmt')

#
# Create mo files.
#
begin 
  require 'gettext'

  Dir.glob("po/*/*.po") do |file|
    lang, basename = /po\/([\w\.]*)\/(.*)\.po/.match(file).to_a[1,2]
    molangdir = (modir % lang).split("/")
    molangdir.each_index {|i|
      if i > 0
        Dir.mkdir(molangdir[0..i].join("/")) unless FileTest.exist?(molangdir[0..i].join("/"))
      end
    }
    system("#{ruby} #{rmsgfmt} po/#{lang}/#{basename}.po -o #{modir % lang}#{basename}.mo")
  end
rescue LoadError
  puts "L10n is not supported on this environment."
end
