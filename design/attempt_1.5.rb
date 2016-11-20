module Storefront
  Checkout = 'yep'
  OtherThing = 'right here'
end

def package(name, &block)
  mod = Module.new

  def mod.const_missing(name)
    puts "const missing called on mod for #{name}"
    if Storefront.const_defined?(name)
      Storefront.const_get(name)
    end
  end

  mod.instance_exec(&block)
end

package 'orders' do
  puts self::Checkout     # both work fine because cosnt_missing is invoked on the inner module
  puts self::OtherThing
  puts Checkout           # does not work, calls const_missing on Object :(
end
