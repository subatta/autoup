require_relative '../lib/autoup'
require_relative '../lib/constants'
require 'test/unit'
require 'json'

class TestUpgradeAll < Test::Unit::TestCase

  def test_config_load_files_exist_pass

    Dir.chdir Constants::SPEC if File.basename(Dir.pwd) != Constants::SPEC

    upgradeall = UpgradeAll.new Dir.pwd + '/samples/manifest.json'

    assert_not_equal upgradeall.manifest, nil

    Dir.chdir Constants::PARENTDIR

  end

  def test_config_load_files_exist_fail

    Dir.chdir Constants::SPEC if File.basename(Dir.pwd) != Constants::SPEC

    upgradeall = UpgradeAll.new ''

    assert_equal upgradeall.manifest, nil

    Dir.chdir Constants::PARENTDIR

  end

  def test_upgradeall_local

    Dir.chdir Constants::SPEC if File.basename(Dir.pwd) != Constants::SPEC

    test_manifest_path = Dir.pwd + '/samples/manifest.json'
    test_manifest = JSON.parse File.read(test_manifest_path) if File.exist? test_manifest_path

    # test file set to unprocessed
    assert_equal true, validate_status_all(test_manifest, Constants::UNPROCESSED)

    upgradeall = UpgradeAll.new test_manifest_path
    iv = InputValidator.new
    iv.test_mode

    status = upgradeall.Do iv
    assert_equal true, status

    # after upgrade, status should be reset
    modified_manifest = upgradeall.manifest
    assert_equal true, validate_status_all(modified_manifest, Constants::UNPROCESSED)

    Dir.chdir Constants::PARENTDIR

  end

  def test_upgradeall_local_skipped_with_success_status

    Dir.chdir Constants::SPEC if File.basename(Dir.pwd) != Constants::SPEC

    test_manifest_path = Dir.pwd + '/samples/manifest_status_reset.json'
    test_manifest = JSON.parse File.read(test_manifest_path) if File.exist? test_manifest_path

    # test file set to unprocessed
    assert_equal true, validate_status_all(test_manifest, Constants::SUCCESS)

    upgradeall = UpgradeAll.new test_manifest_path
    iv = InputValidator.new
    iv.test_mode

    status = upgradeall.Do iv
    assert_equal true, status

    modified_manifest = upgradeall.manifest
    assert_equal true, validate_status_all(modified_manifest, Constants::UNPROCESSED)

    Dir.chdir Constants::PARENTDIR

  end

  def test_set_status_unprocessed_pass

    Dir.chdir Constants::SPEC if File.basename(Dir.pwd) != Constants::SPEC

    test_manifest_path = Dir.pwd + '/samples/manifest_status_reset.json'
    test_manifest = JSON.parse File.read(test_manifest_path) if File.exist? test_manifest_path

    # test file set to success
    assert_equal true, validate_status_all(test_manifest, Constants::SUCCESS)

    upgradeall = UpgradeAll.new test_manifest_path
    modified_manifest =  upgradeall.reset_status_unprocessed

    # modified file set to unprocessed
    assert_equal true, validate_status_all(modified_manifest, Constants::UNPROCESSED)

  end

  def validate_status_all manifest, status
    is_equal = false
    manifest['projects'].each { |proj|
      proj.each { |item|
        is_equal = item['metadata']['status'] == status if item.class.to_s != 'String'
      }
    }
    is_equal
  end

end
