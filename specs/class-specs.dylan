Module:       testworks-specs
Synopsis:     A library for building specification test suites
Author:       Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// Class specs

define class <class-spec> (<definition-spec>)
  constant slot class-spec-class :: <class>,
    required-init-keyword: class:;
  constant slot class-spec-superclasses :: <sequence>,
    required-init-keyword: superclasses:;
  slot class-spec-modifiers :: <sequence> = #[],
    init-keyword: modifiers:;
end class <class-spec>;

define method initialize (this :: <class-spec>, #key)
  next-method();
  let modifiers = this.class-spec-modifiers;
  // Ensure no conflicting modifiers were specified.
  if ((member?(#"sealed", modifiers) & member?(#"open", modifiers))
      | (member?(#"primary", modifiers) & member?(#"free", modifiers))
      | (member?(#"abstract", modifiers) & member?(#"concrete", modifiers)))
    error("Conflicting modifiers specified for class %s",
          this.class-spec-class);
  end if;
  // Classes are concrete by default.
  if (~member?(#"abstract", modifiers) & ~member?("concrete", modifiers))
    modifiers := add!(modifiers, #"concrete");
  end if;
  // Classes are free by default.
  if (~member?(#"free", modifiers) & ~member?("primary", modifiers))
    modifiers := add!(modifiers, #"free");
  end if;
  // Classes are sealed by default.
  if (~member?(#"sealed", modifiers) & ~member?("open", modifiers))
    modifiers := add!(modifiers, #"sealed");
  end if;
  this.class-spec-modifiers := modifiers;
end method initialize;



/// A useful macro to define the class specs

define macro class-test-definer
  { define ?protocol-name:name class-test ?class-name:name ()
      ?body:body
    end }
    => { define test "test-class-" ## ?class-name (requires-assertions?: #f)
           ?body
         end }
end macro class-test-definer;


/// Class checking

define method class-spec-instantiable?
    (class-spec :: <class-spec>) => (instantiable? :: <boolean>)
  member?(#"instantiable", class-spec-modifiers(class-spec))
// I deleted the following because it causes tests that initially fail
// because the programmer failed to provide a make-test-instance method
// to pass on subsequent test runs.  -- carlg
//    & begin
//        let info = protocol-class-bindings(spec);
//        ~member?(class, protocol-uninstantiable-classes(info))
//      end
end method class-spec-instantiable?;

define method class-spec-abstract?
    (class-spec :: <class-spec>)
 => (abstract? :: <boolean>)
  member?(#"abstract", class-spec-modifiers(class-spec))
end method class-spec-abstract?;

define method check-class-specification
    (class-spec :: <class-spec>)
 => ()
  let title = spec-title(class-spec);
  let class = class-spec-class(class-spec);
  check-instance?(format-to-string("Variable %s is a class", title),
                  <class>, class);
  check-true(format-to-string("Variable %s has the correct superclasses", title),
             class-has-correct-superclasses?(class-spec));
  check-class-instantiation(class-spec);
  check-class-test-function(class-spec);
end method check-class-specification;

define method class-has-correct-superclasses?
    (class-spec :: <class-spec>)
 => (correct? :: <boolean>)
  let class = class-spec-class(class-spec);
  every?(method (superclass :: <class>) => (subtype? :: <boolean>)
           subtype?(class, superclass)
         end,
         class-spec-superclasses(class-spec))
end method class-has-correct-superclasses?;


/// Class instantiation checks

define method make-test-instance
    (class :: <class>) => (object)
  make(class)
end method make-test-instance;

define method destroy-test-instance
    (class :: <class>, object :: <object>) => ()
  #f
end method destroy-test-instance;

define method check-class-instantiation
    (class-spec :: <class-spec>)
 => ()
  let class = class-spec-class(class-spec);
  let title = spec-title(class-spec);
  if (class-spec-instantiable?(class-spec))
    let instance = #f;
    check-instance?(format-to-string("make %s with required arguments", title),
                    class,
                    instance := make-test-instance(class));
    if (instance)
      destroy-test-instance(class, instance)
    end
  else
    check-condition
      (format-to-string("make(%s) errors because not instantiable", title),
       <error>,
       begin
         let instance = make-test-instance(class);
         destroy-test-instance(class, instance)
       end)
  end
end method check-class-instantiation;

define method check-class-test-function
    (class-spec :: <class-spec>)
 => ()
  let class = class-spec-class(class-spec);
  let test-function = class-test-function(class);
  if (test-function)
    let instantiable? = class-spec-instantiable?(class-spec);
    let abstract? = class-spec-abstract?(class-spec);
    test-function(class,
                  name: spec-title(class-spec),
                  abstract?: abstract?,
                  instantiable?: instantiable?);
  end
end method check-class-test-function;
