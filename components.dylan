Module:       %testworks
Synopsis:     Components are suites and tests.
Author:       Shri Amit, Andrew Armstrong
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND


/// This is the class of objects that can be performed in a test
/// suite.  Note that there are no <assertion> or <check> classes so
/// they aren't considered "components".
define abstract class <component> (<object>)
  constant slot component-name :: <string>,
    required-init-keyword: name:;
end class <component>;

define class <suite> (<component>)
  constant slot suite-components :: <sequence> /* of <component> */ = #[],
    init-keyword: components:;
  constant slot suite-setup-function :: <function> = method () end,
    init-keyword: setup-function:;
  constant slot suite-cleanup-function :: <function> = method () end,
    init-keyword: cleanup-function:;
end class <suite>;

define abstract class <runnable> (<component>)
  constant slot test-function :: <function>,
    required-init-keyword: function:;
  constant slot %expected-failure? :: type-union(<boolean>, <function>) = #f,
    init-keyword: expected-failure?:;
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

define method expected-failure? (r :: <runnable>)
  select (r.%expected-failure? by instance?)
    <boolean> => r.%expected-failure?;
    <function> => r.%expected-failure?();
  end select
end method expected-failure?;

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


/// Suites

define constant $root-suite = make(<suite>,
                                   name: "All Defined Suites",
                                   components: make(<stretchy-vector>));

define method root-suite () => (suite :: <suite>)
  $root-suite
end;

define method make-suite
    (name :: <string>, components, #rest keyword-args)
 => (suite :: <suite>)
  let suite = apply(make, <suite>,
                    name: name,
                    components: components,
                    keyword-args);
  let all-suites :: <stretchy-vector> = root-suite().suite-components;
  let position = find-key(all-suites,
                          method (suite)
                            suite.component-name = name
                          end);
  if (position)
    all-suites[position] := suite
  else
    add!(all-suites, suite)
  end;
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

// All tests and benchmarks are registered here.
define constant $tests = make(<stretchy-vector>);

define function register-test (test :: <runnable>)
  if (member?(test, $tests, test: method (t1, t2)
                                    component-name(t1) = component-name(t2)
                                  end))
    error("Duplicate test name: %=", component-name(test));
  end;
  add!($tests, test);
end;

define macro test-definer
  { define test ?test-name:name (?keyword-args:*) ?test-body:body end
  } => {
    define function "%%" ## ?test-name () ?test-body end;
    define constant ?test-name = make(<test>,
                                      name: ?"test-name",
                                      function: "%%" ## ?test-name,
                                      ?keyword-args);
    register-test(?test-name);
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
    register-test(?test-name);
  }
end macro benchmark-definer;

// For backward compatibility.
define macro with-test-unit
  { with-test-unit (?name:expression, ?keyword-args:*)
      ?test-body:body
    end
  } => { ?test-body }
end macro with-test-unit;

define method find-suite
    (name :: <string>, #key search-suite = root-suite())
 => (suite :: false-or(<suite>))
  let lowercase-name = as-lowercase(name);
  local method do-find-suite (suite :: <suite>)
          if (as-lowercase(component-name(suite)) = lowercase-name)
            suite
          else
            block (return)
              for (object in suite-components(suite))
                if (instance?(object, <suite>))
                  let subsuite = do-find-suite(object);
                  if (subsuite)
                    return(subsuite)
                  end;
                end
              end
            end
          end
        end;
  do-find-suite(search-suite);
end method find-suite;

define method find-runnable
    (name :: <string>, #key search-suite = root-suite())
 => (test :: false-or(<runnable>))
  let lowercase-name = as-lowercase(name);
  local method do-find-runnable (suite :: <suite>)
          block (return)
            for (object in suite-components(suite))
              select (object by instance?)
                <runnable> =>
                  if (as-lowercase(component-name(object)) = lowercase-name)
                    return(object)
                  end if;
                <suite> =>
                  let test = do-find-runnable(object);
                  if (test)
                    return(test)
                  end;
              end
            end
          end
        end;
  do-find-runnable(search-suite);
end method find-runnable;
