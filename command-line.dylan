Module:       %testworks
Synopsis:     Testworks command-line parsing and top-level entry points
Author:       Andy Armstrong, Shri Amit
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND


define constant $list-option-values = #["all", "suites", "tests", "benchmarks"];

// types of progress to display
define constant $none = #"none";
define constant $default = #"default";
define constant $verbose = #"verbose";

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
             // TODO: When <choice-option> supports having an optional
             // value then this can be made optional where no value
             // means "failures".
             make(<choice-option>,
                  names: "debug",
                  choices: #("no", "crashes", "failures"),
                  default: "no",
                  variable: "WHAT",
                  help: "Enter the debugger on failure: NO|crashes|failures"));
  add-option(parser,
             make(<choice-option>,
                  names: #("progress", "p"),
                  choices: #("none", "default", "verbose"),
                  default: "default",
                  variable: "TYPE",
                  help: "Show output as the test run progresses: none|DEFAULT|verbose"));
  add-option(parser,
             make(<choice-option>,
                  names: "report",
                  choices: key-sequence($report-functions),
                  default: "failures",
                  variable: "TYPE",
                  help: format-to-string("Final report to generate: %s",
                                         join(sort(key-sequence($report-functions)), "|"))));
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
                    " then when that suite runs its components are ordered separately."));

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

  // TODO(cgay): Replace these 4 options with --skip and --match (or
  // --include?).  Because Dylan is a Lisp-1 suites, tests, and
  // benchmarks share a common namespace and --skip and --match will
  // be unambiguous.
  add-option(parser,
             make(<repeated-parameter-option>,
                  names: "suite",
                  help: "Run (or list) only these named suites. May be repeated."));
  add-option(parser,
             make(<repeated-parameter-option>,
                  names: "test",
                  help: "Run (or list) only these named tests. May be repeated."));
  add-option(parser,
             make(<repeated-parameter-option>,
                  names: "skip-suite",
                  variable: "SUITE",
                  help: "Skip these named suites. May be repeated."));
  add-option(parser,
             make(<repeated-parameter-option>,
                  names: "skip-test",
                  variable: "TEST",
                  help: "Skip these named tests. May be repeated."));
  add-option(parser,
             make(<choice-option>,
                  names: #("list", "l"),
                  choices: $list-option-values,
                  default: #f,
                  variable: "WHAT",
                  help: format-to-string("List components: %s",
                                         join($list-option-values, "|"))));
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
 => (c :: <component>, runner :: <test-runner>, report-function :: <function>)
  // TODO(cgay): Use init-keywords rather than setters so we can make <test-runner>
  //   immutable.
  // TODO(cgay): The runner should either contain the top-level components to run
  //   AND the components to skip, or neither one.

  local method find-component (name :: <string>) => (component)
          let i = find-key($components, method (c)
                                          c.component-name = name
                                        end);
          (i & $components[i]) | usage-error("test component not found: %=", name);
        end;
  let debug = get-option-value(parser, "debug");
  let report = get-option-value(parser, "report");
  let progress = as(<symbol>, get-option-value(parser, "progress"));
  let report-function = element($report-functions, report);
  let runner = make(<test-runner>,
                    debug?: select (debug by \=)
                              "no" => #f;
                              "crashes" => #"crashes";
                              "failures" => #t;
                            end select,
                    skip: concatenate(map(find-component,
                                          get-option-value(parser, "skip-suite")),
                                      map(find-component,
                                          get-option-value(parser, "skip-test"))),
                    report: report,
                    progress: if (progress = $none) #f else progress end,
                    tags: parse-tags(get-option-value(parser, "tag")),
                    order: as(<symbol>, get-option-value(parser, "order")),
                    options: get-option-value(parser, "options"));

  // TODO(cgay): So...the --suite and --test options may specify
  // something disjoint from `top`. This begs the question why do we
  // ever bother passing a component to run-test-application?  Why not
  // just assume all tests should be run and then filter tests in/out?
  // If it was so that run-test-application could be used in the REPL,
  // we should just make all test components callable instead, and
  // provide a run-all-tests entry point without need of command-line
  // args.
  let components = concatenate(map(find-component,
                                   get-option-value(parser, "suite")),
                               map(find-component,
                                   get-option-value(parser, "test")));
  let top = select (components.size)
              0 => top;
              1 => components[0];
              otherwise =>
                // Multiple suites or tests specified.
                make(<suite>,
                     name: join(components, ", ", key: component-name),
                     components: components);
            end;
  values(top, runner, report-function)
end function make-runner-from-command-line;


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
                     test-runner & ~test-runner.debug-runner?
                   end)
    format(*standard-error*, "Error: %s", error);
    exit-application(1);
  end;
end function;

define function process-command-line
    (parser :: <command-line-parser>, components)
 => (suite :: <component>, runner :: <test-runner>, reporter :: <function>)
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

  let suite
    = if (empty?(components))
        make(<suite>,
             name: locator-base(as(<file-locator>, application-name())),
             components: find-root-components())
      else
        components[0]
      end;
  make-runner-from-command-line(suite, parser)
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
