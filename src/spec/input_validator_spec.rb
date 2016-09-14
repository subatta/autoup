require 'test/unit'
require 'json'
require_relative '../lib/input_validator'
require_relative '../lib/hash_extensions'
require_relative '../lib/constants'

class TestUpgrade < Test::Unit::TestCase

  def test_manifest_validate

    Dir.chdir Constants::SPEC if File.basename(Dir.pwd) != Constants::SPEC

    manifest_file = Dir.pwd + '/samples/manifest.json'
    if File.exists?  manifest_file
      manifest_json = JSON.parse File.read(manifest_file)
    end

    # validate manifest
    errors = []
    iv = InputValidator.new
    iv.test_mode
    iv.validate_manifest(manifest_json) do |valid|
      errors << valid if !valid.nil?
    end
    assert_equal 0, errors.length

    manifest = Hashit.new  manifest_json
    errors = []
    iv.validate_project_node manifest.projects.root do |valid|
      errors << valid if !valid.nil?
    end
    assert_equal 0, errors.length

    errors = []
    iv.validate_project_node manifest.projects.AutoUpgradeTestProject do |valid|
      errors << valid if !valid.nil?
    end
    assert_equal 0, errors.length

    Dir.chdir Constants::PARENTDIR
  end

end
