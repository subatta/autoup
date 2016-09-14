require_relative '../lib/autoup'
require 'test/unit'

class TestUpgrade < Test::Unit::TestCase

  def test_package_version_upgrade

    # switch to tests folder with sample packages.config file
    Dir.chdir Constants::SPEC if File.basename(Dir.pwd) != Constants::SPEC

    # higher version
    versions = {
      'SolutionScripts' => '1.2'
    }

    pkg_files = [Dir.pwd + '/samples/packages.config']

    # upgrade
    up = UpgradePackages.new versions
    up.replace_package_versions pkg_files

    # read back packages.config and check for version match
    doc = Nokogiri::XML File.read(pkg_files[0])
    nodes = doc.xpath "//*[@id]"
    nodes.each { |node|
      if (versions.has_key? node['id'])
        assert_equal versions[node['id']], node['version']
      end
    }

    Dir.chdir Constants::PARENTDIR
  end

  def test_project_version_upgrade

    # switch to tests folder with sample proj file
    Dir.chdir Constants::SPEC if File.basename(Dir.pwd) != Constants::SPEC

    # higher version
    versions = {
      'Newtonsoft.Json' => '6.3.0'
    }

    proj_files = [Dir.pwd + '/samples/proj.csproj']

    # upgrade
    up = UpgradePackages.new versions
    status = up.replace_project_versions proj_files

    assert_equal true, status

    Dir.chdir Constants::PARENTDIR
  end

  def test_upgrade_and_rake_build

    Dir.chdir Constants::SPEC if File.basename(Dir.pwd) != Constants::SPEC

    config_map  = {
      'project_name' => 'AutoUpgradeTestProject',
      'metadata' => {
        'repo_url' => Constants::TEST_REPO,
        'branch' => 'master'
      }
    }

    config_map = Hashit.new config_map
    up = UpgradePackages.new
    status = up.Do config_map, []

    Dir.chdir Constants::PARENTDIR

    assert_equal true, status
  end

  def test_semver_upgraded_when_versions_provided

    # higher version
    versions = {
      'SolutionScripts' => '1.2'
    }

    Dir.chdir Constants::SPEC if File.basename(Dir.pwd) != Constants::SPEC

    config_map  = {
      'project_name' => 'AutoUpgradeTestProject',
      'metadata' => {
        'repo_url' => Constants::TEST_REPO,
        'branch' => 'master'
      }
    }

    config_map = Hashit.new config_map
    up = UpgradePackages.new versions
    status = up.Do config_map, []

    assert_equal true, status

    # verify upgrade from repo changes
    changes = `git status -s`
    lines = changes.split("\n")

    lines.each { |line|
      # check if packages.config has higher version
      if line.include? 'packages.config'
        doc = Nokogiri::XML File.read('./' + line.sub(/ M /, ''))
        nodes = doc.xpath "//*[@id]"
        nodes.each { |node|
          if node['id'] == 'SolutionScripts'
            assert_equal '1.2', node['version']
            break
          end
        }
      end
    }

    lines.each { |line|
      # check if semver was incremented
      if line.include? Constants::SEMVER
        v = SemVer.new
        v.load './' + line.sub(/ M /, '')
        assert_equal 6, v.patch
      end
    }


    Dir.chdir Constants::PARENTDIR

  end

end
