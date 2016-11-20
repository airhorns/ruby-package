PACKAGES = {}

def package(name, imports = [])
  mod = Module.new
  PACKAGES[name] = mod

  # Include the constants in the singleton class of the module, not the module itself
  # We're using singleton classes here because it is a syntax that allows opening a new lexical scope
  # without having to name a new constant.
  imports.each do |import|
    package = PACKAGES[import].singleton_class
    # Gotta build a module that can actually be included in the target class body
    importable = Module.new
    package.constants.each do |name|
      importable.const_set(name, package.const_get(name))
    end
    mod.singleton_class.include importable
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
