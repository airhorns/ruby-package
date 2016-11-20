require 'ruby-package'

instance_eval do
  def package(*args, &block)
    RubyPackage::DEFAULT_REGISTRY.define(*args, &block)
  end
end
