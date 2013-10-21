Module:       %testworks
Synopsis:     Report generation
Author:       Shri Amit
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND


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
         $crashed =>
           crashes := crashes + 1;
         otherwise =>
           error("Invalid result status: %=", result.result-status);
       end
     end,
     result,
     test: test);
  values(passes, failures, not-executed, not-implemented, crashes)
end method count-results;


/// Summary generation

define method print-result-summary
    (result :: <result>, name :: <string>, #key test = always(#t))
 => ()
  let (passes, failures, not-executed, not-implemented, crashes)
    = count-results(result, test: test);
  let total = passes + failures + not-implemented + crashes;
  let percent = 100.0 * if (total = 0)
                          1
                        else
                          as(<float>, passes) / total
                        end;
  test-output("  Ran %d %s%s: %d passed (%s%%), %d failed, %d skipped, "
                "%d not implemented, %d crashed\n",
              total,
              name,
              if (total == 1) "" else "s" end,
              passes,
              percent,
              failures, not-executed, not-implemented, crashes);
end method print-result-summary;

define method print-result-info
    (result :: <result>, #key indent = "", test)
 => ()
  let result-status = result.result-status;
  let show-result? = if (test) test(result) else #t end;
  if (show-result?)
    test-output("\n%s%s %s",
                indent, result.result-name, status-name(result-status));
    if (result-status == $passed
        & instance?(result, <component-result>))
      test-output(" in %s seconds with %s bytes allocated.",
                  result-time(result), result-bytes(result) | "?");
    end if
  end;
end method print-result-info;

define method print-result-info
    (result :: <component-result>, #key indent = "", test)
 => ()
  next-method();
  let show-result? = if (test) test(result) else #t end;
  let reason = result.result-reason;
  if (show-result? & reason)
    test-output(" [%s]", reason);
  end;
  let subindent = concatenate(indent, "  ");
  for (subresult in result-subresults(result))
    print-result-info(subresult, indent: subindent, test: test)
  end
end method print-result-info;

// This 'after' method prints the reason for the result's failure
define method print-result-info
    (result :: <unit-result>, #key indent = "", test) => ()
  ignore(indent);
  next-method();
  let show-result? = if (test) test(result) else #t end;
  let reason = result.result-reason;
  if (show-result? & reason)
    test-output(" [%s]", reason);
  end;
end method print-result-info;



/// Report functions

define method null-report-function (result :: <result>) => ()
  #f
end method null-report-function;

define method summary-report-function
    (result :: <result>) => ()
  test-output("\n\n%s summary:\n", result-name(result));
  local method print-class-summary (result, name, class) => ()
          print-result-summary(result, name,
                               test: method (subresult)
                                       instance?(subresult, class)
                                     end)
        end;
  print-class-summary(result, "suite", <suite-result>);
  print-class-summary(result, "test",  <test-result>);
  print-class-summary(result, "check", <check-result>);
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

// TODO(cgay): either delete this or replace it with a json report.

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
            if (result.result-reason)
              test-output("Reason: %s\n", result.result-reason);
            end;
            for (subresult in result-subresults(result))
              generate-report(subresult)
            end
          else
            let reason = result.result-reason;
            if (reason)
              test-output("Reason: %s\n", remove-newlines(reason));
            end;
            if (~reason & instance?(result, <component-result>))
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

define function do-xml-element (element-name :: <string>, body :: <function>) => ()
  test-output("<%s>", element-name);
  body();
  test-output("</%s>\n", element-name);
end function;

define method do-xml-result-body (result :: <result>) => ();
  test-output("\n");
  do-xml-element("name", curry(xml-output-pcdata, result.result-name));
  let status = result.result-status;
  do-xml-element("status", curry(xml-output-pcdata, status.status-name));
end method;

define method do-xml-result-body (result :: <check-result>) => ();
  next-method();
  let reason = result.result-reason;
  if (reason)
    do-xml-element("reason", curry(xml-output-pcdata, reason));
  end if;
end method;

define method do-xml-result-body (result :: <component-result>) => ();
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
  if (result.result-reason)
    do-xml-element("reason",
                   method ()
                     xml-output-pcdata(result.result-reason);
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


/// Surefire report

define function emit-surefire-suite
    (suite :: <suite-result>) => ()
  let is-test-result? = rcurry(instance?, <test-result>);
  let test-results = choose(is-test-result?, result-subresults(suite));
  if (~empty?(test-results))
    let (passes, failures, not-executed, not-implemented, crashes)
      = count-results(suite, test: is-test-result?);
    test-output("  <testsuite name=\"%s\" failures=\"%d\" errors=\"%d\" tests=\"%d\">\n",
                suite.result-name, failures + not-implemented, crashes,
                test-results.size);
    do(curry(emit-surefire-test, suite), test-results);
    test-output("  </testsuite>\n");
  end if;
end function emit-surefire-suite;

define function emit-surefire-test
    (suite :: <suite-result>, test :: <test-result>) => ()
  test-output("    <testcase name=\"%s\" classname=\"%s\">",
              test.result-name, suite.result-name);
  let status = test.result-status;
  select (status)
    $passed => #f;
    $skipped =>
      test-output("\n      <skipped />\n");
    $not-implemented =>
      test-output("\n      <failure message=\"Not implemented\" />\n");
    otherwise =>
      // If this test failed then we know at least one of the checks
      // failed.  Note that (due to testworks-specs) a <test-result>
      // may contain <test-unit-result>s and we flatten those into
      // this result because they don't (apparently?) match Surefire's
      // format.
      test-output("\n      <failure>\n");
      do-results(emit-surefire-check, test,
                 test: rcurry(instance?, <check-result>));
      test-output("\n      </failure>\n");
  end select;
  test-output("    </testcase>\n");
end function emit-surefire-test;

define function emit-surefire-check
    (result :: <check-result>) => ()
  let status = result.result-status;
  let reason = result.result-reason;
  if (reason & status ~= $passed & status ~= $skipped)
    xml-output-pcdata(reason);
    test-output("\n");
  end;
end function emit-surefire-check;

define function collect-suite-results
    (result :: <result>) => (results :: <sequence>)
  let all-suites = make(<stretchy-vector>);
  iterate collect (r :: <result> = result)
    if (instance?(r, <suite-result>))
      all-suites := add!(all-suites, r);
      do(collect, result-subresults(r))
    end if;
  end iterate;
  all-suites
end function collect-suite-results;

define function surefire-report-function
    (result :: <result>) => ()
  test-output("%s\n", $xml-version-header);
  test-output("<testsuites>\n");
  do(emit-surefire-suite, collect-suite-results(result));
  test-output("</testsuites>\n");
end function surefire-report-function;
