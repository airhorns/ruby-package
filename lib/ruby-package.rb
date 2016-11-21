module RubyPackage
  class DoubleRegisterException < RuntimeError; end
  class UnknownImportException < NameError; end
  class PackageNestingException < RuntimeError; end

  # Registries hold a bunch of packages that can reference each other. There's a default registry new packages
  # use by default, but to namespace a bunch of packages away from all others, use a new Registry instance.
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

  # PackageDefinitionContext exposes existing constants and accepts newly defined constants for a package.
  #
  # Instances of this class are the ones that get returned out of the `package` global method to be then `class <<`'d
  # They are where constants are looked up and where constants are defined for all user code using the system. Each
  # invocation of `package` gets a different definition context because each invocation can have different imports,
  # so different constants need to be available. The logic for how to expose the constants from imports are here.

  # Packages also sometimes re-open constants already defined in the package to do things like append a new class
  # to an inner module or whatnot. For this reason, PackageDefinitionContext must also make available all the existing
  # constants in the package already.
  class PackageDefinitionContext < Module
    def initialize(existing_exports, imports)
      @imports = imports
      @constants_before_definition = existing_exports.constants
      klass = singleton_class

      # It would be great to just be able to `include` the things that supply constants to a definition context,
      # but we can't. See ruby_behaviour_test.rb for examples of why. Instead of including, we manually mix in the
      # constants from the existing package exports, and from the imports, by const_set'ing them on the object.
      imports.each do |import|
        import.constants.each do |name|
          klass.const_set(name, import.const_get(name))
        end
      end

      existing_exports.constants.each do |name|
        klass.const_set(name, existing_exports.const_get(name))
      end
    end

    def defined_constants
      singleton_class.constants - @imports.flat_map(&:constants) - @constants_before_definition
    end
  end

  # ImportableContext manages the reporting and discovery of constants exported by a package.

  # Instances of this class are exposed by Package objects to report on what constants that package has exported.
  # When a package is imported into a new packge, the constants from this module are mixed in to the context for
  # defining that new package.
  class ImportableContext < Module
    def initialize(package)
      @package = package
    end

    def refresh!
      @package.definition_contexts.each do |context|
        context.defined_constants.each do |name|
          unless const_defined?(name)
            const_set(name, context.singleton_class.const_get(name))
          end
        end
      end
    end
  end

  class Package
    attr_accessor :name, :import_context, :definition_contexts

    def self.define(name, import: [], registry: DEFAULT_REGISTRY)
      package = registry.package(name) || new(name, registry: registry)
      package.new_definition_context(import)
    end

    def initialize(name, registry: DEFAULT_REGISTRY)
      @name = name.to_sym
      @registry = registry
      @definition_contexts = []
      @import_context = ImportableContext.new(self)
      registry.register(self)
    end

    def new_definition_context(imports)
      available_contexts = imports.map do |import_name|
        package = @registry.package(import_name)
        if package.nil?
          raise UnknownImportException, "Couldn't find package #{import_name} to import when defining #{name}"
        end
        package.import_context
      end

      # Refresh things about to be exposed in the definition context to pick up any newly defined dynamic constants.
      available_contexts.each(&:refresh!)
      import_context.refresh!

      new_context = PackageDefinitionContext.new(import_context, available_contexts)
      @definition_contexts << new_context
      new_context
    end
  end
end
