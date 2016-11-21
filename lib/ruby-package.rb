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
      @packages[name.to_sym]
    end
  end

  DEFAULT_REGISTRY = Registry.new

  class PackageDefinitionContext < Module
    def initialize(imports)
      klass = singleton_class
      klass.instance_exec { @imports = imports }

      def klass.const_missing(name)
        @imports.each do |import|
          if import.singleton_class.const_defined?(name)
            return import.singleton_class.const_get(name)
          end
        end
        super
      end
    end
  end

  class Package
    attr_accessor :name, :definition_context

    def self.define(name, import: [], registry: DEFAULT_REGISTRY)
      package = registry.package(name) || new(name, import: import, registry: registry)
      package.definition_context
    end

    def initialize(name, import: [], registry: DEFAULT_REGISTRY)
      @name = name.to_sym
      @registry = registry
      registry.register(self)
      available_contexts = import.map { |import_name| @registry.package(import_name).definition_context }
      @definition_context = PackageDefinitionContext.new(available_contexts)
    end
  end
end
