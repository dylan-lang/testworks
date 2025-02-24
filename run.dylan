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

define constant $progress-none    = #"progress-none";
define constant $progress-minimal = #"progress-minimal"; // Hide assertions unless they fail.
define constant $progress-all     = #"progress-all";     // Display all assertions.
define constant <progress-option>
  = one-of($progress-none, $progress-minimal, $progress-all);

define constant $debug-none    = #"debug-none";
define constant $debug-crashes = #"debug-crashes";
define constant $debug-all     = #"debug-all";
define constant <debug-option>
  = one-of($debug-none, $debug-crashes, $debug-all);

define inline function debug-failures?
    () => (debug-failures? :: <boolean>)
  runner-debug(*runner*) == $debug-all
end function;

define inline function debug?
    () => (debug? :: <boolean>)
  runner-debug(*runner*) ~= $debug-none
end function;

define constant $source-order  = #"source"; // order they appear in the source code.
define constant $lexical-order = #"lexical";
define constant $random-order  = #"random";
define constant $default-order = $source-order;
define constant <order> = one-of($source-order, $lexical-order, $random-order);

define generic sort-components (components :: <sequence>, order :: <order>)
  => (_ :: <sequence>);

define method sort-components (components :: <sequence>, order == $source-order)
 => (_ :: <sequence>)
  components
end;

define method sort-components (components :: <sequence>, order == $lexical-order)
 => (_ :: <sequence>)
  sort(components, test: method (a, b) a.component-name < b.component-name end)
end;

define method sort-components (components :: <sequence>, order == $random-order)
 => (_ :: <sequence>)
  sort(components, test: method (a, b) random(100) < 50 end)
end;

define generic runner-tags     (runner :: <test-runner>) => (tags :: <sequence>);
define generic runner-progress (runner :: <test-runner>) => (progress :: <progress-option>);
define generic runner-debug    (runner :: <test-runner>) => (debug :: <debug-option>);
define generic runner-skip     (runner :: <test-runner>) => (skip :: <sequence> /* of <component> */);
define generic runner-order    (runner :: <test-runner>) => (order :: <order>);
define generic runner-output-stream (runner :: <test-runner>) => (stream :: <stream>);
define generic runner-options  (runner :: <test-runner>) => (options :: <table>);


// A <test-runner> holds options for the test run and collects results.
define open class <test-runner> (<object>)
  // TODO(cgay): <report> = one-of(#"failures", #"crashes", #"none", ...)
  //constant slot runner-report :: <string> = "failures",
  //  init-keyword: report:;
  constant slot runner-tags :: <sequence> = #[],
    init-keyword: tags:;
  constant slot runner-progress :: <progress-option> = $progress-minimal,
    init-keyword: progress:;
  constant slot runner-debug :: <debug-option> = $debug-none,
    init-keyword: debug:;
  constant slot runner-skip :: <sequence> = #[],   // of components
    init-keyword: skip:;
  constant slot runner-order :: <order> = $default-order,
    init-keyword: order:;

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


define function run-tests
    (runner :: <test-runner>, component :: <component>)
 => (component-result :: <component-result>)
  dynamic-bind (*runner* = runner)
    maybe-execute-component(component, runner)
  end;
end function run-tests;


/// Execute component

// If not #f, all suites and tests should be skipped for this reason.
// Normally because a suite setup function failed.
define thread variable *skip-reason* :: false-or(<string>) = #f;

define open generic execute-component?
    (component :: <component>, runner :: <test-runner>)
 => (execute? :: <boolean>);

define method execute-component?
    (component :: <component>, runner :: <test-runner>)
 => (execute? :: <boolean>)
  ~*skip-reason*                // Skipping due to suite setup failure.
    & ~member?(component, runner.runner-skip)
    & tags-match?(runner.runner-tags, component)
end;

define method maybe-execute-component
    (component :: <component>, runner :: <test-runner>)
 => (result :: <component-result>)
  if (runner.runner-progress ~== $progress-none)
    show-progress-start(runner, component);
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
             reason: *skip-reason*,
             seconds: 0,
             microseconds: 0,
             bytes: 0)
      end;
  force-output(*standard-error*);
  force-output(*standard-output*);
  if (runner.runner-progress ~== $progress-none)
    show-progress-done(runner, component, result);
  end;
  result
end method maybe-execute-component;

define method execute-component
    (suite :: <suite>, runner :: <test-runner>)
 => (result :: <component-result>)
  local method run-suite-thunk (suite, thunk, context) => (msg :: false-or(<string>))
          block ()
            thunk();
            #f
          exception (err :: <serious-condition>, test: method (c) ~debug?() end)
            format-to-string("Error in %s for suite %s: %s",
                             context, suite.component-name, err)
          end
        end;
  let subresults :: <stretchy-vector> = make(<stretchy-vector>);
  let seconds :: <integer> = 0;
  let microseconds :: <integer> = 0;
  let bytes :: <integer> = 0;
  let indent = next-indent();
  let error-message = #f;
  block ()
    if (~*skip-reason*)
      // Only run setup (and cleanup, later) if we're not skipping a nested suite due to
      // a previous setup failure.
      error-message := run-suite-thunk(suite, suite.suite-setup-function, "setup");
    end;
    for (component in sort-components(suite.suite-components, runner.runner-order))
      let subresult
        = dynamic-bind (*indent* = indent,
                        *skip-reason* = error-message | *skip-reason*)
            maybe-execute-component(component, runner);
          end;
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
  cleanup
    if (~*skip-reason*)
      let msg = run-suite-thunk(suite, suite.suite-cleanup-function, "cleanup");
      error-message := error-message | msg;
    end;
  end block;
  // TODO: there doesn't seem to be any record-suite equivalent to record-check and
  // record-benchmark. When the setup/cleanup functions fail does the error actually go
  // into the report? Does it appear in the --progress?
  make(component-result-type(suite),
       name: suite.component-name,
       status: if (error-message)
                 $crashed
               else
                 decide-suite-status(subresults)
               end,
       reason: error-message | *skip-reason*,
       subresults: subresults,
       seconds: seconds,
       microseconds: microseconds,
       bytes: bytes)
end method execute-component;

define function decide-suite-status
    (subresults :: <sequence>) => (status :: <result-status>)
  if (empty?(subresults))
    $not-implemented
  else
    let status0 = subresults[0].result-status;
    if (every?(method (subresult)
                 subresult.result-status == status0
               end,
               subresults))
      status0
    elseif (any?(method (r) r.result-status == $crashed end, subresults))
      $crashed
    elseif (every?(result-passing?, subresults))
      $passed
    else
      $failed
    end if
  end if
end function;

define method execute-component
    (test :: <runnable>, runner :: <test-runner>)
 => (result :: <component-result>)
  let subresults = make(<stretchy-vector>);
  let (seconds, microseconds, bytes) = values(0, 0, 0);
  local
    method record-check (result :: <result>)
      add!(subresults, result);
      if (runner.runner-progress ~== $progress-none)
        show-progress-done(runner, #f, result);
      end;
      result
    end,
    method record-benchmark (result :: <result>)
      add!(subresults, result);
      result
    end;
  let (status, reason)
    = dynamic-bind (*check-recording-function* = record-check,
                    *benchmark-recording-function* = record-benchmark,
                    *indent* = next-indent())
        let cond
          = profiling (cpu-time-seconds, cpu-time-microseconds, allocation)
              block ()
                test.test-function();
              exception (err :: <assertion-failure>,
                         test: method (c) ~debug?() end)
                // An assertion failure causes the remainder of a test to be
                // skipped (by jumping here) to prevent cascading failures.
                // The failure has already been recorded so nothing to do.
                #f
              exception (err :: <serious-condition>,
                         test: method (c) ~debug?() end)
                err
              end;
            results
              seconds := cpu-time-seconds;
              microseconds := cpu-time-microseconds;
              bytes := allocation;
            end profiling;
        decide-test-status(test, subresults, cond)
      end dynamic-bind;
  make(component-result-type(test),
       name: test.component-name,
       status: status,
       reason: reason,
       subresults: subresults,
       seconds: seconds,
       microseconds: microseconds,
       bytes: bytes)
end method execute-component;

define function decide-test-status
    (test :: <runnable>, subresults, condition)
 => (status :: <result-status>, reason)
  let benchmark? = ~test.test-requires-assertions?;
  case
    instance?(condition, <serious-condition>)
      => if (test.expected-to-fail?)
           $expected-failure
         else
           values($crashed, format-to-string("%s", condition))
         end;
    empty?(subresults) & ~benchmark?
      => $not-implemented;
    every?(method (result :: <result>) => (passed? :: <boolean>)
             result.result-status == $passed
           end,
           subresults)
      => if (test.expected-to-fail?)
           let reason = format-to-string("%s passed but was expected to fail due to %=",
                                         test.component-type-name,
                                         test.expected-to-fail-reason
                                           | "<no reason supplied>");
           values($unexpected-success, reason)
         else
           $passed
         end if;
    otherwise
      => if (test.expected-to-fail?)
           $expected-failure
         else
           $failed
         end if;
  end case
end function;

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


// Show progress output during the test run. These are only called if
// runner.runner-progress ~== $progress-none.
define generic show-progress-start
    (runner :: <test-runner>, component :: <component>)
 => ();
define generic show-progress-done
    (runner :: <test-runner>, component :: false-or(<component>), result :: <result>)
 => ();

// suites, tests, benchmarks
define method show-progress-start
    (runner :: <test-runner>, component :: <component>) => ()
  test-output("%s%s %=%s%=:\n",
              *indent*,
              capitalize(component.component-type-name),
              $component-name-text-attributes,
              component.component-name,
              $reset-text-attributes);
end method;

// suites, tests, benchmarks
define method show-progress-done
    (runner :: <test-runner>, component :: <component>, result :: <result>) => ()
  let status = result.result-status;
  test-output("%s%s %=%s%= %=%s%=",
              *indent*,
              capitalize(component.component-type-name),
              $component-name-text-attributes,
              component.component-name,
              $reset-text-attributes,
              result-status-to-text-attributes(status),
              status.status-name.as-uppercase,
              $reset-text-attributes);
  let elapsed = result.result-time;
  if (elapsed & status ~== $skipped & status ~== $not-implemented)
    test-output(" in %ss", elapsed);
    let bytes = result.result-bytes;
    if (bytes)
      test-output(" and %s", format-bytes(bytes));
    end;
  end;
  test-output("\n");
end method;

// assertions
define method show-progress-done
    (runner :: <test-runner>, component == #f, result :: <result>) => ()
  if (~result-passing?(result)
        | runner.runner-progress == $progress-all)
    let status = result.result-status;
    test-output("%s%=%s%=: %s\n%s%s%s\n",
                *indent*,
                result-status-to-text-attributes(status),
                status.status-name.as-uppercase,
                $reset-text-attributes,
                result.result-name,
                *indent*,
                $indent-step,
                result.result-reason);
  end;
end method;

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
