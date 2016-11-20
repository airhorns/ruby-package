require 'test_helper'

package :fruit do
  class Apple; end
  class Pear; end
  class Peach; end
end

package :pie do
  class Pie
    def initialize(fruit)
      @fruit = fruit
    end

    def serve
      "Enjoy a slice of #{@fruit.class.name}"
    end
  end
end

package :bakery do
  import :fruit, :pie
  Foobar
  MENU = [Pie.new(Apple.new)]
  SERVE = proc { MENU[0] }
  SERVE_CUSTOM = proc { Pie.new(Pear.new) }
end

package :bakery do
  MENU << Pie.new(Peach.new)
end

class TestExample < Minitest::Test
  def test_constants_arent_visible_outside_of_package
    assert_raises(NameError) { MENU }
    assert_raises(NameError) { Apple }
    assert_raises(NameError) { Pear }
    assert_raises(NameError) { Peach }
    assert_raises(NameError) { Pie }
  end
end

package :bakery do
  class TestBakery < Minitest::Test
    def test_inner_classes_can_access_constants
      assert MENU
    end

    def test_packages_can_be_reopened
      assert_equal 2, MENU.size
    end
  end
end
