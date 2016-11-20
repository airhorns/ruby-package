module Storefront
  Checkout = 'yep'
end

def package(name, &block)
  mod = Module.new
  mod.include(Storefront) # simulate import
  mod.instance_exec(&block)
end

package 'orders' do
  puts self::Checkout # works fine because instance_exec changes self to be module
  puts Checkout       # does not work because lookup is done in lexical scope, which is just main
end
