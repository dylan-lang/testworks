Module:       %testworks
Synopsis:     Components are suites, tests, and benchmarks.
Author:       Shri Amit, Andrew Armstrong
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND


// The class of objects that can be "performed" in a test suite.
define abstract class <component> (<object>)
  constant slot component-name :: <string>,
    required-init-keyword: name:;
end class <component>;

define function full-component-name (c :: <component>) => (name :: <string>)
  // TODO(cgay): return the full path from the root to this component so that
  // --match and --skip can use it. Need to store back pointers to parent
  // suites.
  c.component-name
end;

define generic suite-components (suite :: <suite>) => (components :: <sequence> /* of <component> */);
define generic suite-setup-function (suite :: <suite>) => (function :: <function>);
define generic suite-cleanup-function (suite :: <suite>) => (function :: <function>);

define class <suite> (<component>)
  constant slot suite-components :: <sequence> /* of <component> */ = #[],
    init-keyword: components:;
  constant slot suite-setup-function :: <function> = method () end,
    init-keyword: setup-function:;
  constant slot suite-cleanup-function :: <function> = method () end,
    init-keyword: cleanup-function:;
end class <suite>;

define method make (class == <suite>, #rest args, #key) => (suite :: <suite>)
  let suite = next-method();
  check-for-tests-included-multiple-times(suite);
  suite
end;

// Signal an error if any test is included in a suite more than once,
// transitively.
define function check-for-tests-included-multiple-times (suite :: <suite>)
  let seen = make(<table>);
  local method check-seen (runnable :: <runnable>)
          let function = runnable.test-function;
          if (element(seen, function, default: #f))
            cerror("Continue and run the test multiple times",
                   "test %= is included in suite %= multiple times",
                   runnable.component-name,
                   suite.component-name);
          else
            seen[function] := function;
          end;
        end method;
  do-components(suite, check-seen, type: <runnable>);
end function;

// Call `function` on each component of type `type` under `component`.
define function do-components
    (component :: <component>, function :: <function>, #key type = <component>)
  if (instance?(component, type))
    function(component);
  end;
  if (instance?(component, <suite>))
    for (child in component.suite-components)
      do-components(child, function, type: type);
    end;
  end;
end function;

define generic test-tags (r :: <runnable>) => (tags :: <sequence> /* of <tag> */);
define generic test-function (r :: <runnable>) => (fn :: <function>);
define generic test-requires-assertions? (r :: <runnable>) => (required? :: <boolean>);

define abstract class <runnable> (<component>)
  constant slot test-function :: <function>,
    required-init-keyword: function:;
  constant slot %expected-to-fail? :: type-union(<boolean>, <function>) = #f,
    init-keyword: expected-to-fail?:;
  // Benchmarks don't require assertions.  Needs to be an instance
  // variable, not a bare method, because testworks-specs
  // auto-generated tests often don't get filled in.  I want to kill
  // testworks-specs with fire.
  constant slot test-requires-assertions? :: <boolean> = #t,
    init-keyword: requires-assertions?:;
  constant slot test-tags :: <sequence> /* of <tag> */ = #[],
    init-keyword: tags:;
end class <runnable>;

define method make
    (class :: subclass(<runnable>), #rest args, #key name, tags)
 => (runnable :: <runnable>)
  let tags = map(make-tag, tags | #[]);
  let negative = choose(tag-negated?, tags);
  if (~empty?(negative))
    error("Tags associated with tests or benchmarks may not be negated.  Test: %s, Tags: %s",
          name, negative);
  end;
  apply(next-method, class, tags: tags, args)
end method make;

define method expected-to-fail? (r :: <runnable>)
  select (r.%expected-to-fail? by instance?)
    <boolean> => r.%expected-to-fail?;
    <function> => r.%expected-to-fail?();
  end select
end method;

define class <test> (<runnable>)
end;

define class <test-unit> (<test>)
end;


define generic component-type-name
    (component :: <component>) => (type-name :: <string>);

define method component-type-name
    (test :: <test>) => (type-name :: <string>)
  "test"
end;

define method component-type-name
    (test-unit :: <test-unit>) => (type-name :: <string>)
  "test unit"
end;

define method component-type-name
    (suite :: <suite>) => (type-name :: <string>)
  "suite"
end;

define method component-type-name
    (component :: <component>) => (type-name :: <string>)
  "component"
end;


// Get the result type for a component.  This isn't needed for checks;
// only for components with subresults.
define generic component-result-type
    (component :: <component>) => (result-type :: subclass(<result>));

define method component-result-type
    (component :: <component>) => (result-type :: subclass(<result>))
  <component-result>
end;

define method component-result-type
    (component :: <test>) => (result-type :: subclass(<result>))
  <test-result>
end;

define method component-result-type
    (component :: <suite>) => (result-type :: subclass(<result>))
  <suite-result>
end;

define method component-result-type
    (component :: <test-unit>) => (result-type :: subclass(<result>))
  <test-unit-result>
end;

// All tests, benchmarks, and suites are added to this when created.
define constant $components = make(<stretchy-vector>);

// Add `c` to `$components` or replace an existing component with the
// same name.
define function register-component (c :: <component>) => ()
  let pos = find-key($components, method (comp)
                                    c.component-name = comp.component-name
                                  end);
  if (pos)
    cerror("Replace the test and continue",
           "a test named %= already exists", c.component-name);
    $components[pos] := c;
  else
    add!($components, c);
  end;
end;


/// Suites

define method make-suite
    (name :: <string>, components, #rest keyword-args)
 => (suite :: <suite>)
  let suite = apply(make, <suite>,
                    name: name,
                    components: components,
                    keyword-args);
  register-component(suite);
  suite
end method make-suite;

define macro suite-definer
  { define suite ?suite-name:name (?keyword-args:*) ?components end
  } => {
    define constant ?suite-name
      = make-suite(?"suite-name", list(?components), ?keyword-args)
  }
 components:
  { } => { }
  { test ?:name; ... } => { ?name, ... }
  { benchmark ?:name; ... } => { ?name, ... }
  { suite ?:name; ... } => { ?name, ... }
end macro suite-definer;


/// Tests

define macro test-definer
  { define test ?test-name:name (?keyword-args:*) ?test-body:body end
  } => {
    define function "%%" ## ?test-name () ?test-body end;
    define constant ?test-name = make(<test>,
                                      name: ?"test-name",
                                      function: "%%" ## ?test-name,
                                      ?keyword-args);
    register-component(?test-name);
  }
end macro test-definer;

define macro benchmark-definer
  { define benchmark ?test-name:name (?keyword-args:*) ?test-body:body end
  } => {
    define function "%%" ## ?test-name () ?test-body end;
    define constant ?test-name :: <benchmark>
      = make(<benchmark>,
             name: ?"test-name",
             function: "%%" ## ?test-name,
             ?keyword-args);
    register-component(?test-name);
  }
end macro benchmark-definer;

// For backward compatibility.
define macro with-test-unit
  { with-test-unit (?name:expression, ?keyword-args:*)
      ?test-body:body
    end
  } => { ?test-body }
end macro with-test-unit;

// Find a minimal set of components that cover all tests and return
// them.
define function find-root-components () => (components :: <sequence>)
  let refs = make(<table>);
  for (c in $components)
    refs[c] := 0;
  end;
  // Any suite that _contains_ another component is a ref.  Since
  // $components contains _all_ components there's no need to traverse
  // the full suite hierarchy recursively.
  for (c in $components)
    if (instance?(c, <suite>))
      for (sub in suite-components(c))
        refs[sub] := refs[sub] + 1;
      end;
    end;
  end;
  let roots = make(<stretchy-vector>);
  for (count keyed-by c in refs)
    if (count = 0)
     add!(roots, c);
    end;
  end;
  roots
end;
