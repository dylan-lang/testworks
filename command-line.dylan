Module:       testworks
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
                  help: "Enter the debugger on failure: no|crashes|failures"));
  add-option(parser,
             make(<flag-option>,
                  names: #("progress"),
                  negative-names: #("noprogress"),
                  default: #f,
                  help: "Show progress as tests are run."));
  add-option(parser,
             make(<flag-option>,
                  names: #("verbose"),
                  negative-names: #("quiet"),
                  default: #t,
                  help: "Adjust output verbosity."));
  add-option(parser,
             make(<flag-option>,
                  names: #("profile"),
                  default: #f,
                  help: "Turn on code profiling."));
  add-option(parser,
             make(<parameter-option>,
                  names: #("report"),
                  default: "failures",
                  help: "Type of final report to generate: "
                    "none|full|failures|summary|log|xml"));
  // TODO(cgay): Make test and suite names use one namespace or
  // a hierarchical naming scheme these four options are reduced
  // to tests/suites specified as regular arguments plus --ignore. 
  add-option(parser,
             make(<repeated-parameter-option>,
                  names: #("suite"),
                  help: "Run only these named suites.  May be "
                    "used multiple times."));
  add-option(parser,
             make(<repeated-parameter-option>,
                  names: #("test"),
                  help: "Run only these named tests.  May be "
                    "used multiple times."));
  add-option(parser,
             make(<repeated-parameter-option>,
                  names: #("ignore-suite"),
                  help: "Ignore these named suites.  May be "
                    "used multiple times."));
  add-option(parser,
             make(<repeated-parameter-option>,
                  names: #("ignore-test"),
                  help: "Ignore these named tests.  May be "
                    "used multiple times."));
  block ()
    parse-command-line(parser, args, description: "Run tests suites.");
  exception (ex :: <usage-error>)
    exit-application(2);
  end;
  parser
end function parse-args;


define table $report-functions :: <string-table> = {
    "none"     => null-report-function,
    "full"     => full-report-function,
    "summary"  => summary-report-function,
    "failures" => failures-report-function,
    "log"      => log-report-function,
    "xml"      => xml-report-function
    };

// Encapsulates the components to be ignored

define class <perform-criteria> (<perform-options>)
  slot perform-ignore :: <stretchy-vector>, 
    init-keyword: ignore:;
end class <perform-criteria>;

define method execute-component? 
    (component :: <component>, options :: <perform-criteria>) 
 => (answer :: <boolean>)
  next-method()
     & ~member?(component, options.perform-ignore)
end method execute-component?;

define method find-component
    (suite-name :: false-or(<string>), test-name :: false-or(<string>))
 => (test :: <component>)
  let suite
    = if (suite-name)
        find-suite(suite-name)
          | usage-error("Suite not found: %s", suite-name);
      end;
  let test
    = if (test-name)
        find-test(test-name, search-suite: suite | root-suite())
          | usage-error("Test not found: %s", test-name);
      end;
  test | suite;
end method find-component;

define method find-component
    (suite-names :: false-or(<sequence>), test-names :: false-or(<sequence>))
 => (tests :: <sequence>)
  let tests = make(<stretchy-vector>);
  suite-names 
    & for (name in suite-names)
        add!(tests, find-component(name, #f));
      end for;
  test-names 
    & for (name in test-names)
        add!(tests, find-component(#f, name));
      end for;
  values(tests);
end method find-component;

define method display-run-options
    (start-suite :: <component>,
     report-function :: <function>, 
     options :: <perform-criteria>)
 => ()
  format-out
     ("\nRunning %s %s, with options:\n"
        "   progress-function: %s\n"
        "     report-function: %s\n"
        "              debug?: %s\n"
        "              ignore: %s\n\n",
      if (instance?(start-suite, <suite>)) "suite" else "test" end,
      component-name(start-suite),
      select (options.perform-progress-function)
        full-progress-function => "full";
        null-progress-function => "none";
      end,
      find-key($report-functions, curry(\=, report-function)),
      select (options.perform-debug?)
        #"crashes" => "crashes";
        #t         => "failures";
        otherwise  => "no";
      end,
      reduce(method (s :: <string>, c :: <component>)
               concatenate(s, component-name(c), " ")
             end method,
             " ",
             options.perform-ignore))
end method display-run-options;

define method compute-application-options
    (parent :: <component>, parser :: <command-line-parser>)
 => (start-suite :: <component>, 
     options :: <perform-criteria>,
     report-function :: <function>)
  let options = make(<perform-criteria>);

  let debug = get-option-value(parser, "debug");
  options.perform-debug?
    := select (debug by \=)
         #f, "no" => #f;
         "crashes" => #"crashes";
         #t, "failures" => #t;
         otherwise =>
           usage-error("Invalid --debug option: %s", debug);
       end select;

  if (get-option-value(parser, "progress"))
    options.perform-progress-function := full-progress-function;
    options.perform-announce-function := announce-component;
  else
    options.perform-progress-function := null-progress-function;
    options.perform-announce-function := method (component) end;
  end;

  let report = get-option-value(parser, "report") | "failures";
  let report-function = element($report-functions, report, default: #f)
    | usage-error("Invalid --report option: %s", report);

  let components = find-component(get-option-value(parser, "suite"),
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

  let ignore-suites = get-option-value(parser, "ignore-suite");
  let ignore-tests = get-option-value(parser, "ignore-test");
  options.perform-ignore := find-component(ignore-suites, ignore-tests);
  values(start-suite, options, report-function)
end method compute-application-options;

define method run-test-application
    (parent :: <component>, 
     #key command-name = application-name(),
          arguments = application-arguments(),
          report-format-function = *format-function*)
 => (result :: <result>)
  let parser = parse-args(arguments);
  let (start-suite, options, report-function)
    = block ()
        compute-application-options(parent, parser)
      exception (ex :: <usage-error>)
        format-out("%s\n", condition-to-string(ex));
        exit-application(2);
      end;

  // Run the appropriate test or suite
  block ()
    if (get-option-value(parser, "verbose")
          & (report-function ~= xml-report-function))
      display-run-options(start-suite, report-function, options)
    end;
    let result = #f;
    let handler <warning>
      = method (warning :: <warning>, next-handler :: <function>) => ()
          report-format-function("Warning: %s\n", warning);
          next-handler()
        end;
    profiling (cpu-time-seconds, cpu-time-microseconds, allocation)
      result := perform-component(start-suite, options, report-function: #f);
    results
      display-results(result,
                      report-function: report-function,
                      report-format-function: report-format-function);
      if (get-option-value(parser, "profile"))
        format-out("\nTest run took %d.%s seconds, allocating %d byte%s\n",
                   cpu-time-seconds,
                   integer-to-string(cpu-time-microseconds, size: 6),
                   allocation, plural(allocation));
      end if;
      format-out("\n");
      force-output(*standard-output*);
    end profiling;
    result
  afterwards
    end-test();
  end block;
end method run-test-application;

define not-inline function end-test ()
  // This function isn't intended to do anything; it just provides a place
  // to set a breakpoint before the program terminates.
  values()
end function end-test;
