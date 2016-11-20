require 'ruby-package'

instance_eval do
  def package(*args, &block)
    RubyPackage::Package.define(*args, &block)
  end
end
