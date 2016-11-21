# ruby-package

`ruby-package` adds a large-scale way to organize and express dependencies to Ruby for really big apps.

## Features

 - Allows defining packages who's members are listed private or public to the package
 - Allows importing other packages who's public members become in scope
 - "Just works" with Rails autoloading
 - Supports independent registries of packages

### Anti-features

 - Is not a build server, static analyzer, or transpiler that adds syntax extensions
 - Is not a C extension
 - Is not Rails-only or incompatible with Rails

## Status

 - Super, super work in progress.
 - Nothing is finalized: not the syntax, not the semantics, nothin.
 - I (the author) am still undecided on if this is even a good idea at all ...

## Example

```ruby
class << package(:fruit)
  class Apple; end
  class Peach; end
end

const_defined?(:Apple) # => false

class << package(:pie)
  class Pie
    def initialize(filling)
      @filling = filling
    end

    def serve
      "Enjoy a slice of #{@filling.class.name}"
    end
  end
end

class << package(:bakery, import: %w(fruit pie))
  MENU = [Pie.new(Apple.new), Pie.new(Pear.new)]
end
```

## Motivations

TL;DR: Having a reliable user-land mechanism for building bounded contexts around code in Ruby allows the scaling ruby codebases without any new language features.

Ruby has pretty darn good facilities for organizing and isolating code already. Constants can be nested in modules and other objects, methods can be marked private, and since 1.9.2 constants can be marked private with respect to a module, which is great. For big apps though, these can fall short.

Consider an application that has 5 different teams working on 10 different major subsystems. All the code no longer fits in any one contributor's head, and different teams have different priorities for the existing abstractions. Each abstraction (model) gets pulled in different directions. Every time a team needs to say add a callback to an `ActiveRecord::Base` subclass in an area managed by a different team, that subclass blends both team's concerns. Future contributors to that class need to understand the intent of both the original author and the new additions in order to make the next change correctly. This can be managed, but grows more challenging as the number of people contributing to one particular object grows.

If the application gets to the point where it as 30 different teams working on 40 different major subsystems, it becomes mayhem if the strategy doesn't change. No one is able to understand the hundreds of different intents that brought the objects to be the way they are, and so making any change correctly is incredibly difficult. There are plenty of well thought out approaches for continuing to ship however: you can buy a Fowler book, you can practice Domain Driven Development, you can switch to an Event Sourcing model, et cetera et cetera. Each of these describes a way to slicing up big problem the application solves into a bunch of smaller, simpler problems, each of which is back to being understandable. Slicing the space isn't easy, and no matter what slicing you pick different sub-problems depend on the solutions to other sub-problems. These dependencies must be managed correctly. Without proper attention and minimization, they turn the application back into an intricately interconnected mind-boggling maze. So, enter a __module system__. Put walls up around your subproblems so that accidental or poorly-thought-out dependencies aren't introduced. Code that works near the walls may be more complicated in order to not violate them, but in the long run, contributors only need context inside one walled garden to contribute, and the teams are back to being productive.

`ruby-package` exists because Ruby's existing wall-building tools can be insufficient. It is very easy to use constants from completely different places in a Ruby application if you're using `autoload` or Rails such that it's easy to make short sighted decisions and introduce unnecessary couplings between things with a simple constant reference. It isn't possible to specify what should be "public API" on an object when it is used both by things inside the walled garden and things outside it: we can only set methods as visible to everyone or no one.

To remedy these issues, `ruby-package` introduces explicit package dependencies, so that code inside packages can't reference just any constant from the global namespace, and instead must take one minor step to asking for it.

### Semantics

A package is:
 - an isolated namespace
 - which contains a bunch of constants
 - with a name

A file defining a package can:
 - import other packages
 - define new constants
 - mark those constants as package-private or package-public

### Design

TL;DR: The `class <<` shift operator is the only good way of opening a new scope to do constant lookup in, so thats what we use. This whole library has nothing to do with singleton classes, it's just the only syntax that works.

__Note__: Much of this was explored in the files in the `design` folder, so if you want to play around, look there!

Sadly, Ruby doesn't really make this whole thing very easy. In order to define constants in a scope that `ruby-package` can control, we need to open a new lexical scope in which constant lookup will be done differently. Sadly, blocks (`instance_exec`'d or not) do not have this property.

```ruby
def package(name, &block)
  mod = Module.new
  mod.instance_exec(&block)
  mod
end

package('orders') do
  Order = {}
end

const_defined?(Order) # => true
```

The block passed to the package method there binds itself to the lexical scope it which it was opened, which is `main`, where constant lookup will be the same as ever. This seems to be unchangeable without stringifying (see [sourcify](https://github.com/ngty/sourcify)) the block and `eval`ing the string somewhere else, which I think renders the developer experience way too nasty. Most code in an application using `ruby-package` would go through this path which means we'd be parsing and evaluating every Ruby file twice, and I'm not sure if it's possible to match the debugging experience of "real" code with `eval`'d code.

So, there are 4 ways I can find of actually opening a new constant lookup scope in Ruby: defining a method with the `def` keyword, opening a class with the `class` keyword, opening a module with the `module` keyword, and opening the singleton class with the `class << obj` operator. The first three all require a static name for the thing we're about to define, so you can't do things like this:

```ruby
module package('orders')   # syntax error
  Order = {}
end
```

You can do things like this:

```ruby
class package('orders')::Order   
  def process(cart)
    package('orders')::Processor.process(cart)
  end
end
```

But, you have to use fully qualified constant names in the class body because we're not using the nested module syntax. If this were allowed, things would be a lot cleaner:

```ruby
module package('orders')
  class Order   
    def process(cart)
      Processor.process(cart)
    end
  end
end
```

Once more, this is indeed a syntax error.

So, with `def`, `class`, and `module` requiring these static names, we're left with `class << obj`, where the obj can be any expression. It works! It has the (in this case) unfortunate side effect of kicking us into the scope of that expression's singleton class, but that is as fine a place as any to `def self.const_missing`, so we're able to hook in and look up constants from other packages there. Woo hoo! The syntax is gross, but it doesn't leak constants, allows for blocks defined in scope to be called after the scope is closed again, and doesn't require any C extensions or other hullabulloo to get working. See `design/attempt_6.1.rb` for the minimum viable code.
