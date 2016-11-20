module Storefront
  Checkout = 'yep'
end

def package(name, &block)
  mod = Module.new
  mod.include(Storefront) # simulate import
  # export constants as locals into scope of the binding
  Storefront.constants.each do |const_name|
    block.binding.eval("#{const_name} = Storefront::#{const_name}")
  end
  mod.instance_exec(&block)
end

package 'orders' do
  puts self::Checkout # works fine because instance_exec changes self to be module
  puts Checkout       # works because constant lookup is done in lexical scope which now has constant
end

raise "Leaked constant" if Object.const_defined?(:Checkout)
