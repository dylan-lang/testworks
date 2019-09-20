Module:       %testworks
Synopsis:     Generate tests based on an API specification
Author:       Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND


define abstract class <spec> (<object>)
  constant slot spec-name :: <symbol>,
    required-init-keyword: name:;
end class <spec>;

define abstract class <definition-spec> (<spec>)
end class <definition-spec>;

define method spec-title
    (spec :: <spec>) => (title :: <byte-string>)
  as-lowercase(as(<byte-string>, spec-name(spec)))
end method spec-title;

/// Protocols

define open generic make-test-instance
    (class :: <class>) => (object);

define open generic destroy-test-instance
    (class :: <class>, object :: <object>) => ();

define open generic class-test-function
    (class :: <class>) => (test-function :: false-or(<function>));

define method class-test-function
    (class :: <class>) => (test-function :: false-or(<function>))
  #f
end method class-test-function;

// A macro for building a suite out of a list of binding specifications

define macro binding-spec-suite-definer
  { define binding-spec-suite ?suite-name:name (?options:*)
      ?specs:*
    end }
    => { define suite ?suite-name (?options)
           ?specs
         end }
 specs:
  { } => { }
  { ?spec:*; ... } => { ?spec ... }
 spec:
  { protocol ?protocol-name:name }
    => { suite ?protocol-name ## "-protocol-test-suite"; }
  { ?modifiers:* class ?class-name:name (?superclasses:*); }
    => { test "check-class-specification-" ## ?class-name;
         test "test-class-" ## ?class-name; }
  { ?modifiers:* function ?function-name:name (?parameters:*) => (?results:*); }
    => { test "check-function-specification-" ## ?function-name;
         test "test-function-" ## ?function-name; }
  { ?modifiers:* generic-function ?function-name:name (?parameters:*) => (?results:*); }
    => { test "check-function-specification-" ## ?function-name;
         test "test-function-" ## ?function-name; }
  { ?modifiers:* variable ?variable-name:name :: ?type:expression; }
    => { test "check-variable-specification-" ## ?variable-name;
         test "test-variable-" ## ?variable-name; }
  { ?modifiers:* constant ?constant-name:name :: ?type:expression; }
    => { test "check-constant-specification-" ## ?constant-name;
         test "test-constant-" ## ?constant-name; }
  { ?modifiers:* macro-test ?macro-name:name; }
    => { test "test-macro-" ## ?macro-name; }
  { ?definition:* }
    => { }
end macro binding-spec-suite-definer;

define macro binding-specs-definer
  { define binding-specs ?protocol-name:name (?options:*)
    end }
    => { }
  { define binding-specs ?protocol-name:name (?options:*)
      ?modifiers:* class ?class-name:name (?superclasses:*);
      ?more-specs:*
    end }
    => { define test "check-class-specification-" ## ?class-name ()
           let class-spec = make(<class-spec>,
                                 name: ?#"class-name",
                                 class: ?class-name,
                                 superclasses: vector(?superclasses),
                                 modifiers: vector(?modifiers));
           check-class-specification(class-spec);
         end;
         define binding-specs ?protocol-name (?options)
           ?more-specs
         end; }
  { define binding-specs ?protocol-name:name (?options:*)
      ?modifiers:* function ?function-name:name (?parameters:*) => (?results:*);
      ?more-specs:*
    end }
    => { define test "check-function-specification-" ## ?function-name ()
           let function-spec
             = make(<function-spec>,
                    name: ?#"function-name",
                    function: ?function-name,
                    parameters: vector(?parameters),
                    results:    vector(?results),
                    modifiers: vector(?modifiers));
           check-function-specification(function-spec);
         end;
         define binding-specs ?protocol-name (?options)
           ?more-specs
         end; }
  { define binding-specs ?protocol-name:name (?options:*)
      ?modifiers:* generic-function ?function-name:name (?parameters:*) => (?results:*);
      ?more-specs:*
    end }
    => { define test "check-function-specification-" ## ?function-name ()
           let function-spec
             = make(<function-spec>,
                    name: ?#"function-name",
                    function: ?function-name,
                    parameters: vector(?parameters),
                    results:    vector(?results),
                    modifiers: vector(#"generic", ?modifiers));
           check-function-specification(function-spec);
         end;
         define binding-specs ?protocol-name (?options)
           ?more-specs
         end; }
  { define binding-specs ?protocol-name:name (?options:*)
      ?modifiers:* variable ?variable-name:name :: ?type:expression;
      ?more-specs:*
    end }
    => { define test "check-variable-specification-" ## ?variable-name ()
           let variable-spec
             = make(<variable-spec>,
                    name: ?#"variable-name",
                    type: ?type,
                    getter: method () => (value :: ?type)
                              ?variable-name
                            end,
                    setter: method (value :: ?type) => (value :: ?type)
                              ?variable-name := value
                            end);
           check-variable-specification(variable-spec);
         end;
         define binding-specs ?protocol-name (?options)
           ?more-specs
         end; }
  { define binding-specs ?protocol-name:name (?options:*)
      ?modifiers:* constant ?constant-name:name :: ?type:expression;
      ?more-specs:*
    end }
    => { define test "check-constant-specification-" ## ?constant-name ()
           let constant-spec
             = make(<constant-spec>,
                    name: ?#"constant-name",
                    type: ?type,
                    getter: method () ?constant-name end);
           check-constant-specification(constant-spec);
         end;
         define binding-specs ?protocol-name (?options)
           ?more-specs
         end; }
  { define binding-specs ?protocol-name:name (?options:*)
      ?modifiers:* macro-test ?macro-name:name;
      ?more-specs:*
    end }
    => { define binding-specs ?protocol-name (?options)
           ?more-specs
         end; }
 modifiers:
  { }
    => { }
  { ?modifier:name ... }
    => { ?#"modifier", ... }
end macro binding-specs-definer;

/// Library specs

// Like the "define suite" macro, but allows clauses like "module foo;"
// in its body which expand to "suite foo-module-test-suite".
define macro library-spec-definer
  { define library-spec ?library-name:name (?options:*)
      ?subsuites:*
    end}
    => { define suite ?library-name ## "-test-suite" (?options)
           ?subsuites
         end
         }
 subsuites:
  { } => { }
  { ?thing; ... } => { ?thing; ... }
 thing:
  { module ?module-name:name }
    => { suite ?module-name ## "-module-test-suite" }
  { ?x:* } => { ?x }
end macro library-spec-definer;

/// A useful macro to define protocol specs
///
/// A protocol spec is a list of binding specifications that
/// is smaller than a module. It is used to more tightly associate
/// a set of bindings rather than having them all within a single
/// module spec.
define macro protocol-spec-definer
  { define protocol-spec ?protocol-name:name (?options:*)
      ?specs:*
    end}
    => { define binding-specs ?protocol-name (?options)
           ?specs
         end;
         define binding-spec-suite ?protocol-name ## "-protocol-test-suite" (?options)
           ?specs
         end }
end macro protocol-spec-definer;

/// A useful macro to define module specs

// This expands a list of binding specifications into a test for each of those
// specifications, as well as a suite that will run both those specification tests
// and the separate test function for each binding.
define macro module-spec-definer
  { define module-spec ?module-name:name (?options:*)
      ?specs:*
    end}
    => { define module-binding-specs ?module-name ()
           ?specs
         end;
         define binding-spec-suite ?module-name ## "-module-test-suite" (?options)
           ?specs
         end }
end macro module-spec-definer;

// This just dispatches to binding-specs, but drops protocol references first.
// protocol references are used to tie a protocol-spec into a module-spec.
define macro module-binding-specs-definer
  { define module-binding-specs ?module-name:name (?options:*)
      ?specs:*
    end }
    => { define binding-specs ?module-name (?options)
           ?specs
         end }
 specs:
  { } => { }
  { ?spec:*; ... } => { ?spec ... }
 spec:
  { protocol ?protocol-name:name }
    => { }
  { ?definition:* }
    => { ?definition; }
end macro module-binding-specs-definer;

/// Variable specs

define abstract class <abstract-variable-spec> (<definition-spec>)
  constant slot variable-spec-type :: <type>,
    required-init-keyword: type:;
  constant slot variable-spec-getter :: <function>,
    required-init-keyword: getter:;
end class <abstract-variable-spec>;

define class <variable-spec> (<abstract-variable-spec>)
  constant slot variable-spec-setter :: <function>,
    required-init-keyword: setter:;
end class <variable-spec>;

define class <constant-spec> (<abstract-variable-spec>)
end class <constant-spec>;


/// A useful macro to define the class specs

define macro variable-test-definer
  { define ?protocol-name:name variable-test ?variable-name:name ()
      ?body:body
    end }
    => { define test "test-variable-" ## ?variable-name (requires-assertions?: #f)
           ?body
         end }
end macro variable-test-definer;

define macro constant-test-definer
  { define ?protocol-name:name constant-test ?constant-name:name ()
      ?body:body
    end }
    => { define test "test-constant-" ## ?constant-name (requires-assertions?: #f)
           ?body
         end }
end macro constant-test-definer;


/// Variable testing

define function check-variable-specification
    (variable-spec :: <variable-spec>)
 => ()
  let title = spec-title(variable-spec);
  check-instance?(format-to-string("Variable %s has the correct type", title),
                  variable-spec-type(variable-spec),
                  variable-spec-getter(variable-spec)());
  check-true(format-to-string("Variable %s can be set to itself", title),
             begin
               let value = variable-spec-getter(variable-spec)();
               variable-spec-setter(variable-spec)(value) = value
             end);
end function check-variable-specification;

define function check-constant-specification
    (constant-spec :: <constant-spec>)
 => ()
  let title = spec-title(constant-spec);
  check-instance?(format-to-string("Constant %s has the correct type", title),
                  variable-spec-type(constant-spec),
                  variable-spec-getter(constant-spec)());
end function check-constant-specification;

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

/// Function specs

define class <function-spec> (<definition-spec>)
  constant slot function-spec-function :: <function>,
    required-init-keyword: function:;
  constant slot function-spec-modifiers :: <sequence> = #[],
    init-keyword: modifiers:;
  constant slot %function-spec-parameters :: <sequence> = #[],
    init-keyword: parameters:;
  constant slot %function-spec-results :: <sequence> = #[],
    init-keyword: results:;
end class <function-spec>;


/// A useful macro to define the function specs

define macro function-test-definer
  { define ?protocol-name:name function-test ?function-name:name ()
      ?body:body
    end }
    => { define test "test-function-" ## ?function-name (requires-assertions?: #f)
           ?body
         end }
end macro function-test-definer;


/// Function spec modeling

define method function-spec-parameters
    (function-spec :: <function-spec>)
 => (required :: <sequence>, rest? :: <boolean>,
     keys :: <sequence>, all-keys? :: <boolean>);
  let spec-parameters = %function-spec-parameters(function-spec);
  local
    method identify-required
        (index :: <integer>)
     => (required :: <sequence>, rest? :: <boolean>,
         keys :: <sequence>, all-keys? :: <boolean>);
      if (index < spec-parameters.size)
        let item = spec-parameters[index];
        if (instance?(item, <type>))
          identify-required(index + 1)
        else
          let required = copy-sequence(spec-parameters, end: index);
          if (item == #"rest")
            identify-key(required, #t, index + 1)
          else
            identify-key(required, #f, index)
          end if
        end if
      else
        values(spec-parameters, #f, #[], #f)
      end if
    end method,
    method identify-key
        (required :: <sequence>, rest? :: <boolean>, index :: <integer>)
     => (required :: <sequence>, rest? :: <boolean>,
         keys :: <sequence>, all-keys? :: <boolean>);
      if (index < spec-parameters.size)
        let item = spec-parameters[index];
        if (item == #"key")
          identify-keys(required, rest?, index + 1, index + 1)
        else
          error("Unrecognized parameter %= in %s", item,
                spec-name(function-spec));
        end if
      else
        values(required, rest?, #[], #f)
      end if
    end method,
    method identify-keys
        (required :: <sequence>, rest? :: <boolean>,
         first-key-index :: <integer>, index :: <integer>)
     => (required :: <sequence>, rest? :: <boolean>,
         keys :: <sequence>, all-keys? :: <boolean>);
      if (index < spec-parameters.size)
        let item = spec-parameters[index];
        if (item == #"all-keys")
          if (index + 1 ~= spec-parameters.size)
            error("#\"all-keys\" must appear as the last parameter item");
          end if;
          let keys
            = copy-sequence(spec-parameters,
                            start: first-key-index, end: index);
          values(required, rest?, keys, #t)
        elseif (instance?(item, <symbol>))
          identify-keys(required, rest?, first-key-index, index + 1)
        else
          error("Unrecognized parameter %= in %s", item,
                spec-name(function-spec));
        end if
      else
        let keys
          = copy-sequence(spec-parameters, start: first-key-index, end: index);
        values(required, rest?, keys, #f)
      end if
    end method;
  identify-required(0)
end method function-spec-parameters;

define method function-spec-results
    (function-spec :: <function-spec>)
 => (required :: <sequence>, rest? :: <boolean>);
  let spec-results = %function-spec-results(function-spec);
  local
    method identify-required
        (index :: <integer>)
     => (required :: <sequence>, rest? :: <boolean>);
      if (index < spec-results.size)
        let item = spec-results[index];
        if (instance?(item, <type>))
          identify-required(index + 1)
        elseif (item == #"rest")
          if (index + 1 ~= spec-results.size)
            error("#\"rest\" must appear as the last parameter item");
          end if;
          values(copy-sequence(spec-results, end: index), #t)
        else
          error("Unrecognized result %= in %s", item,
                spec-name(function-spec));
        end if
      else
        values(spec-results, #f)
      end if
    end method;
  identify-required(0)
end method function-spec-results;

define method function-spec-generic?
    (function-spec :: <function-spec>)
 => (generic? :: <boolean>)
  member?(#"generic", function-spec-modifiers(function-spec))
end method function-spec-generic?;

define function function-spec-type
    (function-spec :: <function-spec>)
 => (type :: <type>, type-name :: <string>)
  if (function-spec-generic?(function-spec))
    values(<generic-function>, "generic-function")
  else
    values(<function>, "function")
  end
end function function-spec-type;

define function function-spec-check-name
    (function-name :: <string>, type-name :: <string>)
 => (check-name :: <string>)
  format-to-string("Variable %s is a %s and all of its specializer types"
                     " are bound", function-name, type-name)
end function function-spec-check-name;

define function check-function-specification-parameters
    (title :: <string>, function-spec :: <function-spec>)
 => ();
  let function = function-spec-function(function-spec);
  let (required :: <sequence>, rest? :: <boolean>,
       keys :: <sequence>, all-keys? :: <boolean>)
    = function-spec-parameters(function-spec);
  let actual-specializers
    = function-specializers(function);
  let (actual-required-number, actual-rest?, actual-keys)
    = function-arguments(function);

  check-true(format-to-string("function %s can handle the maximum number"
                                " of specified arguments", title),
             actual-rest?
               | (~rest? & required.size <= actual-required-number));
  check-true(format-to-string("function %s can handle the minimum number"
                                " of specified arguments", title),
             required.size >= actual-required-number);

  // TODO(cgay): This fails for cases where a library adds a method to
  // an existing generic function. For example,
  //     open generic-function \< (<date>, <date>) => (<boolean>);
  // The generic is defined on (<object>, <object>) so the below test fails.
  // We should be able to iterate over the gf methods and see if there's
  // one exactly matching the spec's types.  (On the other hand, having
  // that in the spec doesn't seem nearly as useful as writing a test that
  // calls <date> < <date> and gets the right result.)

  for (spec in required,
       actual in actual-specializers,
       index from 0)
    check-true(format-to-string("function %s argument %d type %s"
                                  " is a subtype of the specified type %s",
                                title, index, actual, spec),
               subtype?(actual, spec));
  end for;

  for (key in keys)
    check-true(format-to-string("function %s can handle keyword"
                                  " argument %=", title, key),
               actual-rest?
                 | actual-keys == #"all"
                 | (instance?(actual-keys, <sequence>)
                      & member?(key, actual-keys)));
  end for;
  if (all-keys?)
    check-true(format-to-string("function %s can handle all keywords", title),
               actual-rest? | actual-keys == #"all");
  end if;
end function;

define function check-function-specification-results
    (title :: <string>, function-spec :: <function-spec>)
 => ();
  let function = function-spec-function(function-spec);
  let (required :: <sequence>, rest? :: <boolean>)
    = function-spec-results(function-spec);
  let (actual-return-types, actual-rest?) = function-return-values(function);
  check-true(format-to-string("function %s can return the minimum number"
                                " of specified return values", title),
             actual-return-types.size >= required.size
               | actual-rest?);
  check-true(format-to-string("function %s can not exceed the maximum number"
                                " of specified return values", title),
             actual-return-types.size <= required.size
               | rest?);
  for (spec in required, return-type in actual-return-types, index from 0)
    check-true(format-to-string("function %s return value %d type %s"
                                  " is a subtype of the specified type %s",
                                title, index, return-type, spec),
               subtype?(return-type, spec));
  end for;
end function;

define function check-function-specification
    (function-spec :: <function-spec>)
 => ()
  let title = spec-title(function-spec);
  let function = function-spec-function(function-spec);
  let (type, type-name) = function-spec-type(function-spec);
  check-instance?(function-spec-check-name(title, type-name),
                  type, function);
  check-function-specification-parameters(title, function-spec);
  check-function-specification-results(title, function-spec);
end function check-function-specification;

/// A useful macro to define a macro test

define macro macro-test-definer
  { define ?protocol-name:name macro-test ?macro-name:name ()
      ?body:body
    end }
    => { define test "test-macro-" ## ?macro-name (requires-assertions?: #f)
           ?body
         end }
end macro macro-test-definer;
