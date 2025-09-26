Module:       %testworks
Synopsis:     Testworks command-line parsing and top-level entry points
Author:       Andy Armstrong, Shri Amit
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND


define constant $list-option-values = #["all", "suites", "tests", "benchmarks"];

// TODO(cgay): This seems to mix two concerns: what I want to output to the
// screen during and after the test run, and what I want stored in a file for
// later analysis. I think the --report option should apply to the latter and
// --verbose (or --output) should apply to the former.
define table $report-functions :: <string-table>
  = {
     "none"     => print-null-report,
     "summary"  => print-summary-report,
     "failures" => print-failures-report,
     "full"     => print-full-report,
     "surefire" => print-surefire-report,
     "xml"      => print-xml-report,
     "json"     => print-json-report,
};

define function parse-args
    (args :: <sequence>) => (parser :: <command-line-parser>)
  let parser = make(<command-line-parser>,
                    help: "Run tests.");
  add-option(parser,
             make(<choice-option>,
                  names: "debug",
                  choices: #("none", "crashes", "failures", "all"),
                  default: "none",
                  variable: "WHAT",
                  help: "Enter the debugger? none, crashes, failures, or all."
                    " [%default%]"));
  add-option(parser,
             make(<choice-option>,
                  names: #("progress", "p"),
                  choices: #("none", "minimal", "all"),
                  default: "minimal",
                  variable: "TYPE",
                  help: "Show test names and results as the test run progresses? None, minimal"
                    " (no assertions unless they fail), or all. [%default%]"));
  add-option(parser,
             make(<choice-option>,
                  names: "report",
                  choices: key-sequence($report-functions),
                  default: "failures",
                  variable: "TYPE",
                  help: format-to-string("Final report to generate: %s [%%default%%]",
                                         join(sort(key-sequence($report-functions)), ", ",
                                              conjunction: ", or "))));
  add-option(parser,
             make(<choice-option>,
                  names: "order",
                  choices: map(method (key)
                                 as-lowercase(as(<string>, key))
                               end,
                               list($source-order, $lexical-order, $random-order)),
                  default: as-lowercase(as(<string>, $default-order)),
                  help: "Order in which to run tests. Note that when suites are being used"
                    " the suite is ordered with other tests/suites at the same level and"
                    " then when that suite runs its components are ordered separately."
                    " [%default%]"));
  // TODO(cgay): I adopted the convention of using ./_test in test-temp-directory()
  // and we could use it here as the default location of the report file.
  add-option(parser,
             make(<parameter-option>,
                  names: "report-file",
                  variable: "FILE",
                  help: "File in which to store the report."));
  add-option(parser,
             make(<repeated-parameter-option>,
                  names: "load",
                  variable: "FILE",
                  help: "Load the given shared library file before searching for"
                    " test suites. May be repeated."));

  add-option(parser,
             make(<repeated-parameter-option>,
                  names: "run",
                  variable: "TEST",
                  help: "Run only these named suites or tests. May be repeated."));
  add-option(parser,
             make(<repeated-parameter-option>,
                  names: "skip",
                  variable: "TEST",
                  help: "Skip these named suites or tests. May be repeated."));
  add-option(parser,
             make(<choice-option>,
                  names: #("list", "l"),
                  choices: $list-option-values,
                  default: #f,
                  variable: "WHAT",
                  help: format-to-string("List components: %s",
                                         join($list-option-values, ", "))));
  add-option(parser,
             make(<repeated-parameter-option>,
                  names: #("tag", "t"),
                  help: "Only run tests matching this tag. If tag is prefixed"
                    " with '-', the test will only run if it does NOT have the tag."
                    " May be repeated. Ex: --tag=-slow,-benchmark means don't run"
                    " benchmarks or tests tagged as slow."));
  add-option(parser,
             make(<keyed-option>,
                  names: #("options", "O"),
                  default: make(<string-table>),
                  help: "Key/value pairs that may be used to pass context to tests."));
  parse-command-line(parser, args);
  parser
end function parse-args;

define function do-loads
    (library-files :: <collection>)
  for (file in library-files)
    format(*standard-output*, "Loading library %s\n", file);
    force-output(*standard-output*);
    os/load-library(file);
  end for;
end function;

// Create a `<test-runner>` from command-line options.
define function make-runner-from-command-line
    (top :: <component>, parser :: <command-line-parser>)
 => (runner :: <test-runner>, reporter :: <function>)
  let components
    = compute-components(top,
                         parse-tags(get-option-value(parser, "tag")),
                         get-option-value(parser, "run"),
                         get-option-value(parser, "skip"));
  let debug = select (as-lowercase(get-option-value(parser, "debug")) by \=)
                "none"     => $debug-none;
                "crashes"  => $debug-crashes;
                "failures" => $debug-failures;
                "all"      => $debug-all;
              end;
  let progress = select (as-lowercase(get-option-value(parser, "progress")) by \=)
                   "none"    => $progress-none;
                   "minimal" => $progress-minimal;
                   "all"     => $progress-all;
                 end;
  let report = get-option-value(parser, "report");
  let reporter = element($report-functions, report, default: #f)
    | usage-error("unrecognized --report type: %s", report);
  let runner = make(<test-runner>,
                    components: components,
                    debug: debug,
                    progress: progress,
                    order: as(<symbol>, get-option-value(parser, "order")),
                    options: get-option-value(parser, "options"));
  values(runner, reporter)
end function make-runner-from-command-line;

// Figure out the exact set of components to run based on command-line options.  Needs to
// figure out the suites to run when --test is provided so that the setup/cleanup will be
// executed.  The universe of components to consider is the subtree of components defined
// by `top`.
define function compute-components
    (top :: <suite>, tags, run, skip)
 => (components)
  local method find-component (name :: <string>) => (component)
          block (return)
            do-components(top, method (c)
                                 if (c.component-name = name)
                                   return(c)
                                 end;
                               end);
          end | usage-error("not found: %=", name);
        end;
  if (run.empty? & skip.empty?)
    $components
  else
    let components = make(<set>);
    if (run.empty?)
      do(curry(add!, components), $components);
    else
      for (name in run)
        let comp = find-component(name);
        do-components(comp, curry(add!, components));
        // Gotta run the ancestor suites' setup/cleanup.
        do-ancestors(comp, curry(add!, components));
      end;
    end;
    for (name in skip)
      let comp = find-component(name);
      do-components(comp, curry(remove!, components));
      // The remove! above could leave a suite in the `components`
      // list even if it has no child components that will be run...
      do-ancestors(comp, method (c)
                           if (instance?(c, <suite>)
                                 & ~any?(rcurry(member?, components),
                                         c.suite-components))
                             remove!(components, c);
                           end
                         end);
    end for;
    if (components.empty?)
      usage-error("The given options did not specify any tests.");
    end;
    // Not clear why choose requires a <sequence> and not a <collection>...
    as(<set>, choose(curry(tags-match?, tags), key-sequence(components)))
  end
end function;

// Run or list tests as filtered by the command-line options and then call
// exit-application. Without any arguments, defaults to running all tests in
// the library. The `components` argument may be provided for backward
// compatibility and must be a single test, benchmark, or test suite.
//
// TODO(cgay): update callers to pass no args, then remove `components` arg.
define function run-test-application
    (#rest components) => ()
  let test-runner = #f;
  block ()
    if (components.size > 1)
      format(*standard-error*,
             "run-test-application takes 0 or 1 test components as"
               " arguments, (got %d)", components.size);
      exit-application(2);
    end;
    let parser = parse-args(application-arguments());
    let (suite, runner, reporter) = process-command-line(parser, components);
    test-runner := runner;
    let status = run-or-list-tests(suite, runner, reporter, parser);
    exit-application(status);
  exception (err :: <abort-command-error>)
    format(*standard-error*, "%s", err);
    exit-application(err.exit-status);
  exception (error :: <error>,
             test: method (cond)
                     test-runner & (runner-debug(test-runner) == $debug-none)
                   end)
    format(*standard-error*, "Error: %s", error);
    exit-application(1);
  end;
end function;

define function process-command-line
    (parser :: <command-line-parser>, components)
 => (suite :: <suite>, runner :: <test-runner>, reporter :: <function>)
  assert(components.size <= 1);
  // Load more tests, if requested. Tests share a global namespace so this will
  // signal on duplicate names.
  let to-load = get-option-value(parser, "load");
  if (to-load.size > 0)
    if (~empty?(components))
      // We can remove this check (and the components parameter) after all
      // libraries are updated to pass no args to run-test-application.
      error("passing a component to run-test-application and using --load"
              " at the same time is pointless since only the passed component"
              " will run.");
    end;
    do-loads(to-load);
  end;
  let top
    = if (~components.empty? & instance?(components[0], <suite>))
        components[0]
      else
        // Note that it is an error if this name clashes with an existing suite.
        let suite-name = "testworks-autogenerated-top-level-suite";
        if (components.empty?)
          make-suite(suite-name, find-root-components())
        else
          make-suite(suite-name, list(components[0]))
        end
      end;
  let (runner, reporter) = make-runner-from-command-line(top, parser);
  values(top, runner, reporter)
end function;

define function run-or-list-tests
    (start-suite, runner, report-function, parser)
 => (exit-status :: <integer>)
  let list-opt = get-option-value(parser, "list");
  if (list-opt)
    list-components(runner, start-suite, list-opt.as-lowercase);
    0
  else
    // Run the requested tests.
    let pathname = get-option-value(parser, "report-file");
    let result = run-tests(runner, start-suite);
    if (pathname)
      fs/with-open-file(stream = pathname, direction: #"output", if-exists: #"replace")
        report-function(result, stream);
      end;
      // Always display the summary on the console.
      print-summary-report(result, *standard-output*);
    else
      report-function(result, *standard-output*);
    end;
    if (*output-captured?*)
      // TODO: be more specific about where the files are after fixing various problems
      // with test-temp-directory, i.e., store one _test subdir per runner.
      test-output("NOTE: Some test output was captured. See files named %s "
                    "in the _test directory.\n",
                  $captured-output-filename);
    end;
    if (result.result-status == $passed) 0 else 1 end
  end
end function;

define function list-components
    (runner :: <test-runner>, start-suite :: <component>, what :: <string>)
  if (~member?(what, $list-option-values, test: \=))
    format(*standard-error*,
           "Invalid --list option, %=.  Value must be one of %s.\n",
           what, join($list-option-values, ", ", conjunction: ", or "));
    exit-application(2);
  end;
  let components = list-component(start-suite, runner);
  for (component :: <component> in components)
    if (what = "all" | select (component.object-class)
                         <suite> => what = "suites";
                         <test> => what = "tests";
                         <benchmark> => what = "benchmarks";
                       end)
      format(*standard-output*, "%s %s%s\n",
             component.component-type-name, component.component-name,
             if (instance?(component, <runnable>) & ~empty?(component.test-tags))
               format-to-string(" (tags: %s)",
                                join(component.test-tags, ", ", key: tag-name))
             else
               ""
             end)
    end;
  end;
end function list-components;
