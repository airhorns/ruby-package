require 'byebug'
PACKAGES = {}

def package(name, imports = [])
  PACKAGES[name] ||= Module.new
  mod = PACKAGES[name]
  imports.each do |import|
    mod.include PACKAGES[import]
  end
  mod
end

package('storefront')::Checkout = 'yep'

# can't define/reopen a module who's name is dynamic, only it's ancestor can be dynamic
module package('shipping')
  # syntax error
end

module package('orders', ['storefront', 'shipping'])
  puts Checkout # doesn't work because we're not nested in the package namespace, would need to use the module Foo; class Bar; syntax to add the lexical scope in which these modules would be looked up
  puts Label
end
