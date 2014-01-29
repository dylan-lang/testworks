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
define class <component> (<object>)
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

define class <test> (<component>)
  constant slot test-function :: <function>,
    required-init-keyword: function:;
  constant slot test-allow-empty? :: <boolean> = #f,
    init-keyword: allow-empty:;
  constant slot test-tags :: <sequence> /* of <tag> */ = #[],
    init-keyword: tags:;
end class <test>;

define method make
    (class :: subclass(<test>), #rest args, #key name, tags)
 => (test :: <test>)
  let tags = map(make-tag, tags | #[]);
  let negative = choose(tag-negated?, tags);
  if (~empty?(negative))
    error("Tags associated with tests may not be negated.  Test: %s, Tags: %s",
          name, negative);
  end;
  apply(next-method, class, tags: tags, args)
end method make;

// Benchmarks are just tests that don't require any assertions.
define class <benchmark> (<test>)
  inherited slot test-allow-empty? = #t;
end;

define method make
    (class :: subclass(<benchmark>), #rest args, #key tags)
 => (test :: <benchmark>)
  let new-tags = concatenate(#["benchmark"], tags | #[]);
  apply(next-method, class, tags: new-tags, args)
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
    (bench :: <benchmark>) => (type-name :: <string>)
  "benchmark"
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
    (component :: <benchmark>) => (result-type :: subclass(<result>))
  <benchmark-result>
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

define macro test-definer
  { define test ?test-name:name (?keyword-args:*) ?test-body:body end
  } => {
    define constant ?test-name :: <test>
      = make(<test>,
             name: ?"test-name",
             function: method () ?test-body end,
             ?keyword-args);
  }
end macro test-definer;

define macro benchmark-definer
  { define benchmark ?test-name:name (?keyword-args:*) ?test-body:body end
  } => {
    define constant ?test-name :: <benchmark>
      = make(<benchmark>,
             name: ?"test-name",
             function: method () ?test-body end,
             ?keyword-args);
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

define method find-test
    (name :: <string>, #key search-suite = root-suite())
 => (test :: false-or(<test>))
  let lowercase-name = as-lowercase(name);
  local method do-find-test (suite :: <suite>)
          block (return)
            for (object in suite-components(suite))
              select (object by instance?)
                <test> =>
                  if (as-lowercase(component-name(object)) = lowercase-name)
                    return(object)
                  end if;
                <suite> =>
                  let test = do-find-test(object);
                  if (test)
                    return(test)
                  end;
              end
            end
          end
        end;
  do-find-test(search-suite);
end method find-test;
