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

Super, super work in progress. Nothing is finalized: not the syntax, not the semantics, nothin. Not even the fact that this is a good idea at all!

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

class << package(:bakery)
  import :fruit, :pie
  MENU = [Pie.new(Apple.new), Pie.new(Pear.new)]
end
```

## Motivations

TL;DR: Having a reliable user-land mechanism for building bounded contexts around code in Ruby allows the scaling ruby codebases without any new language features.

Ruby has pretty darn good facilities for organizing and isolating code already. Constants can be nested in modules and other objects, methods can be marked private, and since 1.9.2 constants can be marked private with respect to a module, which is great. For big apps though, these can fall short.

Consider an application that has 5 different teams working on 10 different major subsystems. All the code no longer fits in any one contributor's head, and different teams have different priorities for the existing abstractions that pull them in different directions. Each time a team needs to say, add a callback to an `ActiveRecord::Base` subclass in an area managed by a different team, that subclass blends two teams concerns. Future contributors to that class need to understand the intent of both the original author and the new additions in order to make the next change correctly. This can be managed, but grows more challenging as the number of people contributing to one particular object grows.

If the application gets to the point where it as 30 different teams working on 40 different major subsystems, it becomes mayhem. No one is able to understand the hundreds of different intents that brought the objects to be the way they are, and so making any change correctly is incredibly difficult. There are plenty of well thought out approaches for continuing to ship however: you can buy a Fowler book, you can practice Domain Driven Development, you can switch to an Event Sourcing model, etc! Each of these describes a way to slicing up big problem the application solves into a bunch of smaller, simpler problems, each of which is back to being understandable. Slicing the space isn't easy, and no matter what slicing you pick different sub-problems depend on the solutions to other sub-problems. These dependencies, if not managed correctly, can turn the application back into being one intricately interconnected mind-boggling maze. So, enter a module system. Put walls up around you subproblems so that accidental or poorly-thought-out dependencies aren't introduced. Code that works near the walls may be more complicated in order to not violate them, but in the long run, contributors only need context inside one walled garden to contribute, and the teams are back to being productive.

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
