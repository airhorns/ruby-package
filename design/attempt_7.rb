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

# can't define/reopen a module who's name is dynamic, only it's ancestor can be dynamic
package('storefront')::Checkout = 'yep'

class package('shipping')::Label
  def print
    puts 'printy'
  end
end

class package('orders', ['storefront', 'shipping'])::Order
  puts package('orders')::Checkout # works because the imported module is added
  puts Checkout # doesn't work because we're not nested in the package namespace, would need to use the module Foo; class Bar; syntax to add the lexical scope in which these modules would be looked up
  puts Label
end

raise "Leaked constant" if Object.const_defined?(:Checkout)
