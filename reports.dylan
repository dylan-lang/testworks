Module:       testworks
Synopsis:     Reporting functions for TestWorks
Author:       Shri Amit
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// Display results

define method display-results
    (result :: <result>,
     #key report-function = *default-report-function*,
          report-format-function = *format-function*)
 => ()
  if (report-function)
    dynamic-bind (*format-function* = report-format-function)
      report-function(result)
    end
  end
end method display-results;


/// Results component

define method do-results
    (function :: <function>, result :: <result>,
     #key test = always(#t))
 => ()
  if (test(result))
    function(result)
  end
end method do-results;

define method do-results
    (function :: <function>, result :: <component-result>,
     #key test = always(#t))
 => ()
  next-method();
  for (subresult in result-subresults(result))
    do-results(function, subresult, test: test)
  end
end method do-results;

define method count-results
    (result :: <result>, #key test = always(#t))
 => (passes :: <integer>, failures :: <integer>,
     not-executed :: <integer>, not-implemented :: <integer>,
     crashes :: <integer>)
  let passes          = 0;
  let failures        = 0;
  let not-executed    = 0;
  let not-implemented = 0;
  let crashes         = 0;
  do-results
    (method (result)
       select (result.result-status)
         $passed =>
           passes := passes + 1;
         $failed =>
           failures := failures + 1;
         $skipped =>
           not-executed := not-executed + 1;
         $not-implemented =>
           not-implemented := not-implemented + 1;
         otherwise =>
           crashes := crashes + 1;
       end
     end,
     result,
     test: test);
  values(passes, failures, not-executed, not-implemented, crashes)
end method count-results;

/*
define function sum-benchmark-results
    (result :: <result>)
 => (seconds, microseconds, bytes-allocated)
  let seconds = 0;
  let microseconds = 0;
  let allocation = 0;
  local method sum-benches (result :: <benchmark-result>)
          let sec = result-seconds(result);
          let usec = result-microseconds(result);
          let bytes = result-bytes(result);
          if (sec & usec & bytes)
            microseconds := microseconds + usec;
            if (microseconds >= 1000000)
              microseconds := microseconds - 1000000;
              seconds := seconds + 1;
            end if;
            seconds := seconds + sec;
            allocation := allocation + bytes;
          end if;
        end method;
  do-results(sum-benches, result,
             test: method (result :: <result>) => (b :: <boolean>)
                     instance?(result, <benchmark-result>)
                   end);
  values((seconds > 0) & seconds,
         (microseconds > 0) & microseconds,
         (allocation > 0) & allocation)
end function sum-benchmark-results;
*/
define constant $benchmark-result-divider
  = "    -------------------------------------------------------------------------------";

define method print-benchmark-result-header () => ()
  print-one-benchmark-result("Benchmark", "Time (sec)", "Bytes allocated");
  test-output("%s\n", $benchmark-result-divider);
end method print-benchmark-result-header;

define method print-one-benchmark-result
    (name :: <string>, time :: <string>, allocation :: <string>) => ()
  local method pad-to (name, columns, align-left?)
          let len = size(name);
          if (len > columns)
            name
          else
            let filler = make(<string>, size: columns - len, fill: ' ');
            if (align-left?)
              concatenate(name, filler)
            else
              concatenate(filler, name)
            end if
          end if
        end method;
  test-output("    %s %s   %s\n",
              pad-to(name, 50, #t),
              pad-to(time, 10, #f),
              pad-to(allocation, 12, #f));
end method print-one-benchmark-result;

define method print-benchmark-result-footer
    (title :: <string>, time :: <string>,
     allocation :: <string>, crashes :: <integer>, #key divider? = #t)
 => ()
  divider? & test-output("%s\n", $benchmark-result-divider);
  print-one-benchmark-result(title, time, allocation);
  if (crashes > 0)
    test-output("\n    [*] %d benchmark%s crashed.\n", crashes, plural(crashes));
  end if;
end method print-benchmark-result-footer;

// ---*** carlg 99-02-17 Currently this displays each test's output in a separate
//        table.  It may be preferable to display all benchmarks in a single flat
//        table?  It sort of depends on how we expect the benchmarks to be organized...
define method print-benchmark-results
    (result :: <result>)
 => ()
  let total-seconds = 0;
  let total-microseconds = 0;
  let total-allocation = 0;
  let any-displayed? = #f;
  local method do-one-component (result :: <component-result>) => ()
          let seconds = 0;
          let microseconds = 0;
          let allocation = 0;
          let crashed = 0;
          let header-displayed? = #f;
          local method maybe-display-header () => ()
                  if (~header-displayed?)
                    header-displayed? := #t;
                    any-displayed? := #t;
                    test-output("\n  %s %s\n",
                              result-type-name(result), result-name(result));
                    print-benchmark-result-header();
                  end if;
                end method;
          local method maybe-display-footer () => ()
                  if (header-displayed?)
                    print-benchmark-result-footer
                      ("Subtotals:",
                       time-to-string(seconds, microseconds),
                       integer-to-string(allocation),
                       crashed);
                    let (newsec, newusec) = addtimes(total-seconds, total-microseconds,
                                                     seconds, microseconds);
                    total-seconds := newsec;
                    total-microseconds := newusec;
                    total-allocation := total-allocation + allocation;
                  end if;
                end method;
          for (bench in result-subresults(result))
            if (instance?(bench, <benchmark-result>))
              let sec = result-seconds(bench);
              let usec = result-microseconds(bench);
              let bytes = result-bytes(bench);
              let name = result-name(bench);
              let time = result-time(bench);
              let sbytes = result-bytes(bench) & integer-to-string(result-bytes(bench));
              if (result-status(bench) == $passed)
                let (newsec, newusec) = addtimes(seconds, microseconds, sec, usec);
                seconds := newsec;
                microseconds := newusec;
                allocation := allocation + bytes;
              else
                crashed := crashed + 1;
                name := concatenate(name, " [*]");
                time := "N/A";
                sbytes := "N/A";
              end if;
              maybe-display-header();
              print-one-benchmark-result(name, time, sbytes);
            end if;
          end for;
          maybe-display-footer();
          for (subresult in result-subresults(result))
            if (instance?(subresult, <component-result>))
              do-one-component(subresult);
            end if;
          end for;
        end method;
  do-one-component(result);
  if (any-displayed?)
    test-output("\n  Totals: %s seconds, %d bytes allocated.\n",
                time-to-string(total-seconds, total-microseconds), total-allocation);
  end if;
end method print-benchmark-results;


/// Summary generation

define method print-percentage
    (count :: <integer>, size :: <integer>,
     #key decimal-places = 1) => ()
  case
    size > 0 =>
      let shift = 10; // 10 ^ decimal-places;
      let percentage = ceiling/(count * 100 * shift, size);
      let (integer, remainder) = floor/(percentage, shift);
      test-output("%d.%d%%", integer, floor(remainder));
    otherwise =>
      test-output("100%%");
  end
end method print-percentage;

define method print-result-summary
    (result :: <result>, name :: <string>,
     #key test = always(#t))
 => ()
  let (passes, failures, not-executed, not-implemented, crashes)
    = count-results(result, test: test);
  let total-results = passes + failures + not-implemented + crashes;
  test-output("  Ran %d %s%s %d passed (",
              total-results,
              name,
              if (total-results == 1) ": " else "s: " end,
              passes);
  print-percentage(passes, total-results);
  test-output("), %d failed, %d skipped, %d not implemented, %d crashed\n",
              failures, not-executed, not-implemented, crashes);
end method print-result-summary;

define method print-result-class-summary
    (result :: <result>, name :: <string>, class :: <class>) => ()
  print-result-summary(result, name,
                       test: method (subresult)
                               instance?(subresult, class)
                             end)
end method print-result-class-summary;

define method print-result-info
    (result :: <result>, #key indent = "", test)
 => ()
  let result-status = result.result-status;
  let show-result? = if (test) test(result) else #t end;
  if (show-result?)
    test-output("\n%s%s %s",
                indent, result.result-name, status-name(result-status));
    if (result-status == $passed
        & instance?(result, <benchmark-result>))
      test-output(" in %s seconds with %d bytes allocated.",
                  result-time(result), result-bytes(result) | 0);
    end if
  end;
end method print-result-info;

define method print-result-info
    (result :: <component-result>, #key indent = "", test)
 => ()
  next-method();
  let show-result? = if (test) test(result) else #t end;
  let status = result.result-status;
  if (show-result? & instance?(status, <serious-condition>))
    print-error(status);
  end;
  let subindent = concatenate(indent, "  ");
  for (subresult in result-subresults(result))
    print-result-info(subresult, indent: subindent, test: test)
  end
end method print-result-info;



/// Report functions

define method null-report-function (result :: <result>) => ()
  #f
end method null-report-function;

define method summary-report-function (result :: <result>) => ()
  print-benchmark-results(result);
  test-output("\n\n%s summary:\n", result-name(result));
  print-result-class-summary(result, "suite", <suite-result>);
  print-result-class-summary(result, "test",  <test-result>);
  print-result-class-summary(result, "check", <check-result>);
  print-result-class-summary(result, "benchmark", <benchmark-result>);
end method summary-report-function;

define method failures-report-function (result :: <result>) => ()
  test-output("\n");
  select (result.result-status)
    $passed =>
      test-output("%s passed\n", result.result-name);
    otherwise =>
      print-result-info
        (result,
         test: method (result)
                 let status = result.result-status;
                 status ~== $passed & status ~== $skipped
               end);
      test-output("\n");
  end;
  summary-report-function(result);
end method failures-report-function;

define method full-report-function (result :: <result>) => ()
  test-output("\n");
  print-result-info(result, test: always(#t));
  summary-report-function(result);
end method full-report-function;

define variable *default-report-function* = failures-report-function;


/// Log report

define constant $test-log-header = "--------Test Log Report--------";
define constant $test-log-footer = "--------End Log Report---------";

define method remove-newlines
    (string :: <string>) => (new-string :: <string>)
  let string = copy-sequence(string);
  for (i from 0 below size(string))
    when (string[i] = '\n')
      string[i] := ' '
    end
  end;
  string
end method remove-newlines;

define method log-report-function (result :: <result>) => ()
  local method generate-report (result :: <result>) => ()
          let test-type = result-type-name(result);
          test-output("\nObject: %s\n", test-type);
          test-output("Name: %s\n", remove-newlines(result-name(result)));
          test-output("Status: %s\n", status-name(result-status(result)));
          let status = result.result-status;
          if (instance?(result, <component-result>))
            if (instance?(status, <error>))
              test-output("Reason: %s\n",
                          remove-newlines(safe-error-to-string(status)))
            end;
            for (subresult in result-subresults(result))
              generate-report(subresult)
            end
          else
            let operation = result-operation(result);
            let value = result-value(result);
            let reason = block ()
                           failure-reason(status, operation, value)
                         exception (ex :: <error>)
                           "***error getting failure reason***"
                         end;
            if (reason)
              test-output("Reason: %s\n", remove-newlines(reason));
            end;
            if (~reason & instance?(result, <benchmark-result>))
              test-output("Seconds: %s\nAllocation: %d bytes\n",
                          result-time(result), result-bytes(result) | 0);
            end if;
          end;
          test-output("end\n");
        end method generate-report;
  test-output("\n%s", $test-log-header);
  generate-report(result);
  test-output("\n%s\n", $test-log-footer);
  failures-report-function(result)
end method log-report-function;


/// XML report

define constant $xml-version-header
  = "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>";

define function xml-output-pcdata (text :: <string>) => ()
  let text-size = text.size;
  iterate loop (start = 0, i = 0)
    if (i < text-size)
      select (text[i])
        '&' =>
          test-output("%s&amp;", copy-sequence(text, start: start, end: i));
          loop(i + 1, i + 1);

        '<' =>
          test-output("%s&lt;", copy-sequence(text, start: start, end: i));
          loop(i + 1, i + 1);

        '>' =>
          test-output("%s&gt;", copy-sequence(text, start: start, end: i));
          loop(i + 1, i + 1);

        otherwise =>
          loop(start, i + 1);
      end select;
    else
      test-output("%s",
                  if (start = 0)
                    text
                  else
                    copy-sequence(text, start: start)
                  end);
    end if;
  end iterate;
end function;

define function do-xml-element (gi :: <string>, body :: <function>) => ()
  test-output("<%s>", gi);
  body();
  test-output("</%s>\n", gi);
end function;

define method do-xml-result-body (result :: <result>) => ();
  test-output("\n");
  do-xml-element("name", curry(xml-output-pcdata, result.result-name));
  let status = result.result-status;
  do-xml-element("status", curry(xml-output-pcdata, status.status-name));
end method;

define method do-xml-result-body (result :: <check-result>) => ();
  next-method();
  let operation = result-operation(result);
  let value = result-value(result);
  let reason
    = block ()
        failure-reason(result.result-status, operation, value)
      exception (ex :: <error>)
        format-to-string("***error %s getting failure reason***", ex);
      end;
  if (reason)
    do-xml-element("reason", curry(xml-output-pcdata, reason));
  end if;
end method;

define method do-xml-result-body (result :: <benchmark-result>) => ();
  next-method();
  do-xml-element("seconds",
                 method ()
                   test-output("%d", result.result-seconds)
                 end);
  do-xml-element("microseconds",
                 method ()
                   test-output("%d", result.result-microseconds)
                 end);
  do-xml-element("allocation",
                 method ()
                   test-output("%d", result.result-bytes)
                 end);
end method;

define method do-xml-result-body (result :: <component-result>) => ();
  next-method();
  let status = result.result-status;
  if (instance?(status, <error>))
    do-xml-element("reason",
                   method ()
                     xml-output-pcdata(safe-error-to-string(status));
                   end);
  end if;
  do(do-xml-result, result-subresults(result));
end method;

define method do-xml-result (result :: <result>) => ();
  do-xml-element(result-type-name(result), curry(do-xml-result-body, result));
end method;

define method xml-report-function (result :: <result>) => ()
  test-output("%s\n", $xml-version-header);
  do-xml-element("test-report",
                 method ()
                   test-output("\n");
                   do-xml-result(result);
                 end);
end method;

define function emit-surefire-suite (suite :: <suite-result>)
  let is-test-result? = rcurry(instance?, <test-result>);
  let test-results = choose(is-test-result?, result-subresults(suite));
  if (~empty?(test-results))
    let (passes, failures, not-executed, not-implemented, crashes)
      = count-results(suite, test: is-test-result?);
    test-output("<testsuite name=\"%s\" failures=\"%d\" errors=\"%d\" tests=\"%d\">\n",
                suite.result-name, failures + not-implemented, crashes,
                test-results.size);
    do(curry(emit-surefire-test, suite), test-results);
    test-output("</testsuite>\n");
  end if;
end function;

define function emit-surefire-test (suite :: <suite-result>,
                                    test :: <test-result>)
  let checks = choose(rcurry(instance?, <check-result>),
                      result-subresults(test));
  test-output("<testcase name=\"%s\" classname=\"%s\">",
              test.result-name, suite.result-name);
  select (test.result-status)
    $passed => #f;
    $skipped =>
      test-output("<skipped />");
    $not-implemented =>
      test-output("<failure message=\"Not implemented\" />");
    otherwise =>
      do(emit-surefire-check, checks);
  end select;
  test-output("</testcase>\n");
end function;

define function extract-check-failure (result :: <check-result>)
 => (reason :: <string>)
  let operation = result-operation(result);
  let value = result-value(result);
  block ()
    failure-reason(result.result-status, operation, value)
  exception (ex :: <error>)
    format-to-string("***error %s getting failure reason***", ex);
  end;
end function;

define function emit-surefire-check (result :: <check-result>)
  let status = result.result-status;
  if (status ~= $passed)
    let reason = if (status == $failed)
                   extract-check-failure(result)
                 elseif (instance?(status, <error>))
                   safe-error-to-string(status);
                 else
                   format-to-string("Unknown failure: %=", status)
                 end if;
    test-output("\n<failure>");
    xml-output-pcdata(reason);
    test-output("</failure>\n");
  end if;
end function;

define function collect-suite-results (result :: <result>) => (results :: <sequence>)
  let all-suites = make(<stretchy-vector>);
  iterate collect (r :: <result> = result)
    if (instance?(r, <suite-result>))
      all-suites := add!(all-suites, r);
      do(collect, result-subresults(r))
    end if;
  end iterate;
  all-suites
end function;

define method surefire-report-function (result :: <result>) => ()
  test-output("%s\n", $xml-version-header);
  test-output("<testsuites>\n");
  do(emit-surefire-suite, collect-suite-results(result));
  test-output("</testsuites>\n");
end method;
