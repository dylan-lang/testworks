Module:       testworks-report-lib
Synopsis:     A tool to generate reports from test run logs
Author:       Shri Amit, Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// Application options

// TODO(cgay): use command-line-parser https://github.com/dylan-lang/testworks/issues/121

define class <application-options> (<object>)
  constant slot application-quiet? :: <boolean> = #f,
    init-keyword: quiet?:;
  constant slot application-log1 :: <string>,
    required-init-keyword: log1:;
  constant slot application-log2 :: false-or(<string>) = #f,
    init-keyword: log2:;
  constant slot application-report-function :: <function>,
    required-init-keyword: report-function:;
  constant slot application-tests :: <sequence> = #[],
    init-keyword: tests:;
  constant slot application-suites :: <sequence> = #[],
    init-keyword: suites:;
  constant slot application-ignored-tests :: <sequence> = #[],
    init-keyword: ignored-tests:;
  constant slot application-ignored-suites :: <sequence> = #[],
    init-keyword: ignored-suites:;
  constant slot application-tolerance :: <integer> = $default-benchmark-tolerance,
    init-keyword: tolerance:;
end class <application-options>;

define function print-elements
    (sequence :: <sequence>, #key prefix = "", postfix = "\n") => ()
  let separator = ", ";
  let current-separator = "";
  let sequence-size = size(sequence);
  format-out(prefix);
  for (element in sequence)
    format-out("%s%s", current-separator, element);
    current-separator := separator
  end;
  format-out(postfix);
end function print-elements;

define method display-run-options
    (options :: <application-options>) => ()
  unless (application-quiet?(options))
    let log1 = application-log1(options);
    let log2 = application-log2(options);
    let report-function = application-report-function(options);
    let tests = application-tests(options);
    let suites = application-suites(options);
    let ignored-tests = application-ignored-tests(options);
    let ignored-suites = application-ignored-suites(options);
    format-out("\n");
    if (log2)
      format-out("Comparing log files:\n  %s\n  %s\n\n", log1, log2)
    else
      format-out("Generating report for:\n  %s\n", log1)
    end;
    format-out("\n    Report function: %s\n",
               select (report-function by \=)
                 print-diff-full-report      => "full-diff";
                 print-diff-report           => "diff";
                 print-diff-summary-report   => "diff-summary";
                 print-benchmark-diff-report => "benchmark-diff";
                 print-summary-report        => "summary";
                 print-failures-report       => "failures";
                 print-full-report           => "full";
                 otherwise                   => "*** unrecognised ***";
               end);
    print-elements(tests,          prefix: "              Tests: ");
    print-elements(suites,         prefix: "             Suites: ");
    print-elements(ignored-tests,  prefix: "      Ignored Tests: ");
    print-elements(ignored-suites, prefix: "     Ignored Suites: ");
    format-out("Benchmark tolerance: %d%%\n", application-tolerance(options));
    format-out("\n")
  end
end method display-run-options;

/// application-error

// TODO(cgay): this should be defined in the testworks module
define class <testworks-error> (<format-string-condition>, <error>)
end;

define function application-error (format-string :: <string>, #rest args)
  signal(make(<testworks-error>,
              format-string: format-string,
              format-arguments: args));
end function;


/// Command line arguments

// Removed '/' from this list because it is patently broken for Linux.
// --cgay 2006.11.23
define constant $keyword-prefixes = #['-'];

define method process-argument
    (argument :: <string>)
 => (text :: <string>, keyword? :: <boolean>)
  if (keyword-argument?(argument))
    values(copy-sequence(argument, start: 1), #t)
  else
    values(argument, #f)
  end
end method process-argument;

define method keyword-argument?
    (argument :: <string>) => (keyword? :: <boolean>)
  member?(argument[0], $keyword-prefixes)
  & block ()   // don't treat a negative integer as a keyword arg.
      let (int, index) = string-to-integer(argument);
      ignore(int);
      size(argument) ~= index
    exception (e :: <error>)
      #t
    end
end method keyword-argument?;

define constant $usage-exit-status = 2;

define method invalid-argument (format-string :: <string>, #rest args) => ()
  display-help(application-name());
  format-out("\n");
  apply(format-out, format-string, args);
  exit-application($usage-exit-status);
end method invalid-argument;

define method argument-value
    (keyword :: <string>, arguments :: <deque>,
     #key allow-zero-arguments?)
 => (value :: <stretchy-vector>)
  if (~allow-zero-arguments?
      & (empty?(arguments) | keyword-argument?(arguments[0])))
    invalid-argument("No argument specified for keyword '%s'.\n", keyword)
  end;
  let value = make(<stretchy-vector>);
  while (~empty?(arguments) & ~keyword-argument?(arguments[0]))
    add!(value, pop(arguments))
  end;
  value
end method argument-value;

define constant $help-format-string =
  "Application: %s\n"
  "\n"
  "  Arguments: report1\n"
  "             [report2]\n"
  "             [-quiet]\n"
  "             [-report [full failures summary diff full-diff diff-summary benchmark-diff]]\n"
  "             [-suite <name1> <name2> ... ...]\n"
  "             [-test <name1> <name2> ... ...]\n"
  "             [-ignore-suite <name1> <name2> ... ...]\n"
  "             [-ignore-test <name1> <name2> ... ...]\n"
  "             [-tolerance <percentage>]\n";

define method display-help (command-name :: <string>) => ()
  format-out($help-format-string, command-name);
end method display-help;

define method parse-arguments
    (command-name :: <sequence>, arguments :: <sequence>)
 => (options :: <application-options>)
  let arguments = as(<deque>, arguments);
  let log1 = #f;
  let log2 = #f;
  let suites = #[];
  let tests = #[];
  let ignored-suites = #[];
  let ignored-tests = #[];
  let report-function = #f;
  let quiet? = #f;
  let tolerance = $default-benchmark-tolerance;
  // Parse through the arguments
  while (~empty?(arguments))
    let argument = pop(arguments);
    let (option, keyword?) = process-argument(argument);
    select (option by \=)
      "report" =>
        report-function
          := begin
               let function-name = pop(arguments);
               select (function-name by \=)
                 "full"         => print-full-report;
                 "summary"      => print-summary-report;
                 "failures"     => print-failures-report;
                 "diff"         => print-diff-report;
                 "full-diff"    => print-diff-full-report;
                 "diff-summary" => print-diff-summary-report;
                 "benchmark-diff" => print-benchmark-diff-report;
                 otherwise =>
                   invalid-argument("Report function '%s' not supported.\n",
                                    function-name);
               end
             end;
      "suite" =>
        suites := concatenate(suites, argument-value(option, arguments));
      "test" =>
        tests := concatenate(tests, argument-value(option, arguments));
      "ignore-suite" =>
        ignored-suites
          := concatenate(ignored-suites, argument-value(option, arguments));
      "ignore-test" =>
        ignored-tests
          := concatenate(ignored-tests,  argument-value(option, arguments));
      "quiet" =>
        quiet? := #t;
      "verbose" =>
        quiet? := #f;
      "tolerance" =>
        let vals = argument-value(option, arguments);
        block ()
          tolerance := string-to-integer(vals[0]);
        exception (e :: <error>)
          invalid-argument("Invalid argument specified for the %s keyword: '%s'.\n",
                           option, vals[0]);
        end;
      otherwise =>
        case
          log1 & log2 =>
            invalid-argument("Invalid command line keyword '%s'.\n", option);
          log1      => log2 := option;
          otherwise => log1 := option;
        end;
    end
  end;
  unless (log1)
    invalid-argument("Report file missing - one or two report files must be supplied\n")
  end;
  unless (report-function)
    report-function := if (log2)
                         print-diff-report
                       else
                         print-failures-report
                       end;
  end;
  if (log2 & member?(report-function, vector(print-full-report,
                                             print-failures-report,
                                             print-summary-report)))
    invalid-argument("The report function specified is not meaningful "
                     "when two report files are specified.\n");
  end if;
  if (~log2 & member?(report-function, vector(print-diff-report,
                                              print-diff-full-report,
                                              print-diff-summary-report,
                                              print-benchmark-diff-report)))
    invalid-argument("The report function specified is only meaningful "
                     "when two report files are specified.\n");
  end if;
  make(<application-options>,
       log1: log1, log2: log2,
       quiet?: quiet?, report-function: report-function,
       tolerance: tolerance,
       tests: tests, suites: suites,
       ignored-tests:  map(as-lowercase, ignored-tests),
       ignored-suites: map(as-lowercase, ignored-suites))
end method parse-arguments;

// TODO(cgay): use strings library
define method case-insensitive-equal?
    (name1 :: <string>, name2 :: <string>)
 => (equal? :: <boolean>)
  as-lowercase(name1) = as-lowercase(name2)
end method case-insensitive-equal?;

define method find-named-results
    (result :: <check-result>, #key tests = #[], suites = #[])
 => (named-results :: <sequence>)
  #[]
end method find-named-results;

define method find-named-results
    (results :: <sequence>, #key tests = #[], suites = #[])
 => (named-results :: <sequence>)
  let named-results = make(<stretchy-vector>);
  for (subresult in results)
    let subresults
      = find-named-results(subresult, tests: tests, suites: suites);
    for (result in subresults)
      add!(named-results, result)
    end
  end;
  named-results
end method find-named-results;

define method find-named-results
    (result :: <test-result>, #key tests = #[], suites = #[])
 => (named-results :: <sequence>)
  let match?
    = member?(result.result-name, tests, test: case-insensitive-equal?);
  if (match?)
    vector(result)
  else
    find-named-results
      (result.result-subresults, tests: tests, suites: suites)
  end
end method find-named-results;

define method find-named-results
    (result :: <suite-result>, #key tests = #[], suites = #[])
 => (named-results :: <sequence>)
  let match?
    = member?(result.result-name, suites, test: case-insensitive-equal?);
  if (match?)
    vector(result)
  else
    find-named-results
      (result.result-subresults, tests: tests, suites: suites)
  end
end method find-named-results;

define method find-named-result
    (result :: <result>, #key tests = #[], suites = #[])
 => (named-result :: <result>)
  let results = find-named-results(result, tests: tests, suites: suites);
  select (size(results))
    0 =>
      application-error("No matches for tests %= or suites %=", tests, suites);
    1 =>
      results[0];
    otherwise =>
      let passed?
        = every?(method (subresult)
                   let status = subresult.result-status;
                   status = $passed | status = $skipped
                 end,
                 results);
      make(<suite-result>,
           name: "[Specified tests/suites]",
           status: if (passed?) $passed else $failed end,
           subresults: results);
  end
end method find-named-result;

define method main
    (command-name :: <string>, arguments :: <sequence>) => ()
  // Process the command line arguments
  if (arguments & ~empty?(arguments))
    let (first-argument, keyword?) = process-argument(arguments[0]);
    if (keyword? & member?(first-argument, #["help", "?"], test: \=))
      display-help(command-name);
      exit-application(0);
    end if;
  end if;
  let options = parse-arguments(command-name, arguments);
  display-run-options(options);
  let path1 = application-log1(options);
  let path2 = application-log2(options);
  let tests = application-tests(options);
  let suites = application-suites(options);
  let report-function = application-report-function(options);
  let ignored-tests = application-ignored-tests(options);
  let ignored-suites = application-ignored-suites(options);
  let tolerance = application-tolerance(options);
  local method read-report-with-options
            (path :: <string>) => (result :: <result>)
          block ()
            let result
              = read-report(path,
                            ignored-tests: ignored-tests,
                            ignored-suites: ignored-suites);
            if (~empty?(tests) | ~empty?(suites))
              find-named-result(result,
                                tests: tests,
                                suites: suites)
            else
              result
            end
          exception (e :: <file-does-not-exist-error>)
            application-error("Error: %s", e);
          end block
        end method;
  let result1 = read-report-with-options(path1);
  if (path2)
    let result2 = read-report-with-options(path2);
    perform-test-diff
      (path1: path1, path1: path2, result1: result1, result2: result2,
       report-function: report-function,
       tolerance: tolerance);
  else
    report-function(result1, *standard-output*);
  end;
end method main;
