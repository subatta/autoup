require_relative '../lib/autoup'

require 'test/unit'

class TestGitApi < Test::Unit::TestCase

  def test_returns_head_hash_when_branch_exists

    Dir.chdir Constants::SPEC if File.basename(Dir.pwd) != Constants::SPEC

    # checkout fresh repo
    GitApi.CheckoutRepoAfresh Constants::TEST_REPO, 'master'
    ret = GitApi.DoesBranchExist  'origin', 'master'
    puts ret
    assert_not_equal '', ret

    Dir.chdir Constants::PARENTDIR
  end

  def test_returns_No_head_hash_when_branch_does_not_exist

    Dir.chdir Constants::SPEC if File.basename(Dir.pwd) != Constants::SPEC

    # checkout fresh repo
    GitApi.CheckoutRepoAfresh Constants::TEST_REPO, 'master'
    ret = GitApi.DoesBranchExist  'origin', 'test'
    assert_equal '', ret

    Dir.chdir Constants::PARENTDIR

  end

end
