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
  // TODO(cgay): For tests and suites, name is a name, but for
  // assertions it tends to be a description.
  constant slot component-name :: <string>,
    required-init-keyword: name:;

  // TODO(cgay): This is more or less unused.  I think we can get rid
  // of it and simply rely on doc comments on the tests and suites.
  constant slot component-description :: <string> = "",
    init-keyword: description:;

  constant slot component-tags :: <sequence> = #[],
    init-keyword: tags:;
end class <component>;


define class <suite> (<component>)
  // TODO(cgay): Why should this ever be anything but a sequence?
  constant slot %components :: false-or(type-union(<sequence>, <function>)) = #f,
    init-keyword: components:;
  constant slot suite-setup-function :: <function> = method () end,
    init-keyword: setup-function:;
  constant slot suite-cleanup-function :: <function> = method () end,
    init-keyword: cleanup-function:;
end class <suite>;


define class <test> (<component>)
  constant slot test-function :: <function>,
    required-init-keyword: function:;
  constant slot test-allow-empty? :: <boolean>,
    init-value: #f, init-keyword: allow-empty:;
end class <test>;

define class <test-unit> (<test>)
end class <test-unit>;


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
  <unit-result>
end;


/// Suites

define variable *all-suites*
  = make(<suite>,
         name: "All Defined Suites",
         components: make(<stretchy-vector>));

define method root-suite () => (suite :: <suite>)
  *all-suites*
end method root-suite;

define method ensure-suite-components
    (components :: <sequence>, suite :: <suite>)
 => (components :: <sequence>)
  map(method (component)
        select (component by instance?)
          <component> =>
            component;
          <function>  =>
            find-test-object(component)
              | error("Non-test function %= in suite %s",
                      component, component-name(suite));
          otherwise   =>
            error("Invalid object %= in suite %s", component, component-name(suite))
        end
      end,
      components)
end method ensure-suite-components;

define method suite-components
    (suite :: <suite>) => (components :: <sequence>)
  let components = suite.%components;
  select (components by instance?)
    <sequence> => components;
    <function> => ensure-suite-components(components(), suite)
  end
end method suite-components;

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
  { define suite ?suite-name:name (?keyword-args:*) ?components end } =>
    {define variable ?suite-name
       = make-suite(?"suite-name",
                    method ()
                      list(?components)
                    end,
                    ?keyword-args) }

  components:
    { } => { }
    { test ?:name; ... }
      => { ?name, ... }
    { suite ?:name; ... }
      => { ?name, ... }
end macro suite-definer;


/// Tests

define constant $test-objects-table = make(<table>);

define method find-test-object
    (function :: <function>) => (test :: false-or(<test>))
  element($test-objects-table, function, default: #f)
end method find-test-object;

// the test macro

//---*** We could use 'define function' but it doesn't debug as well right now
define macro test-definer
  { define test ?test-name:name (?keyword-args:*) ?test-body:body end }
    => { define method ?test-name ()
           ?test-body
         end;
         $test-objects-table[?test-name]
           := make(<test>,
                   name: ?"test-name",
                   function: ?test-name,
                   ?keyword-args); }
end macro test-definer;

// with-test-unit macro


define thread variable *test-unit-options* = make(<perform-options>);

define macro with-test-unit
  { with-test-unit (?name:expression, ?keyword-args:*) ?test-body:body end }
    => { begin
           let test
             = make(<test-unit>,
                    name: concatenate("Test unit ", ?name),
                    function: method () ?test-body end,
                    ?keyword-args);
           let result = perform-component(test, *test-unit-options*,
                                          report-function: #f);
           *check-recording-function*(result);
         end; }
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
                  if (subsuite) return(subsuite) end;
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
                  if (test) return(test) end;
              end
            end
          end
        end;
  do-find-test(search-suite);
end method find-test;
