PACKAGES = {}

def package(name, imports = [])
  mod = Module.new
  PACKAGES[name] = mod

  klass = mod.singleton_class
  klass.instance_eval { @imports = imports }
  def klass.const_missing(name)
    @imports.each do |import|
      package = PACKAGES[import].singleton_class
      # Gotta build a module that can actually be included in the target class body
      if package.const_defined?(name)
        return package.const_get(name)
      end
    end
    super
  end

  mod
end

class << package('storefront')
  Checkout = 'yep'
end

class << package('shipping')
  Label = 'printy'
end

# syntax is gross but is required in order to define a new lexical scope
class << package('orders', %w(storefront shipping))
  puts self::Checkout
  puts Checkout       # works fine because new lexical scope that constant lookup is being done in includes the module!
  puts Label

  def self.callback
    puts Checkout     # again works ok when called out of band because the method is defined in a lexical scope where the constant lookup will succeed, no constants are undef'd
    puts Label
  end
end

raise "Leaked constant" if Object.const_defined?(:Checkout)

PACKAGES['orders'].singleton_class.callback
