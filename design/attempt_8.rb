require 'byebug'
PACKAGES = {}
MAIN = self
def package(name, &block)
  PACKAGES[name] ||= Module.new
  mod = PACKAGES[name]

  def mod.import(*imports, &block)
    imports.each do |import|
      include(PACKAGES[import])
    end
    instance_exec(&block)
  end

  scope = block.binding.eval("self")
  if scope == MAIN
    scope = MAIN.class
  end

  # capture what new constants are defined on Object and move them into the module to not leak
  # necessary because despite the fact that we're instance_exec'ing the outer block in the context of the module,
  # the block "closes over" where it was opened and defines constants there
  before_constants = scope.constants
  mod.instance_exec(&block)
  after_constants = scope.constants
  (after_constants - before_constants).each do |const|
    mod.const_set(const, scope.const_get(const))
    scope.send(:remove_const, const)
  end
end

# can't define/reopen a module who's name is dynamic, only it's ancestor can be dynamic
package 'storefront' do
  Checkout = 'yep'
end

raise "Leaked constant" if Object.const_defined?(:Checkout)

package 'orders' do
  import 'storefront' do  # one might hope that capturing a new closure inside a closure where the instance_exec
    puts self::Checkout
    puts Checkout
  end
end
