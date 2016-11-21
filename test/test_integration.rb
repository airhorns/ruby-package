require 'test_helper'

IntegrationRegistry = RubyPackage::Registry.new

class << package(:fruit, registry: IntegrationRegistry)
  class Apple; end
  class Pear; end
  class Peach; end
end

class << package(:pie, registry: IntegrationRegistry)
  class Pie
    def initialize(fruit)
      @fruit = fruit
    end

    def serve
      "Enjoy a slice of #{@fruit.class.name}"
    end
  end
end

class << package(:bakery, import: [:fruit, :pie], registry: IntegrationRegistry)
  MENU = [Pie.new(Apple.new)]
  SERVE = proc { Pie.new(Pear.new) }
end

class << package(:bakery, import: [:fruit, :pie], registry: IntegrationRegistry)
  MENU << Pie.new(Peach.new)
end

class TestConstantLeaks < Minitest::Test
  def test_constants_arent_visible_outside_of_package
    assert_raises(NameError) { MENU }
    assert_raises(NameError) { Apple }
    assert_raises(NameError) { Pear }
    assert_raises(NameError) { Peach }
    assert_raises(NameError) { Pie }
  end

  def test_package_callbacks_can_be_executed_outside
    assert package(:bakery, registry: IntegrationRegistry).singleton_class::SERVE.call.class.name.end_with?("Pie")
  end
end

class << package(:bakery, registry: IntegrationRegistry)
  class TestBakery < Minitest::Test
    def test_inner_classes_can_access_package_constants
      assert MENU
    end

    def test_packages_can_be_reopened
      assert_equal 2, MENU.size
    end

    def test_previously_imported_package_contstants_arent_accessible_if_not_reimported
      assert_raises(NameError) { Pie }
      assert_raises(NameError) { Apple }
    end
  end
end

class << package(:application, import: [:bakery], registry: IntegrationRegistry)
  class TestApplication < Minitest::Test
    def test_imports_dependencies_arent_accessible
      assert_raises(NameError) { Pie }
    end

    def test_inner_classes_can_access_package_constants
      # the inner class being this minitest test class here
      assert_equal 2, MENU.size
    end
  end
end
