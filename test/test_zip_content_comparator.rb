$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'zip_content_comparator'
require 'pp'

class Test_zip_content_comparator < Test::Unit::TestCase
  TEST_DATA_PATH = 'test/data/zip_content_comparator'
  def setup
    # HOOK: improve test file names (reference file, the same as reference file,
    #                                totally diferent file, a bit different file)
    @reference = File.join(TEST_DATA_PATH, 'reference_test_file.zip')
    @identical = File.join(TEST_DATA_PATH, 'identical_to_reference_test_file.zip')
    @one_file_added = File.join(TEST_DATA_PATH, 'one_file_added.zip')
    @one_file_changed = File.join(TEST_DATA_PATH, 'one_file_changed.zip')
    @one_file_deleted = File.join(TEST_DATA_PATH, 'one_file_deleted.zip')
    @one_file_added_deleted_and_changed = File.join(TEST_DATA_PATH, 'one_file_added_deleted_and_changed.zip')
    @modified_class_file = File.join(TEST_DATA_PATH, 'modified_class_file.zip')
  end

  def test_001_read_in_zipfiles
    zip_file1, zip_file2 = ZipContentComparator.read_in_files(@reference, @one_file_added)
    assert zip_file1
    assert zip_file2
    assert_kind_of Zip::ZipFile, zip_file1
    assert_kind_of Zip::ZipFile, zip_file2
  end

  def test_002_get_files_and_dirs_list
    zip_file1, zip_file2 = ZipContentComparator.read_in_files(@reference, @reference)
    directory_list, file_list = ZipContentComparator.get_files_and_dirs_list(zip_file1, '.')
    assert ! directory_list.empty?
    assert ! file_list.empty?
    assert_not_equal directory_list, file_list
    assert_equal ["prime", "even", "even/moultiplicityof6"].sort, directory_list
    assert_equal ["1",  "3",  "5.class",  "even/2",  "even/4",  "even/moultiplicityof6/6",
                  "even/moultiplicityof6/12.class", "prime/1",  "prime/2",  "prime/3",  "prime/5.class"].sort,
                  file_list
  end

  # Tests if the MD5 digest is equal for identical files placed in two separate ZIP files
  # systems (ZIP files). Every test file is in a different ZIP file.
  def test_003_md5_in_zipfilesystem_works
    file1 = Zip::ZipFile.open(@reference)
    file2 = Zip::ZipFile.open(@identical)
    directory_list1, file_list1 = ZipContentComparator.get_files_and_dirs_list(file1, '.')
    directory_list2, file_list2 = ZipContentComparator.get_files_and_dirs_list(file2, '.')
    assert_equal MD5.md5(file1.file.read(file_list1[0])),
                 MD5.md5(file2.file.read(file_list2[0]))
  end

  def test_004_compare_identical_zip_files
    zip_file1, zip_file2 = ZipContentComparator.read_in_files(@reference, @identical)
    directory_list1, file_list1 = ZipContentComparator.get_files_and_dirs_list(zip_file1, '.')
    directory_list2, file_list2 = ZipContentComparator.get_files_and_dirs_list(zip_file2, '.')
    identical_files, different_files = ZipContentComparator.compare_files(zip_file1, file_list1, zip_file2, file_list2)
    assert different_files.empty?
    assert ! identical_files.empty?
  end

  def test_012_compare_identical_zip_files
    identical_files, different_files = ZipContentComparator.compare(@reference, @identical)
    assert different_files.empty?
    assert !identical_files.empty?
    assert_equal 11, identical_files.size
  end

  def test_013_compare_different_zip_files
    identical_files, different_files = ZipContentComparator.compare(@reference, @one_file_changed)
    assert ! different_files.empty?
    assert ! identical_files.empty?
    assert_equal 1, different_files.size
    assert_equal 10, identical_files.size
    assert_equal ['3'], different_files
  end
  def test_014_compare_different_zip_files
    identical_files, different_files = ZipContentComparator.compare(@reference, @one_file_added)
    assert ! different_files.empty?
    assert ! identical_files.empty?
    assert_equal 1, different_files.size
    assert_equal 11, identical_files.size
    assert_equal ['prime/7'], different_files
  end
  def test_015_compare_different_zip_files
    identical_files, different_files = ZipContentComparator.compare(@reference, @one_file_deleted)
    assert ! different_files.empty?
    assert ! identical_files.empty?
    assert_equal 1, different_files.size
    assert_equal 10, identical_files.size
    assert_equal ['1'], different_files
  end
  def test_016_compare_different_zip_files
    identical_files, different_files = ZipContentComparator.compare(@reference, @one_file_added_deleted_and_changed)
    assert ! different_files.empty?
    assert ! identical_files.empty?
    assert_equal 3, different_files.size
    assert_equal 9, identical_files.size
    assert different_files.include?('1')
    assert different_files.include?('prime/7')
    assert different_files.include?('3')
  end

  def test_021_identical?
    assert ZipContentComparator.identical?(@reference, @identical)
  end
  def test_022_not_identical
    assert ! ZipContentComparator.identical?(@reference, @one_file_changed)
  end
  def test_023_identical_with_detect_pattern
    assert ZipContentComparator.identical?(@reference, @identical,
                                           :detect_pattern => /.class$/)
  end
  def test_024_not_identical_with_detect_pattern
    assert ! ZipContentComparator.identical?(@reference, @modified_class_file,
                                           :detect_pattern => /.class$/)
  end
  def test_025_identical_with_ignore_pattern
    assert ZipContentComparator.identical?(@reference, @identical,
                                           :ignore_pattern => /.class$/)
  end
  def test_026_not_identical_with_ignore_pattern
    assert ! ZipContentComparator.identical?(@reference, @modified_class_file,
                                           :ignore_pattern => /.class$/)
  end

  def test_041_example_from_doku_string
    identical_files, different_files = ZipContentComparator.compare(@reference, @identical)
    list_of_changed_class_files = different_files.detect{ |file| file =~ /.class$/ } || []
    assert list_of_changed_class_files.empty?
  end
  def test_042_example_from_doku_string
    identical_files, different_files = ZipContentComparator.compare(@reference, @modified_class_file)
    list_of_changed_class_files = different_files.detect{ |file| file =~ /.class$/ } || []
    assert ! list_of_changed_class_files.empty?
  end
end
