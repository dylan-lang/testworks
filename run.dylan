Module:       testworks
Summary:      Test run execution logic.
Author:       Andrew Armstrong, James Kirsch
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND


define constant $all-tags = #[#"all"];

define method announce-component
    (component :: <component>) => ()
  test-output("Running %s %s...\n",
              component.component-type-name, component.component-name);
end;

*announce-function* := announce-component;

define method debug-failures?
    () => (debug-failures? :: <boolean>)
  *debug?* == #t
end method debug-failures?;

define method debug?
    () => (debug? :: <boolean>)
  *debug?* ~= #f
end method debug?;

define method test-output
    (format-string :: <string>, #rest format-args) => ()
  apply(*format-function*, format-string, format-args)
end method test-output;

/// Perform options

// this class defines all the options that might be used
// to control test suite performing.

// TODO(cgay): Rename to <test-run> and dispatch on it so that we
// don't need all these thread variables and there are better
// opportunities to modify testworks' behavior.  Or just rename to
// <options> for brevity.

define open class <perform-options> (<object>)
  slot perform-tags :: <sequence> = $all-tags,
    init-keyword: tags:;
  slot perform-announce-function :: false-or(<function>) = *announce-function*,
    init-keyword: announce-function:;
  slot perform-announce-checks? :: <boolean> = *announce-checks?*,
    init-keyword: announce-checks?:;
  slot perform-progress-format-function = *format-function*,
    init-keyword: progress-format-function:;
  slot perform-progress-function = *default-progress-function*,
    init-keyword: progress-function:;
  slot perform-debug? = *debug?*,
    init-keyword: debug?:;
end class <perform-options>;


// Encapsulates the components to be ignored
// TODO(cgay): I see no reason for this to be separate from <perform-options>.

define class <perform-criteria> (<perform-options>)
  slot perform-ignore :: <stretchy-vector>,   // of components
    init-keyword: ignore:;
  slot list-suites? :: <boolean> = #f;
  slot list-tests? :: <boolean> = #f;
end class <perform-criteria>;


///*** Generic Classes, Helper Functions, and Helper Macros ***///

define method plural (n :: <integer>) => (ending :: <string>)
  if (n == 1) "" else "s" end if
end;

define macro maybe-trap-errors
  { maybe-trap-errors (?body:body) }
    => { local method maybe-trap-errors-body () ?body end;
         if (*debug?*)
           maybe-trap-errors-body();
         else
           block ()
             maybe-trap-errors-body();
           exception (cond :: <serious-condition>)
             cond
           end;
         end; }
end macro maybe-trap-errors;

define method tags-match? (run-tags :: <sequence>, object-tags :: <sequence>)
 => (bool :: <boolean>)
  run-tags = $all-tags | ~empty?(intersection(run-tags, object-tags))
end method tags-match?;

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

define method perform-suite
    (suite :: <suite>,
     #key tags                     = $all-tags,
          announce-function        = #f,
          announce-checks?         = *announce-checks?*,
          report-format-function   = *format-function*,
          progress-format-function = *format-function*,
          report-function          = *default-report-function*,
          progress-function        = *default-progress-function*,
          debug?                   = *debug?*)
 => (result :: <component-result>)
  perform-component
    (suite,
     make(<perform-options>,
          tags:                     tags,
          announce-function:        announce-function,
          announce-checks?:         announce-checks?,
          progress-format-function: progress-format-function,
          progress-function:        progress-function | null-progress-function,
          debug?:                   debug?),
     report-function:        report-function | null-report-function,
     report-format-function: report-format-function)
end method perform-suite;

// perform-test takes a <test> object and returns a component-result object.

define method perform-test
    (test :: <test>,
     #key tags                     = $all-tags,
          announce-function        = *announce-function*,
          announce-checks?         = *announce-checks?*,
          progress-format-function = *format-function*,
          report-format-function   = *format-function*,
          progress-function        = *default-progress-function*,
          report-function          = *default-report-function*,
          debug?                   = *debug?*)
 => (result :: <component-result>)
  perform-component
    (test,
     make(<perform-options>,
          tags:                     tags,
          announce-function:        announce-function,
          announce-checks?:         announce-checks?,
          progress-report-function: progress-format-function,
          progress-function:        progress-function | null-progress-function,
          debug?:                   debug?),
     report-function:        report-function | null-report-function,
     report-format-function: report-format-function);
end method perform-test;

// TODO(cgay): Remove this; it's not needed.
define method perform-test
    (function :: <function>,
     #key tags                     = $all-tags,
          announce-function        = *announce-function*,
          announce-checks?         = *announce-checks?*,
          progress-format-function = *format-function*,
          report-format-function   = *format-function*,
          progress-function        = *default-progress-function*,
          report-function          = *default-report-function*,
          debug?                   = *debug?*)
 => (result :: <component-result>)
  let test = find-test-object(function);
  if (test)
    perform-test(test,
                 tags: tags,
                 announce-function:        announce-function,
                 announce-checks?:         announce-checks?,
                 progress-format-function: progress-format-function,
                 report-format-function:   report-format-function,
                 progress-function:        progress-function,
                 report-function:          report-function,
                 debug?:                   debug?)
  else
    error("Cannot perform-test on the non-test function %=", function)
  end
end method perform-test;



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
  let (subresults, status, reason, seconds, microseconds, bytes)
    = if (execute-component?(component, options))
        execute-component(component, options)
      else
        values(#(), $skipped, 0, 0, 0)
      end;
  make(component-result-type(component),
       name: component.component-name,
       status: status,
       reason: reason,
       subresults: subresults,
       seconds: seconds,
       microseconds: microseconds,
       bytes: bytes)
end method maybe-execute-component;

define method execute-component
    (suite :: <suite>, options :: <perform-options>)
 => (subresults :: <sequence>, status :: <result-status>, reason :: false-or(<string>),
     seconds :: <integer>, microseconds :: <integer>, bytes :: <integer>)
  let subresults :: <stretchy-vector> = make(<stretchy-vector>);
  let seconds :: <integer> = 0;
  let microseconds :: <integer> = 0;
  let bytes :: <integer> = 0;
  let (status, reason)
    = block ()
        suite.suite-setup-function();
        for (component in suite.suite-components)
          let subresult = maybe-execute-component(component, options);
          add!(subresults, subresult);
          if (instance?(subresult, <component-result>)
              & subresult.result-seconds
              & subresult.result-microseconds)
            let (sec, usec) = add-times(seconds, microseconds,
                                        subresult.result-seconds,
                                        subresult.result-microseconds);
            seconds := sec;
            microseconds := usec;
            bytes := bytes + subresult.result-bytes;
          else
            test-output("subresult has no profiling info: %s\n",
                        subresult.result-name);
          end;
        end for;
        case
          empty?(subresults) =>
            $not-implemented;
          every?(method (subresult)
                   let status = subresult.result-status;
                   status = $passed | status = $skipped
                 end,
                 subresults) =>
            $passed;
          otherwise =>
            $failed
        end case
      cleanup
        suite.suite-cleanup-function();
      end block;
  values(subresults, status, reason, seconds, microseconds, bytes)
end method execute-component;

define method execute-component
    (test :: <test>, options :: <perform-options>)
 => (subresults :: <sequence>, status :: <result-status>, reason :: false-or(<string>),
     seconds :: <integer>, microseconds :: <integer>, bytes :: <integer>)
  let subresults = make(<stretchy-vector>);
  let (seconds, microseconds, bytes) = values(0, 0, 0);
  let (status, reason)
    = dynamic-bind (*debug?* = options.perform-debug?,
                    *check-recording-function* =
                      method (result :: <result>)
                        add!(subresults, result);
                        options.perform-progress-function(result);
                        result
                      end,
                    *test-unit-options* = options)
        let cond = #f;
        profiling (cpu-time-seconds, cpu-time-microseconds, allocation)
          cond := maybe-trap-errors(test.test-function());
        results
          seconds := cpu-time-seconds;
          microseconds := cpu-time-microseconds;
          bytes := allocation;
        end profiling;
        case
          instance?(cond, <serious-condition>) =>
            values($crashed, format-to-string("%s", cond));
          empty?(subresults) & ~test.test-allow-empty? =>
            $not-implemented;
          every?(method (result :: <unit-result>) => (passed? :: <boolean>)
                   result.result-status == $passed
                 end,
                 subresults) =>
            $passed;
          otherwise =>
            $failed;
        end
      end;
  values(subresults, status, reason, seconds, microseconds, bytes)
end method execute-component;

define method list-component
    (test :: <test>, options :: <perform-options>)
 => (list :: <sequence>)
  if (execute-component?(test, options))
    vector(test);
  else
    #[];
  end if
end method list-component;

define method list-component
    (suite :: <suite>, options :: <perform-options>)
 => (list :: <sequence>)
  let sublist :: <stretchy-vector> = make(<stretchy-vector>);
  if (execute-component?(suite, options))
    add!(sublist, suite);
    for (component in suite.suite-components)
      sublist := concatenate!(sublist, list-component(component, options));
    end for;
  end if;
  sublist
end method list-component;
    


define method null-progress-function
    (result :: <unit-result>) => ()
  #f
end method null-progress-function;

define method full-progress-function
    (result :: <unit-result>) => ()
  print-check-progress(result)
end method full-progress-function;

define variable *default-progress-function* = null-progress-function;

