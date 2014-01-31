Module:       %testworks
Synopsis:     Implementation of run-test-application
Author:       Andy Armstrong, Shri Amit
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define function parse-args
    (args :: <sequence>) => (parser :: <command-line-parser>)
  let parser = make(<command-line-parser>);
  // TODO(cgay): <choice-option> = never|crashes|failures|none|#f
  // where #f means --debug was used with no option value.
  add-option(parser,
             make(<optional-parameter-option>,
                  names: #("debug"),
                  default: "no",
                  variable: "WHAT",
                  help: "Enter the debugger on failure: NO|crashes|failures"));
  add-option(parser,
             make(<parameter-option>,
                  names: #("progress", "p"),
                  default: "default",
                  variable: "TYPE",
                  help: "Show output as the test run progresses: none|DEFAULT|verbose"));
  add-option(parser,
             make(<parameter-option>,
                  names: #("report"),
                  default: "failures",
                  variable: "TYPE",
                  help: "Final report to generate: none|summary|FAILURES|log|xml|surefire"));
  add-option(parser,
             make(<parameter-option>,
                  names: #("report-file"),
                  variable: "FILE",
                  help: "File in which to store the report."));

  // TODO(cgay): Make test and suite names use one namespace or
  // a hierarchical naming scheme these four options are reduced
  // to tests/suites specified as regular arguments plus --skip.
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
             make(<parameter-option>,
                  names: #("list", "l"),
                  default: #f,
                  variable: "WHAT",
                  help: "List components: suites|tests|benchmarks"));
  add-option(parser,
             make(<repeated-parameter-option>,
                  names: #("tag", "t"),
                  help: "Only run tests matching this tag. If tag is prefixed "
                    "with '-', the test will only run if it does NOT have the tag."
                    " May be repeated."));
  block ()
    parse-command-line(parser, args, description: "Run tests suites.");
  exception (ex :: <usage-error>)
    exit-application(2);
  end;
  parser
end function parse-args;

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

define method find-component
    (suite-name :: false-or(<string>), test-name :: false-or(<string>))
 => (test :: <component>)
  let suite = if (suite-name)
                find-suite(suite-name)
                  | usage-error("Suite not found: %s", suite-name);
              end;
  let test = if (test-name)
               find-test(test-name, search-suite: suite | root-suite())
                 | usage-error("Test not found: %s", test-name);
             end;
  test | suite
end method find-component;

define method find-components
    (suite-names :: <sequence>, test-names :: <sequence>)
 => (tests :: <stretchy-vector>)
  let components = make(<stretchy-vector>);
  for (name in suite-names | #[])
    add!(components, find-component(name, #f));
  end;
  for (name in test-names | #[])
    add!(components, find-component(#f, name));
  end;
  values(components)
end method find-components;

// Create a <test-runner> from command-line options.
define function make-runner-from-command-line
    (parent :: <component>, parser :: <command-line-parser>)
 => (start-suite :: <component>, runner :: <test-runner>, report-function :: <function>)
  // TODO(cgay): Use init-keywords rather than setters so we can make <test-runner>
  // immutable.
  let debug = get-option-value(parser, "debug");
  let report = get-option-value(parser, "report");
  let progress = get-option-value(parser, "progress");
  let sprogress = as(<symbol>, progress);
  let report-function = element($report-functions, report, default: #f)
    | usage-error("Invalid --report option: %s", report);
  if (~member?(sprogress, list($none, $default, $verbose)))
    usage-error("Invalid --progress option: %s", progress);
  end;
  let runner = make(<test-runner>,
                    debug?: select (debug by \=)
                              #f, "no" => #f;
                              "crashes" => #"crashes";
                              #t, "failures" => #t;
                              otherwise =>
                                usage-error("Invalid --debug option: %s", debug);
                            end select,
                    skip: find-components(get-option-value(parser, "skip-suite"),
                                          get-option-value(parser, "skip-test")),
                    report: report,
                    progress: if (sprogress = $none) #f else sprogress end,
                    tags: parse-tags(get-option-value(parser, "tag")));
  let components = find-components(get-option-value(parser, "suite"),
                                   get-option-value(parser, "test"));
  let start-suite = select (components.size)
                      0 => parent;
                      1 => components[0];
                      otherwise =>
                        make(<suite>,
                             name: "Specified Components",
                             description: "arguments to -suite and -test",
                             components: components);
                    end select;
  values(start-suite, runner, report-function)
end function make-runner-from-command-line;


// Run a test or suite.  Uses a test runner created based on
// command-line arguments.  Use run-tests instead if you want to
// create the test-runner yourself.  Returns a <result> if any suites
// or tests were executed; otherwise #f.
define method run-test-application
    (parent :: <component>) => (result :: false-or(<result>))
  let parser = parse-args(application-arguments());
  let (start-suite, runner, report-function)
    = block ()
        make-runner-from-command-line(parent, parser)
      exception (ex :: <usage-error>)
        format(*standard-error*, "%s\n", condition-to-string(ex));
        // TODO(cgay): The caller should decide whether to exit the
        // application.
        exit-application(2);
      end;

  let list-opt = get-option-value(parser, "list");
  if (list-opt)
    list-components(runner, start-suite, list-opt);
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
  if (~member?(what, #["suites", "tests", "benchmarks"],
               test: string-equal?))
    format(*standard-error*,
           "Invalid --list option, %=.  Value must be one of "
               "'suites', 'tests', or 'benchmarks'.", what);
    exit-application(2);
  end;
  let components = list-component(start-suite, runner);
  for (component :: <component> in components)
    if (select (component.object-class)
          // order matters.  benchmarks are tests.
          <suite> => what = "suites";
          <benchmark> => what = "benchmarks";
          <test> => what = "tests";
        end)
      format(*standard-output*, "%s %s%s\n",
             component.component-type-name, component.component-name,
             if (instance?(component, <test>) & ~empty?(component.test-tags))
               format-to-string(" (tags: %s)",
                                join(component.test-tags, ", ", key: tag-name))
             else
               ""
             end)
    end;
  end;
end function list-components;
