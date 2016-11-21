require 'test_helper'

MetaRegistry = RubyPackage::Registry.new

class << package(:fruit, registry: MetaRegistry)
  class Apple; end
  METAPROGRAMMING_MAGIC = proc { const_set(:Pear, Class.new) }
end

# Define a new constant in a package outside a package definition
package(:fruit, registry: MetaRegistry).singleton_class::METAPROGRAMMING_MAGIC.call

class << package(:bakery, import: [:fruit], registry: MetaRegistry)
  class TestMetaprogramming < Minitest::Test
    def test_dynamically_defined_constants_are_discovered_upon_import
      assert Pear
    end
  end
end
