# lifted from Rails v4.0.2, was deprecated after that for creating too many symbols
class Proc
  def bind(object)
    block, time = self, Time.now
    (class << object; self end).class_eval do
      method_name = "__bind_#{time.to_i}_#{time.usec}"
      define_method(method_name, &block)
      method = instance_method(method_name)
      remove_method(method_name)
      method
    end.bind(object)
  end
end

module Storefront
  Checkout = 'yep'
end

def package(&block)
  mod = Module.new
  # simulate import
  block = block.bind(Storefront)
  block.call
end

package do
  puts self::Checkout # works because self is now the mod in the rebound proc
  puts Checkout       # doesn't work because the block passed to package is still doing constant lookup in it's original lexical scope, binding the method to a new object made no difference
end
