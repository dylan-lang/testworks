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
         $expected-failure =>
           passes := passes + 1;
         $unexpected-success =>
           failures := failures + 1;
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
    (result :: <result>, name :: <string>, stream :: <stream>,
     #key test = always(#t))
 => ()
  let (passes, failures, not-executed, not-implemented, crashes)
    = count-results(result, test: test);
  let total = passes + failures + not-implemented + crashes;
  let percent = 100.0 * if (total = 0)
                          1
                        else
                          as(<float>, passes) / total
                        end;
  local method count-to-text-attributes (value :: <integer>, desired :: <text-attributes>)
         => (attr :: <text-attributes>)
          if (value > 0)
            desired
          else
            $count-text-attributes
          end if
        end;
  /*
  testworks-test-suite-app PASSED in 0.154072 seconds:
    Ran 10 suites: 10 passed (100.00000%), 0 failed, 0 skipped, 0 not implemented, 0 crashed
    Ran 37 tests: 37 passed (100.00000%), 0 failed, 0 skipped, 0 not implemented, 0 crashed
    Ran 0 benchmarks
    Ran 1455 checks: 1455 passed (100.00000%), 0 failed, 0 skipped, 0 not implemented, 0 crashed
  */
  format(stream, "  Ran %=%s%= %s%s",
         $total-text-attributes,
         total,
         $reset-text-attributes,
         name,
         if (total == 1) "" else "s" end);
  // If nothing ran, skip the details to make it obvious.
  if (total = 0)
    format(stream, "\n");
  else
    format(stream, ": %=%s%= passed (%s%%)",
           $count-text-attributes, passes, $reset-text-attributes, percent);
    // If 100% passed, skip details.
    if (total = passes)
      format(stream, "\n");
    else
      format(stream, ", %=%s%= failed, %=%s%= skipped, "
               "%=%s%= not implemented, %=%s%= crashed\n",
             count-to-text-attributes(failures, $failed-text-attributes),
             failures,
             $reset-text-attributes,
             count-to-text-attributes(not-executed, $skipped-text-attributes),
             not-executed,
             $reset-text-attributes,
             count-to-text-attributes(not-implemented, $not-implemented-text-attributes),
             not-implemented,
             $reset-text-attributes,
             count-to-text-attributes(crashes, $crashed-text-attributes),
             crashes,
             $reset-text-attributes);
    end;
  end;
end method print-result-summary;

define method print-result-info
    (result :: <result>, stream :: <stream>, #key indent = "", test)
 => ()
  let result-status = result.result-status;
  let show-result? = if (test) test(result) else #t end;
  if (show-result?)
    format(stream, "\n%s%s %s",
           indent, result.result-name, status-name(result-status));
    if (result-status == $passed
        & instance?(result, <metered-result>))
      format(stream, " in %s seconds with %s bytes allocated.",
             result-time(result), result-bytes(result) | "?");
    end if
  end;
end method print-result-info;

define method print-result-info
    (result :: <component-result>, stream :: <stream>, #key indent = "", test)
 => ()
  next-method();
  let show-result? = if (test) test(result) else #t end;
  let reason = result.result-reason;
  if (show-result? & reason)
    format(stream, " [%s]", reason);
  end;
  let subindent = concatenate(indent, "  ");
  for (subresult in result-subresults(result))
    print-result-info(subresult, stream, indent: subindent, test: test)
  end
end method print-result-info;

// This 'after' method prints the reason for the result's failure
define method print-result-info
    (result :: <unit-result>, stream :: <stream>, #key indent = "", test) => ()
  ignore(indent);
  next-method();
  let show-result? = if (test) test(result) else #t end;
  let reason = result.result-reason;
  if (show-result? & reason)
    format(stream, " [%s]", reason);
  end;
end method print-result-info;

define function stats-summary
    (v :: limited(<vector>, of: <double-float>))
 => (min-value :: <double-float>,
     max-value :: <double-float>,
     mean-value :: <double-float>,
     median-value :: <double-float>)
  let sorted = sort(v);
  let min-value = sorted.first;
  let max-value = sorted.last;
  let sum = reduce(\+, 0.0d0, sorted);
  let mean-value = sum / as(<double-float>, v.size);
  let midpoint = truncate/(v.size, 2);
  let median-value
    = if (odd?(v.size))
        sorted[midpoint]
      else
        (sorted[midpoint - 1] + sorted[midpoint]) / 2.0d0
      end if;
  values(min-value, max-value, mean-value, median-value)
end function;

define method print-result-info
    (result :: <benchmark-result>, stream :: <stream>, #key indent = "", test) => ()
  let result-status = result.result-status;
  let show-result? = if (test) test(result) else #t end;
  if (show-result?)
    format(stream, "\n%s%s %s",
           indent, result.result-name, status-name(result-status));
    if (result-status == $passed)
      format(stream, " in %s seconds with %s bytes allocated.",
             result-time(result), result-bytes(result) | "?");
    end if;
    let iteration-results
      = choose(rcurry(instance?, <benchmark-iteration-result>),
               result-subresults(result));
    unless (empty?(iteration-results))
      let iteration-times
        = map-as(limited(<vector>, of: <double-float>),
                 method (result :: <metered-result>) => (time :: <double-float>)
                   as(<double-float>, result.result-seconds)
                     + result.result-microseconds / 1.0d6;
                 end,
                 iteration-results);
      let (min-value :: <double-float>, max-value :: <double-float>,
           mean-value :: <double-float>, median-value :: <double-float>)
        = stats-summary(iteration-times);
      format(stream, "\n%s  %d iterations, per iteration min %s seconds, mean %s seconds,"
               " median %s seconds, max %s seconds",
             indent, iteration-times.size,
             float-time-to-string(min-value),
             float-time-to-string(mean-value),
             float-time-to-string(median-value),
             float-time-to-string(max-value));
    end unless;
  end if;
end method print-result-info;


/// Report functions

define method null-report-function
    (result :: <result>, stream :: <stream>) => ()
end;

define method summary-report-function
    (result :: <result>, stream :: <stream>) => ()
  let stream = colorize-stream(stream);
  let result-status = result.result-status;
  format(stream, "\n%s %=%s%= in %s seconds:\n",
         result.result-name,
         result-status-to-text-attributes(result-status),
         result-status.status-name.as-uppercase,
         $reset-text-attributes,
         result.result-time);
  local method print-class-summary (result, name, class) => ()
          print-result-summary(result, name, stream,
                               test: method (subresult)
                                       instance?(subresult, class)
                                     end)
        end;
  print-class-summary(result, "suite", <suite-result>);
  print-class-summary(result, "test", <test-result>);
  print-class-summary(result, "benchmark", <benchmark-result>);
  print-class-summary(result, "check", <check-result>);
end method summary-report-function;

define method failures-report-function
    (result :: <result>, stream :: <stream>) => ()
  if (result.result-status ~= $passed)
    print-result-info (result, stream,
                       test: method (result)
                               let status = result.result-status;
                               status ~== $passed & status ~== $skipped
                             end);
    format(stream, "\n");
  end;
  summary-report-function(result, stream);
end method failures-report-function;

define method full-report-function
    (result :: <result>, stream :: <stream>) => ()
  format(stream, "\n");
  print-result-info(result, stream, test: always(#t));
  summary-report-function(result, stream);
end method full-report-function;


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

define method log-report-function
    (result :: <result>, stream :: <stream>) => ()
  let stream = make(<indenting-stream>, inner-stream: stream);
  local method generate-report (result :: <result>) => ()
          let test-type = result-type-name(result);
          format(stream, "\nObject: %s\n", test-type);
          format(stream, "Name: %s\n", remove-newlines(result-name(result)));
          format(stream, "Status: %s\n", status-name(result-status(result)));
          let status = result.result-status;
          if (instance?(result, <component-result>))
            if (result.result-reason)
              format(stream, "Reason: %s\n", result.result-reason);
            end;
            for (subresult in result-subresults(result))
              with-indentation (stream, 2)
                generate-report(subresult);
              end with-indentation;
            end for;
          else
            let reason = result.result-reason;
            if (reason)
              format(stream, "Reason: %s\n", remove-newlines(reason));
            end;
            if (~reason & instance?(result, <component-result>))
              format(stream, "Seconds: %s\nAllocation: %d bytes\n",
                     result-time(result), result-bytes(result) | 0);
            end if;
          end;
          format(stream, "end\n");
        end method generate-report;
  format(stream, "\n%s", $test-log-header);
  generate-report(result);
  format(stream, "\n%s\n", $test-log-footer);
  failures-report-function(result, stream)
end method log-report-function;


/// XML report

define constant $xml-version-header
  = "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>";

define function xml-output-pcdata
    (text :: <string>, stream :: <stream>) => ()
  let text-size = text.size;
  iterate loop (start = 0, i = 0)
    if (i < text-size)
      select (text[i])
        '&' =>
          format(stream, "%s&amp;", copy-sequence(text, start: start, end: i));
          loop(i + 1, i + 1);

        '<' =>
          format(stream, "%s&lt;", copy-sequence(text, start: start, end: i));
          loop(i + 1, i + 1);

        '>' =>
          format(stream, "%s&gt;", copy-sequence(text, start: start, end: i));
          loop(i + 1, i + 1);

        otherwise =>
          loop(start, i + 1);
      end select;
    else
      format(stream, "%s", if (start = 0)
                             text
                           else
                             copy-sequence(text, start: start)
                           end);
    end if;
  end iterate;
end function;

define function do-xml-element
    (element-name :: <string>, body :: <function>, stream :: <stream>) => ()
  format(stream, "<%s>", element-name);
  body();
  format(stream, "</%s>\n", element-name);
end function;

define method do-xml-result-body
    (result :: <result>, stream :: <stream>) => ()
  format(stream, "\n");
  do-xml-element("name", curry(xml-output-pcdata, result.result-name, stream), stream);
  let status = result.result-status;
  do-xml-element("status", curry(xml-output-pcdata, status.status-name, stream), stream);
end method do-xml-result-body;

define method do-xml-result-body
    (result :: <check-result>, stream :: <stream>) => ()
  next-method();
  let reason = result.result-reason;
  if (reason)
    do-xml-element("reason", curry(xml-output-pcdata, reason, stream), stream);
  end if;
end method do-xml-result-body;

define method do-xml-result-body
    (result :: <metered-result>, stream :: <stream>) => ()
  next-method();
  do-xml-element("seconds",
                 method ()
                   format(stream, "%d", result.result-seconds)
                 end,
                 stream);
  do-xml-element("microseconds",
                 method ()
                   format(stream, "%d", result.result-microseconds)
                 end,
                 stream);
  do-xml-element("allocation",
                 method ()
                   format(stream, "%d", result.result-bytes)
                 end,
                 stream);
end method do-xml-result-body;

define method do-xml-result-body
    (result :: <component-result>, stream :: <stream>) => ()
  next-method();
  if (result.result-reason)
    do-xml-element("reason",
                   method ()
                     xml-output-pcdata(result.result-reason, stream);
                   end,
                   stream);
  end if;
  do(rcurry(do-xml-result, stream), result-subresults(result));
end method;

define method do-xml-result
    (result :: <result>, stream :: <stream>) => ()
  do-xml-element(result-type-name(result),
                 curry(do-xml-result-body, result, stream),
                 stream);
end method do-xml-result;

define method xml-report-function
    (result :: <result>, stream :: <stream>) => ()
  format(stream, "%s\n", $xml-version-header);
  do-xml-element("test-report",
                 method ()
                   format(stream, "\n");
                   do-xml-result(result, stream);
                 end,
                 stream);
end method xml-report-function;


/// Surefire report

define function emit-surefire-suite
    (suite :: <suite-result>, stream :: <stream>) => ()
  let is-test-result? = rcurry(instance?, <test-result>);
  let test-results = choose(is-test-result?, result-subresults(suite));
  if (~empty?(test-results))
    let (passes, failures, not-executed, not-implemented, crashes)
      = count-results(suite, test: is-test-result?);
    format(stream,
           "  <testsuite name=\"%s\" failures=\"%d\" errors=\"%d\" tests=\"%d\">\n",
           suite.result-name, failures + not-implemented, crashes,
           test-results.size);
    do(method (test)
         emit-surefire-test(suite, test, stream);
       end,
       test-results);
    format(stream, "  </testsuite>\n");
  end if;
end function emit-surefire-suite;

define function emit-surefire-test
    (suite :: <suite-result>, test :: <test-result>, stream :: <stream>) => ()
  format(stream, "    <testcase name=\"%s\" classname=\"%s\" time=\"%s\">",
         test.result-name, suite.result-name, test.result-time);
  let status = test.result-status;
  select (status)
    $passed =>
      format(stream, "\n");
    $skipped =>
      format(stream, "\n      <skipped />\n");
    $not-implemented =>
      format(stream, "\n      <failure message=\"Not implemented\" />\n");
    otherwise =>
      // If this test failed then we know at least one of the checks
      // failed.  Note that (due to testworks-specs) a <test-result>
      // may contain <test-unit-result>s and we flatten those into
      // this result because they don't (apparently?) match Surefire's
      // format.
      format(stream, "\n      <failure>\n");
      do-results(rcurry(emit-surefire-check, stream), test,
                 test: rcurry(instance?, <check-result>));
      format(stream, "\n      </failure>\n");
  end select;
  format(stream, "    </testcase>\n");
end function emit-surefire-test;

define function emit-surefire-check
    (result :: <check-result>, stream :: <stream>) => ()
  let status = result.result-status;
  let reason = result.result-reason;
  if (reason & status ~= $passed & status ~= $skipped)
    xml-output-pcdata(reason, stream);
    format(stream, "\n");
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
    (result :: <result>, stream :: <stream>) => ()
  format(stream, "%s\n", $xml-version-header);
  format(stream, "<testsuites>\n");
  do(rcurry(emit-surefire-suite, stream),
     collect-suite-results(result));
  format(stream, "</testsuites>\n");
end function surefire-report-function;

/// JSON report

define function json-report-function (result :: <result>, stream :: <stream>) => ()
  encode-json(stream, result);
end;

define method encode-json (stream :: <stream>, result :: <result>)
  encode-json(stream, result-to-table(result));
end;

// It's easier to convert to <table> and let the json library do the actual
// object formatting.

define method result-to-table (result :: <result>) => (t :: <table>)
  let t = make(<string-table>, size: 8);
  t["type"] := result-type-name(result);
  t["name"] := result.result-name;
  t["status"] := status-name(result.result-status);
  t["reason"] := result.result-reason;
  t
end;

define method result-to-table (result :: <metered-result>) => (t :: <table>)
  let t = next-method();
  t["seconds"] := result.result-seconds;
  t["microseconds"] := result.result-microseconds;
  t["bytes"] := result.result-bytes;
  t
end;

define method result-to-table (result :: <component-result>) => (t :: <table>)
  let t = next-method();
  t["children"] := result.result-subresults;
  t
end;
