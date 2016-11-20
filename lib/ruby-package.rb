require 'set'

RUBY_PACKAGE_MAIN = self

class Object
  def self.const_missing(name)
    puts "object const missing called for #{name}"
    raise NameError, "uninitialized constant #{name}, caught at object level"
  end
end

module RubyPackage
  class DoubleRegisterException < RuntimeError; end
  class UnknownImportException < NameError; end
  class PackageNestingException < RuntimeError; end

  class Registry
    def initialize
      @packages = {}
    end

    def define(package_name, &block)
      package = @packages[package_name]
      if package.nil?
        package = Package.new(package_name, self)
        @packages[package_name] = package
      end

      package.open(&block)
    end

    def register(package)
      if !@packages[package.name]
        @packages[package.name] = package
      else
        raise DoubleRegisterException, "Can't register package #{package.name}, it is already registered"
      end
    end

    def package(name)
      @packages[name]
    end
  end

  DEFAULT_REGISTRY = Registry.new

  class PackageDefinitionContext < Module
    def initialize(registry)
      @registry = registry
      @imported_constants = {}
    end

    def import(*package_names)
      package_names.map do |name|
        package = @registry.package(name)
        if package.nil?
          raise UnknownImportException, "Can't find package #{name} in registry"
        end
        include package.module
        self.class.instance_eval do
          package.exports.each do |export_name, value|
            define_method(export_name) { value }
          end
        end
      end
    end

    def const_missing(name)
      puts "module const missing called for #{name}"
      super
    end
  end

  class NewConstantCapture
    def initialize(scope)
      @scope = scope
    end

    def capture
      before_constant_names = @scope.constants
      yield
      after_constant_names = @scope.constants

      (after_constant_names - before_constant_names).each_with_object({}) do |name, constants|
        constants[name] = @scope.const_get(name)
        @scope.send(:remove_const, name)
      end
    end
  end

  class Package
    attr_accessor :name, :module

    def initialize(name, registry)
      @name = name
      @registry = registry
      registry.register(self)
      @module = PackageDefinitionContext.new(@registry)
    end

    def open(&block)
      puts "opening #{name}"
      if block.binding.eval("self") != RUBY_PACKAGE_MAIN
        raise PackageNestingException "Can't nest packages, must use the top level"
      end
      new_constants = NewConstantCapture.new(RUBY_PACKAGE_MAIN.class).capture do
        @module.instance_exec(&block)
      end
      new_constants.each do |name, value|
        @module.const_set(name, value)
      end
    end

    def exports
      @module.constants.each_with_object({}) do |name, ret|
        ret[name] = @module.const_get(name)
      end
    end
  end
end
