require 'test_helper'

module Orders
  class Order; end
end

module Orders
  class TestRubyBehaviour < Minitest::Test
    def test_module_constants_are_accessible_in_reopened_modules
      assert Order
    end
  end
end

class << Orders
  class SingletonOrder; end
end

Orders.singleton_class.const_set(:RenamedSingletonOrder, Orders.singleton_class.const_get(:SingletonOrder))

class << Orders
  class TestRubyBehaviour < Minitest::Test
    def test_singleton_module_constants_are_accessible_in_reopened_singleton_modules
      assert SingletonOrder
    end

    def test_renamed_singleton_module_constants_are_accessible_in_reopened_singleton_modules
      assert RenamedSingletonOrder
    end
  end
end

module IncludeInSingleton
  class IncludedOrder; end
end

module Target; end

class << Target
  include IncludeInSingleton
end

Target.singleton_class.const_set(:RenamedIncludedOrder, Target.singleton_class.const_get(:IncludedOrder))

class << Target
  class TestRubyBehaviour < Minitest::Test
    def test_included_module_constants_arent_accessible_in_reopened_singleton_modules
      assert_raises(NameError) { IncludedOrder }
    end

    def test_renamed_singleton_module_constants_are_accessible_in_reopened_singleton_modules
      assert RenamedIncludedOrder
    end
  end
end
