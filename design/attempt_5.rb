module Storefront
  Checkout = 'yep'
end

def package(name)
  mod = Module.new
  # Include the constants in the singleton class of the module, not the module itself
  class << mod
    include Storefront
  end

  mod
end

# syntax is gross but is required in order to define a new lexical scope
class << package('orders')
  puts self::Checkout
  puts Checkout       # works fine because new lexical scope that constant lookup is being done in includes the module!
end

raise "Leaked constant" if Object.const_defined?(:Checkout)
