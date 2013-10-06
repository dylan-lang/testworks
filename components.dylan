Module:       testworks
Synopsis:     Contains <component> definitions for Testworks test harness
Author:       Shri Amit, Andrew Armstrong
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// Component
///
/// This is the class of objects that can be performed in a test suite.
/// It is the superclass of both <test> and <suite>.  Note that there are
/// no <check> or <benchmark> classes so they aren't considered "components".

define class <component> (<object>)
  constant slot component-name :: <string>,
    required-init-keyword: name:;
  constant slot component-description :: <string> = "",
    init-keyword: description:;
  constant slot component-tags :: <sequence> = #[],
    init-keyword: tags:;
end class <component>;


define generic component-type-name
    (component :: <component>) => (type-name :: <string>);

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



/// Result handling

define class <component-result> (<result>)
  constant slot result-subresults :: <sequence> = make(<stretchy-vector>),
    init-keyword: subresults:;

  // Profiling data...

  constant slot result-seconds :: false-or(<integer>),
    required-init-keyword: seconds:;
  constant slot result-microseconds :: false-or(<integer>),
    required-init-keyword: microseconds:;
  // Hopefully no benchmarks will allocate more than 536MB haha...
  constant slot result-bytes :: false-or(<integer>),
    required-init-keyword: bytes:;
end class <component-result>;

define class <test-result> (<component-result>)
end class <test-result>;

define method result-type-name
    (result :: <test-result>) => (name :: <string>)
  "Test"
end;

define class <suite-result> (<component-result>)
end class <suite-result>;

define method result-type-name
    (result :: <suite-result>) => (name :: <string>)
  "Suite"
end;


/// Perform component

define method perform-component
    (component :: <component>, options :: <perform-options>,
     #key report-function        = *default-report-function*,
          report-format-function = *format-function*)
 => (component-result :: <component-result>)
  let progress-format-function
    = options.perform-progress-format-function;
  let announce-checks? = options.perform-announce-checks?;
  let result
    = dynamic-bind (*format-function* = progress-format-function,
                    *announce-checks?* = announce-checks?)
        maybe-execute-component(component, options)
      end;
  display-results(result,
                  report-function: report-function,
                  report-format-function: report-format-function);
  result;
end method perform-component;


/// Execute component

// This function can be used to implement any desired
// criteria to execute or not execute independent
// tests & suites.

define open generic execute-component?
    (component :: <component>, options :: <perform-options>);

define method execute-component?
    (component :: <component>, options :: <perform-options>)
 => (answer :: <boolean>)
  tags-match?(options.perform-tags, component.component-tags);
end method execute-component?;

define method maybe-execute-component
    (component :: <component>, options :: <perform-options>)
 => (result :: <component-result>)
  let announce-function
    = options.perform-announce-function;
  if (announce-function)
    announce-function(component)
  end;
  let (subresults, status, seconds, microseconds, bytes)
    = if (execute-component?(component, options))
        execute-component(component, options)
      else
        values(#(), $skipped, 0, 0, 0)
      end;
  make(component-result-type(component),
       name: component.component-name,
       status: status,
       subresults: subresults,
       seconds: seconds,
       microseconds: microseconds,
       bytes: bytes)
end method maybe-execute-component;
