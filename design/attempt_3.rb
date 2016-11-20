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

  # remove constants from binding to prevent leaking
  Storefront.constants.each do |const_name|
    block.binding.eval("Object.send(:remove_const, :#{const_name.to_sym})")
  end
  mod
end

mod = package 'orders' do
  puts self::Checkout # works fine because instance_exec changes self to be module
  puts Checkout       # works because constant lookup is done in lexical scope which now has constant

  # define a callback that could be called outside of the block passed to package
  class << self
    define_method(:callback) { Checkout }
  end

  puts self.callback # works right now because variable is still in scope, but won't once the block ends
end

raise "Leaked constant" if Object.const_defined?(:Checkout)

# raises because the constant the callback block was referencing has been removed from Object, which is where it was referenced in the callback
mod.callback
