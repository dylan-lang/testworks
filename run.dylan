Module:       %testworks
Summary:      Test run execution logic.
Author:       Andrew Armstrong, James Kirsch
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND


define method announce-component
    (component :: <component>) => ()
  test-output("Running %s %s...\n",
              component.component-type-name, component.component-name);
end;

define inline function debug-failures?
    () => (debug-failures? :: <boolean>)
  debug-runner?(*runner*) == #t
end;

define inline function debug?
    () => (debug? :: <boolean>)
  debug-runner?(*runner*) ~= #f
end;

define method test-output
    (format-string :: <string>, #rest format-args) => ()
  apply(format, runner-output-stream(*runner*), format-string, format-args);
end;


// A <test-runner> holds options for the test run and collects results.
// TODO(cgay): Remove the *-function slots and provide methods for
// subclassers to override instead.
define open class <test-runner> (<object>)
  // TODO(cgay): <report> = one-of(#"failures", #"crashes", #"none", ...)
  //constant slot runner-report :: <string> = "failures",
  //  init-keyword: report:;
  constant slot runner-tags :: <sequence> = $all-tags,
    init-keyword: tags:;
  slot runner-announce-function :: false-or(<function>) = announce-component,
    init-keyword: announce-function:;
  slot runner-progress-function = null-progress-function,
    init-keyword: progress-function:;
  constant slot debug-runner? = #f,
    init-keyword: debug?:;
  constant slot runner-ignore :: <sequence> = #[],   // of components
    init-keyword: ignore:;

  // The stream on which output is done.  Note that this may be bound
  // to different streams during the test run and when the report is
  // generated.  e.g., to output the report to a file.
  constant slot runner-output-stream :: <stream> = *standard-output*,
    init-keyword: output-stream:;

end class <test-runner>;


///*** Generic Classes, Helper Functions, and Helper Macros ***///

// TODO(cgay): Use let handler instead.
define macro maybe-trap-errors
  { maybe-trap-errors (?body:body) }
    => { local method maybe-trap-errors-body () ?body end;
         if (debug?())
           maybe-trap-errors-body();
         else
           block ()
             maybe-trap-errors-body();
           exception (cond :: <serious-condition>)
             cond
           end;
         end; }
end macro maybe-trap-errors;

// TODO(cgay): Move report-function into <test-runner>.
define function run-tests
    (runner :: <test-runner>, component :: <component>,
     #key report-function = *default-report-function*)
 => (component-result :: <component-result>)
  let result = dynamic-bind (*runner* = runner)
                 maybe-execute-component(component, runner)
               end;
  report-function & report-function(result);
  result
end function run-tests;


/// Execute component

define open generic execute-component?
    (component :: <component>, runner :: <test-runner>)
 => (execute? :: <boolean>);

define method execute-component?
    (component :: <component>, runner :: <test-runner>)
 => (execute? :: <boolean>)
  tags-match?(runner.runner-tags, component.component-tags)
  & ~member?(component, runner.runner-ignore)
end method execute-component?;

define method maybe-execute-component
    (component :: <component>, runner :: <test-runner>)
 => (result :: <component-result>)
  let announce-function
    = runner.runner-announce-function;
  if (announce-function)
    announce-function(component)
  end;
  let (subresults, status, reason, seconds, microseconds, bytes)
    = if (execute-component?(component, runner))
        execute-component(component, runner)
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
    (suite :: <suite>, runner :: <test-runner>)
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
          let subresult = maybe-execute-component(component, runner);
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
    (test :: <test>, runner :: <test-runner>)
 => (subresults :: <sequence>, status :: <result-status>, reason :: false-or(<string>),
     seconds :: <integer>, microseconds :: <integer>, bytes :: <integer>)
  let subresults = make(<stretchy-vector>);
  let (seconds, microseconds, bytes) = values(0, 0, 0);
  let (status, reason)
    = dynamic-bind (*check-recording-function* =
                      method (result :: <result>)
                        add!(subresults, result);
                        runner.runner-progress-function(result);
                        result
                      end)
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
    (test :: <test>, runner :: <test-runner>)
 => (list :: <sequence>)
  if (execute-component?(test, runner))
    vector(test);
  else
    #[];
  end if
end method list-component;

define method list-component
    (suite :: <suite>, runner :: <test-runner>)
 => (list :: <sequence>)
  let sublist :: <stretchy-vector> = make(<stretchy-vector>);
  if (execute-component?(suite, runner))
    add!(sublist, suite);
    for (component in suite.suite-components)
      sublist := concatenate!(sublist, list-component(component, runner));
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
  let status = result.result-status;
  let name = result.result-name;
  let reason = result.result-reason;
  select (status)
    $skipped =>
      test-output("Skipped check: %s", name);
    otherwise =>
      test-output("Ran check: %s %s%s\n",
                  name,
                  status-name(status),
                  reason & format-to-string(" [%s]", reason) | "");
  end;
end method full-progress-function;

// TODO(cgay): Default to displaying tests and suites only; not checks.
define variable *default-progress-function* = null-progress-function;

