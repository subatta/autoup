require_relative '../lib/autoup'
require 'test/unit'

class TestVersionMap < Test::Unit::TestCase

  def test_norepo_returns_nil
    vm = VersionMap.new
    versions = vm.version_map nil, nil
    assert_equal nil, versions
    Dir.chdir Constants::PARENTDIR
  end

  def test_param_hasrepourl_nobranch_returns_nil
    vm = VersionMap.new
    versions = vm.version_map 'http://github.com/test.git', nil
    assert_equal nil, versions
    Dir.chdir Constants::PARENTDIR
  end

  def test_param_hasbadrepourl_returns_nil
    vm = VersionMap.new
    versions = vm.version_map 'http://', nil
    assert_equal nil, versions
    Dir.chdir Constants::PARENTDIR
  end

  def test_hasrepo_hasbranch_returns_empty_hash_if_bad_repo
    vm = VersionMap.new
    versions = vm.version_map 'http://github.com/test.git', 'master'
    assert_equal nil, versions
    Dir.chdir Constants::PARENTDIR
  end

  def test_hasrepo_nobranch_returns_nil_for_real_repo
    vm = VersionMap.new
    versions = vm.version_map Constants::TEST_REPO, 'xyz'
    assert_equal nil, versions
    Dir.chdir Constants::PARENTDIR
  end

  def test_hasrepo_hasbranch_returns_hash_for_real_repo
    vm = VersionMap.new
    versions = vm.version_map Constants::TEST_REPO, 'master'
    assert_not_equal nil, versions
    Dir.chdir Constants::PARENTDIR
  end
end
