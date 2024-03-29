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
 => (pass :: <integer>, fail :: <integer>, crash :: <integer>,
     skip :: <integer>, nyi :: <integer>, expected-to-fail :: <integer>)
  let (pass, fail, crash, skip, nyi, expected-failures) = values(0, 0, 0, 0, 0, 0);
  do-results(method (result)
               // Not all types of result have all of these kinds of status.
               // e.g., <check-result> is never $skipped or $not-implemented.
               select (result.result-status)
                 $passed =>
                   pass := pass + 1;
                 $failed =>
                   fail := fail + 1;
                 $crashed =>
                   crash := crash + 1;
                 $skipped =>
                   skip := skip + 1;
                 $not-implemented =>
                   nyi := nyi + 1;
                 $expected-failure =>
                   expected-failures := expected-failures + 1;
                 $unexpected-success =>
                   fail := fail + 1; // Should report separately?
                 otherwise =>
                   error("Invalid result status: %=", result.result-status);
               end;
             end method,
             result,
             test: test);
  values(pass, fail, crash, skip, nyi, expected-failures)
end method;

define function count-results-of-type
    (result :: <result>, type :: subclass(<result>)) => (n :: <integer>)
  let n = 0;
  do-results(method (r) n := n + 1 end,
             result,
             test: method (r) instance?(r, type) end);
  n
end function;

define method print-result-info
    (result :: <result>, stream :: <stream>, #key test) => ()
  if (~test | test(result))
    let reason = result.result-reason;
    let status = result.result-status;
    format(stream, "%s%s: %s%s\n",
           *indent*,
           status.status-name.as-uppercase,
           result.result-name,
           if (status == $passed & instance?(result, <metered-result>))
             format-to-string(" in %ss and %s",
                              result.result-time,
                              format-bytes(result.result-bytes))
           else
             ""
           end);
    if (reason)
      format(stream, "%s%s%s\n", *indent*, $indent-step, reason);
    end;
  end;
end method;

define method print-result-info
    (result :: <component-result>, stream :: <stream>, #key test) => ()
  next-method();
  dynamic-bind (*indent* = next-indent())
    for (subresult in result-subresults(result))
      print-result-info(subresult, stream, test: test)
    end;
  end;
end method;

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
    (result :: <benchmark-result>, stream :: <stream>, #key test) => ()
  if (~test | test(result))
    next-method();
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
      format(stream, "%s%s%d iterations, per iteration min %ss, mean %ss,"
               " median %ss, max %ss\n",
             *indent*, $indent-step, iteration-times.size,
             float-time-to-string(min-value),
             float-time-to-string(mean-value),
             float-time-to-string(median-value),
             float-time-to-string(max-value));
    end unless;
  end if;
end method;


/// Report functions

define method print-null-report
    (result :: <result>, stream :: <stream>) => ()
end;

// Example output:
//   Ran 437 tests with 4 expected failures and 117 not implemented
//   PASSED in 88.278782 seconds
define method print-summary-report
    (result :: <result>, stream :: <stream>) => ()
  local method pluralize (count :: <integer>) => (s :: <string>)
          if (count == 1) "" else "s" end
        end;
  let stream = colorize-stream(stream);
  let (_, failed, crashed, skipped, nyi, expected-failures)
    = count-results(result,
                    test: method (result)
                            instance?(result, <test-result>)
                              | instance?(result, <benchmark-result>)
                          end);
  let assertions = count-results-of-type(result, <check-result>);
  let benches = count-results-of-type(result, <benchmark-result>);
  let tests = count-results-of-type(result, <test-result>);
  let kinds = make(<stretchy-vector>);
  if (tests > 0)
    add!(kinds, format-to-string("%d test%s", tests, pluralize(tests)));
  end;
  if (benches > 0)
    add!(kinds, format-to-string("%d benchmark%s", benches, pluralize(benches)));
  end;
  let breakdown = make(<stretchy-vector>);
  if (crashed > 0)
    add!(breakdown, format-to-string("%d crashed", crashed));
  end;
  if (failed > 0)
    add!(breakdown, format-to-string("%d failed", failed));
  end;
  if (expected-failures > 0)
    add!(breakdown,
         format-to-string("%d expected failure%s",
                          expected-failures, pluralize(expected-failures)));
  end;
  if (nyi > 0)
    add!(breakdown, format-to-string("%d not implemented", nyi));
  end;
  if (skipped > 0)
    add!(breakdown, format-to-string("%d skipped", skipped));
  end;
  format(stream, "Ran %d assertion%s\n", assertions, pluralize(assertions));
  format(stream, "Ran %s", join(kinds, " and "));
  if (breakdown.size > 0)
    format(stream, ": %s", join(breakdown, ", ", conjunction: " and "));
  end;
  let status = result.result-status;
  format(stream, "\n%=%s%= in %s seconds\n",
         result-status-to-text-attributes(status),
         status.status-name.as-uppercase,
         $reset-text-attributes,
         result.result-time);
end method;

define method print-failures-report
    (result :: <result>, stream :: <stream>) => ()
  if (result.result-status ~= $passed)
    print-result-info(result, stream, test: compose(\~, result-passing?));
    format(stream, "\n");
  end;
  print-summary-report(result, stream);
end method;

define method print-full-report
    (result :: <result>, stream :: <stream>) => ()
  format(stream, "\n");
  print-result-info(result, stream, test: always(#t));
  print-summary-report(result, stream);
end method;


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

define method print-xml-report
    (result :: <result>, stream :: <stream>) => ()
  format(stream, "%s\n", $xml-version-header);
  do-xml-element("test-report",
                 method ()
                   format(stream, "\n");
                   do-xml-result(result, stream);
                 end,
                 stream);
end method;


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
      // If this test failed then we know at least one of the checks failed.
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

define function print-surefire-report
    (result :: <result>, stream :: <stream>) => ()
  format(stream, "%s\n", $xml-version-header);
  format(stream, "<testsuites>\n");
  do(rcurry(emit-surefire-suite, stream),
     collect-suite-results(result));
  format(stream, "</testsuites>\n");
end function;

/// JSON report

define function print-json-report (result :: <result>, stream :: <stream>) => ()
  print-json(result, stream, indent: 2);
end;

define method do-print-json (result :: <result>, stream :: <stream>)
  do-print-json(result-to-table(result), stream);
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
