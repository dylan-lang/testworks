Module:       %testworks
Summary:      Test run execution logic.
Author:       Andrew Armstrong, James Kirsch
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

// Bound to the currently executing component, both during normal
// test/benchmark execution and while setup/teardown code is running.
define thread variable *component* :: false-or(<component>) = #f;

// Return a temporary directory unique to the current test or benchmark. The
// directory is created the first time this is called for a given test.
// The directory is _test/<user>-<yyyymmdd-hhmmss>/<full-test-name>/, relative
// to ${DYLAN}/, if defined, or fs/working-directory() otherwise.
define function test-temp-directory () => (d :: false-or(<directory-locator>))
  if (instance?(*component*, <runnable>))
    let dylan = os/environment-variable("DYLAN");
    let base = if (dylan)
                 as(<directory-locator>, dylan)
               else
                 fs/working-directory()
               end;
    let uniquifier
      = format-to-string("%s-%s", os/login-name() | "unknown",
                         date/format("%Y%m%d-%H%M%S", date/now()));
    let test-directory
      = subdirectory-locator(base, "_test", uniquifier, full-component-name(*component*));
    fs/ensure-directories-exist(test-directory);
    test-directory
  end
end function;

define inline function debug-failures?
    () => (debug-failures? :: <boolean>)
  debug-runner?(*runner*) == #t
end;

define inline function debug?
    () => (debug? :: <boolean>)
  debug-runner?(*runner*) ~= #f
end;

// For tests to do debugging output.
// TODO(cgay): Collect this and stdio into a log file per test run
// or per test.  The Surefire report has a place for stdout, too.
define method test-output
    (format-string :: <string>, #rest format-args) => ()
  let stream = runner-output-stream(*runner*);
  with-stream-locked (stream)
    apply(format, stream, format-string, format-args);
    force-output(stream);
  end;
end method test-output;

// A <test-runner> holds options for the test run and collects results.
define open class <test-runner> (<object>)
  // TODO(cgay): <report> = one-of(#"failures", #"crashes", #"none", ...)
  //constant slot runner-report :: <string> = "failures",
  //  init-keyword: report:;
  constant slot runner-tags :: <sequence> = #[],
    init-keyword: tags:;
  constant slot runner-progress :: one-of(#f, $default, $verbose),
    init-keyword: progress:;
  constant slot debug-runner? = #f,
    init-keyword: debug?:;
  constant slot runner-skip :: <sequence> = #[],   // of components
    init-keyword: skip:;

  // The stream on which output is done.  Note that this may be bound
  // to different streams during the test run and when the report is
  // generated.  e.g., to output the report to a file.
  constant slot runner-output-stream :: <stream>
      // TODO(cgay): if a non-colorizing stream is used here garbage
      // text attribute objects are displayed on the stream.
      = colorize-stream(*standard-output*),
    init-keyword: output-stream:;

  // Options are from positional args passed as key=val on the
  // command-line and can be used to pass external context information
  // to tests. For example, test data directory pathname.
  constant slot runner-options :: <string-table> = make(<string-table>),
    init-keyword: options:;
end class <test-runner>;


// The active test run object.
define thread variable *runner* :: false-or(<test-runner>) = #f;


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

define function run-tests
    (runner :: <test-runner>, component :: <component>)
 => (component-result :: <component-result>)
  dynamic-bind (*runner* = runner)
    maybe-execute-component(component, runner)
  end;
end function run-tests;


/// Execute component

define open generic execute-component?
    (component :: <component>, runner :: <test-runner>)
 => (execute? :: <boolean>);

define method execute-component?
    (component :: <component>, runner :: <test-runner>)
 => (execute? :: <boolean>)
  ~member?(component, runner.runner-skip) & tags-match?(runner.runner-tags, component)
end;

define method maybe-execute-component
    (component :: <component>, runner :: <test-runner>)
 => (result :: <component-result>)
  if (runner.runner-progress)
    show-progress(runner, component, #f);
  end;
  let result
    = if (execute-component?(component, runner))
        dynamic-bind (*component* = component)
          execute-component(component, runner)
        end
      else
        make(component-result-type(component),
             name: component.component-name,
             status: $skipped,
             reason: #f,
             seconds: 0,
             microseconds: 0,
             bytes: 0)
      end;
  force-output(*standard-error*);
  force-output(*standard-output*);
  if (runner.runner-progress)
    show-progress(runner, component, result);
  end;
  result
end method maybe-execute-component;

define method execute-component
    (suite :: <suite>, runner :: <test-runner>)
 => (result :: <component-result>)
  let subresults :: <stretchy-vector> = make(<stretchy-vector>);
  let seconds :: <integer> = 0;
  let microseconds :: <integer> = 0;
  let bytes :: <integer> = 0;
  let status
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
          empty?(subresults)
            => $not-implemented;
          every?(method (subresult)
                   let status = subresult.result-status;
                   status = $passed | status = $skipped | status = $expected-failure
                 end,
                 subresults)
            => $passed;
          otherwise
            => $failed;
        end case
      cleanup
        suite.suite-cleanup-function();
      end block;
  make(component-result-type(suite),
       name: suite.component-name,
       status: status,
       reason: #f,
       subresults: subresults,
       seconds: seconds,
       microseconds: microseconds,
       bytes: bytes)
end method execute-component;

define method execute-component
    (test :: <runnable>, runner :: <test-runner>)
 => (result :: <component-result>)
  let subresults = make(<stretchy-vector>);
  let (seconds, microseconds, bytes) = values(0, 0, 0);
  let (status, reason)
    = dynamic-bind (*check-recording-function* =
                      method (result :: <result>)
                        add!(subresults, result);
                        if (*runner*.runner-progress)
                          show-progress(*runner*, #f, result);
                        end;
                        result
                      end,
                    *benchmark-recording-function* =
                      method (result :: <result>)
                        add!(subresults, result);
                        result
                      end)
        let cond
          = profiling (cpu-time-seconds, cpu-time-microseconds, allocation)
              maybe-trap-errors(test.test-function());
            results
              seconds := cpu-time-seconds;
              microseconds := cpu-time-microseconds;
              bytes := allocation;
            end profiling;
        case
          instance?(cond, <serious-condition>)
            => values($crashed, format-to-string("%s", cond));
          empty?(subresults) & test.test-requires-assertions?
            => $not-implemented;
          every?(method (result :: <unit-result>) => (passed? :: <boolean>)
                   result.result-status == $passed
                 end,
                 subresults)
            => if (test.expected-failure?)
                 $unexpected-success
               else
                 $passed
               end if;
          otherwise
            => if (test.expected-failure?)
                 $expected-failure
               else
                 $failed
               end if;
        end
      end;
  make(component-result-type(test),
       name: test.component-name,
       status: status,
       reason: reason,
       subresults: subresults,
       seconds: seconds,
       microseconds: microseconds,
       bytes: bytes)
end method execute-component;

define method list-component
    (test :: <runnable>, runner :: <test-runner>)
 => (list :: <sequence>)
  if (execute-component?(test, runner))
    vector(test)
  else
    #[]
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
    

// TODO(cgay): Use indentation to show suite nesting.

// Show some output during the test run.  For each component this is
// called both before and after it has been run.  If before, result
// will be #f.  This function is only called if runner.runner-progress
// ~= #f.
define generic show-progress
    (runner :: <test-runner>,
     component :: false-or(<component>),
     result :: false-or(<result>))
 => ();

// Default does nothing.
define method show-progress
    (runner :: <test-runner>,
     component :: false-or(<component>),
     result :: false-or(<result>))
 => ()
end;

define method show-progress
    (runner :: <test-runner>, suite :: <suite>, result :: false-or(<result>))
 => ()
  if (result)
    let result-status = result.result-status;
    test-output("Completed suite %=%s%=: %=%s%= in %ss\n",
                $component-name-text-attributes,
                suite.component-name,
                $reset-text-attributes,
                result-status-to-text-attributes(result-status),
                result-status.status-name.as-uppercase,
                $reset-text-attributes,
                result.result-time)
  else
    test-output("Running suite %=%s%=:\n",
                $component-name-text-attributes,
                suite.component-name,
                $reset-text-attributes);
  end;
end method show-progress;

// Tests and benchmarks are displayed before and after being run.
define method show-progress
    (runner :: <test-runner>, test :: <runnable>, result :: false-or(<result>))
 => ()
  let verbose? = runner.runner-progress = $verbose;
  if (result)
    let reason = result.result-reason;
    let result-status = result.result-status;
    test-output("%s%=%s%= in %ss and %s\n",
                if (verbose?)
                  format-to-string("  %s ", test.component-type-name)
                else
                  " "
                end,
                result-status-to-text-attributes(result-status),
                result-status.status-name.as-uppercase,
                $reset-text-attributes,
                result.result-time,
                format-bytes(result.result-bytes));
    reason & test-output("    %s\n", reason);
  else
    test-output("Running %s %=%s%=:%s",
                test.component-type-name,
                $component-name-text-attributes,
                test.component-name,
                $reset-text-attributes,
                verbose? & "\n" | "");
  end;
end method show-progress;

// Assertions are only displayed when they fail or the verbose option
// is set.
define method show-progress
    (runner :: <test-runner>, component == #f, result :: <result>)
 => ()
  let status = result.result-status;
  let reason = result.result-reason;
  if (runner.runner-progress = $verbose)
    test-output("  %=%s%=: %s%s\n",
                result-status-to-text-attributes(status),
                status.status-name.as-uppercase,
                $reset-text-attributes,
                result.result-name,
                reason & concatenate(" [", reason, "]") | "");
  elseif (reason)
    test-output("\n  %s: [%s]\n  ", result.result-name, reason);
  end;
end method show-progress;

define function test-option
    (name :: <string>, #key default = unsupplied())
 => (option-value :: <string>);
  let option-value
    = element(*runner*.runner-options, name, default: unfound());
  if (found?(option-value))
    option-value
  elseif (supplied?(default))
    default
  else
    error("No value for test option %s was supplied", name)
  end if
end function;
