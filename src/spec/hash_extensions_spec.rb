require_relative '../lib/hash_extensions'
require 'test/unit'

class TestUpgrade < Test::Unit::TestCase

  def test_hash_with_props
    h = Hashit.new({'a' => '123r', 'b' => {'c' => 'sdvs'}})
    assert_equal h.b.c, 'sdvs'
  end

end
