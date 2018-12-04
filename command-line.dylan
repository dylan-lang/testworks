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

define table $report-functions :: <string-table> = {
    "log"      => log-report-function,
    "none"     => null-report-function,
    "summary"  => summary-report-function,
    "failures" => failures-report-function,
    "surefire" => surefire-report-function,
    "xml"      => xml-report-function
};

define function parse-args
    (args :: <sequence>) => (parser :: <command-line-parser>)
  let parser = make(<command-line-parser>);
  add-option(parser,
             // TODO: When <choice-option> supports having an optional
             // value then this can be made optional where no value
             // means "failures".
             make(<choice-option>,
                  names: #("debug"),
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
                  names: #("report"),
                  choices: key-sequence($report-functions),
                  default: "failures",
                  variable: "TYPE",
                  help: "Final report to generate: none|summary|FAILURES|log|xml|surefire"));
  add-option(parser,
             make(<parameter-option>,
                  names: #("report-file"),
                  variable: "FILE",
                  help: "File in which to store the report."));

  // TODO(cgay): Replace these 4 options with --skip and --match (or
  // --include?).  Because Dylan is a Lisp-1 suites, tests, and
  // benchmarks share a common namespace and --skip and --match will
  // be unambiguous.
  add-option(parser,
             make(<repeated-parameter-option>,
                  names: #("suite"),
                  help: "Run (or list) only these named suites. May be repeated."));
  add-option(parser,
             make(<repeated-parameter-option>,
                  names: #("test"),
                  help: "Run (or list) only these named tests. May be repeated."));
  add-option(parser,
             make(<repeated-parameter-option>,
                  names: #("skip-suite"),
                  variable: "SUITE",
                  help: "Skip these named suites. May be repeated."));
  add-option(parser,
             make(<repeated-parameter-option>,
                  names: #("skip-test"),
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
  block ()
    parse-command-line(parser, args, description: "Run tests suites.");
  exception (ex :: <usage-error>)
    exit-application(2);
  end;
  parser
end function parse-args;

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
                    tags: parse-tags(get-option-value(parser, "tag")));

  // TODO(cgay): runner-options are unused. Delete? What were they for?
  for (option in parser.positional-options)
    let split = find-key(option, curry(\==, '='));
    if (split)
      let key = copy-sequence(option, end: split);
      let value = copy-sequence(option, start: split + 1);
      runner.runner-options[key] := value;
    end if;
  end for;

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


// Run or list tests as filtered by the command-line options. Without
// any arguments, defaults to running all tests in the library. The
// `components` argument may be provided for backward compatibility
// and must be a single test, benchmark, or test suite. Returns a
// `<result>` if any tests are executed; otherwise `#f`.
//
// TODO(cgay): update callers to pass no args, then remove `components` arg.
define method run-test-application
    (#rest components) => (result :: false-or(<result>))
  if (components.size > 1)
    usage-error("run-test-application takes 0 or 1 test components as argument,"
                  " (got %d)", components.size);
  end;
  let top = if (components.size = 0)
              // Make a suite named after the library, containing all test components.
              let app = locator-base(as(<file-locator>, application-name()));
              make(<suite>,
                   name: app,
                   components: find-root-components())
            else
              components[0]
            end;
  let parser = parse-args(application-arguments());
  let (start-suite, runner, report-function)
    = block ()
        make-runner-from-command-line(top, parser)
      exception (ex :: <usage-error>)
        format(*standard-error*, "%s\n", condition-to-string(ex));
        // TODO(cgay): The caller should decide whether to exit the
        // application.
        exit-application(2);
      end;

  let list-opt = get-option-value(parser, "list");
  if (list-opt)
    list-components(runner, start-suite, list-opt.as-lowercase);
    #f
  else
    // Run the appropriate test or suite
    let pathname = get-option-value(parser, "report-file");
    let result = run-tests(runner, start-suite);
    if (pathname)
      with-open-file(stream = pathname,
                     direction: #"output",
                     if-exists: #"overwrite")
        report-function(result, stream);
      end;
    else
      report-function(result, *standard-output*);
    end;
    result
  end if
end method run-test-application;

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
