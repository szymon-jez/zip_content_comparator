#!/usr/bin/env -w ruby
begin
  require 'rubygems'
  require 'zip/zipfilesystem' # from gem: rubyzip
  require 'md5'
rescue LoadError => e
  $stderr.puts <<-STR
    Problem loading gems. Please check if you have:
     * rubygems (gem),
     * rubyzip (gem),
     * md5 (library),
    in your load paths installed.
  STR
  $stderr.puts e
  exit!
end

# == Zip File Content Comparator
# An utility for comparing content of ZIP files.
#
# It does not extract the files anywhere, its's using instead ZIP::ZipFile class
# from RubyGem: rubyzip which enables to access ZIP files like a file system.
# It uses MD5 to compare files.
# For more info see documentation for #compare and #identical? methods.
#
# === Example:
#  # using the #compare method:
#  identical_files, different_files = ZipContentComparator.compare('old_build/myapp.jar','new_build/myapp.jar')
#  list_of_changed_class_files = different_files.detect{ |file| file =~ /.class$/ } || []
#  # using the #identical? method:
#  ZipContentComparator.identical?('old_build/myapp.jar','new_build/myapp.jar', :detect_pattern => /.class$/)
# 
# See the source code if you want to use other methods of this class.
#
# Author:: Szymon (jeznet) Jeż <szymon@jez.net.pl>
class ZipContentComparator
  def self.read_in_files(path_to_zipfile1, path_to_zipfile2)
    zip_file1 = Zip::ZipFile.open(path_to_zipfile1) #{
    zip_file2 = Zip::ZipFile.open(path_to_zipfile2)
    return zip_file1, zip_file2
  end

  # recurrently builds and returns a list of all files and directories in a given path of the given ZIP file
  def self.get_files_and_dirs_list(zip_file, path)
    dirs = []
    files = []
    zip_file.dir.foreach(path) do |file_system_node|
      path_to_node = (path == '.' ? file_system_node : File.join(path, file_system_node))
      if zip_file.file.file?(path_to_node)
        files << path_to_node
      elsif zip_file.file.directory?(path_to_node)
        dirs << path_to_node
      end
    end
    unless dirs.empty?
      dirs.each do |dir|
        d,f = get_files_and_dirs_list(zip_file, dir) # Why is there no multi assign += operator? :'(
        dirs += d
        files += f
      end
    end
    return dirs.sort, files.sort
  end

  # compare files in ZIP files using MD5
  def self.compare_files(zip_file1, file_list1, zip_file2, file_list2)
    different_files = []
    identical_files = []
    file_list1.each do |file1|
      if zip_file2.file.exists?(file1)
        hash1 = MD5.md5(zip_file1.file.read(file1))
        hash2 = MD5.md5(zip_file2.file.read(file1))
        if hash1 != hash2
          #add files with different hashes
          different_files << file1
        else
          identical_files << file1
        end
      else
        # add files not existing in zip_file2
        different_files << file1
      end
    end
    file_list2.each do |file2|
      # add files not existing in zip_file1 (new in zip_file2)
      unless zip_file1.file.exists?(file2)
        different_files << file2
      end
    end
    return identical_files, different_files
  end

  # Compares two ZIP files. Takes two paths to ZIP files. Compares them and
  # returns a list of files (exactly paths + file names) which are identical in both
  # of them and a list of files which are different (changed, added, deleted).
  def self.compare(path_to_zipfile1, path_to_zipfile2)
    zipfile1, zipfile2 = read_in_files(path_to_zipfile1, path_to_zipfile2)
    directory_list1, file_list1 = get_files_and_dirs_list(zipfile1, '.')
    directory_list2, file_list2 = get_files_and_dirs_list(zipfile2, '.')
    identical_files, different_files = compare_files(zipfile1, file_list1, zipfile2, file_list2)
    return identical_files, different_files
  end

  # Checks if the content of two given ZIP files is identical.
  # It compares the files contained in them. Regular Expression patterns can be used to
  # select which files will be compared to determine if the ZIP files are identical.
  #
  # optional arguments are:
  # Regexp :detect_pattern - used to select those files which will be used to determine if
  # the ZIP files are identical. Default is /.*/
  # Regexp :ignore_patter - used to ignore files which will be used to determine if
  # the ZIP files are identical
  def self.identical?(path_to_zipfile1, path_to_zipfile2, options = {})
    options = {:detect_pattern => /.*/, :ignore_patter => nil}.merge(options)
    identical_files, different_files = self.compare(path_to_zipfile1, path_to_zipfile2)
    if options[:detect_pattern].is_a?(Regexp)
      different_files = different_files.detect{ |file| file =~ options[:detect_pattern] } || []
    end
    if options[:ignore_patter].is_a?(Regexp)
      different_files = different_files.delete_if{ |file| file =~ options[:ignore_patter] } || []
    end
    return different_files.empty?
  end
end

# when ran as a script
if $0 == __FILE__
  if ARGV[0] and ARGV[1]
    identical_files, different_files = ZipContentComparator.compare(ARGV[0].strip.to_s, ARGV[1].strip.to_s)
    puts "Identical files:"
    puts identical_files.inspect
    puts "Different files:"
    puts different_files.inspect
  else
    puts 'Error. Please provide arguments 1 and 2 (paths to files to compare)'
  end
end
