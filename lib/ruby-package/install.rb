require 'ruby-package'

module Kernel
  def package(*args, &block)
    RubyPackage::Package.define(*args, &block)
  end
end
