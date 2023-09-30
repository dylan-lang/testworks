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


/// Summary generation

// Output lines like these, one per call. `kind` is "suite", "test", "benchmark", or "check".
//    Ran 1455 checks: 22 crashed 1 failed
//    Ran 37 tests: FAILED (1 crashed, 1 failed, 3 not implemented, 1 skipped, 1 expected failure)
define method print-result-summary
    (result :: <result>, kind :: <string>, stream :: <stream>,
     #key test = always(#t))
 => ()
  // Unexpected success is currently lumped in with failures.
  let (passed, failed, crashed, skipped, nyi, expected-failures)
    = count-results(result, test: test);
  let total = passed + failed + crashed + skipped + nyi + expected-failures;
  let did-paren? = #f;
  let did-comma? = #f;
  local method print-count (count, label, #key plural = "")
          if (count > 0)
            if (~did-paren?)
              did-paren? := #t;
              write(stream, " (");
            end;
            if (did-comma?)
              write(stream, ", ");
            end;
            format(stream, "%d %s%s", count, label, if (count = 1) "" else plural end);
            did-comma? := #t;
          end;
        end method;
  // "Ran 10 suites: " etc
  format(stream, "Ran %=%s%= %s%s:",
         $total-text-attributes,
         total,
         $reset-text-attributes,
         kind,
         if (total == 1) "" else "s" end);
  let passed? = crashed = 0 & failed = 0;
  if (passed?)
    format(stream, " %=PASSED%=", $passed-text-attributes, $reset-text-attributes);
  else
    format(stream, " %=FAILED%=", $failed-text-attributes, $reset-text-attributes);
  end;
  print-count(failed, "failed");
  print-count(crashed, "crashed");
  print-count(skipped, "skipped");
  print-count(nyi, "not implemented");
  print-count(expected-failures, "expected failure", plural: "s");
  if (did-paren?)
    write(stream, ")");
  end;
  write(stream, "\n");
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
    format(stream, "%s", reason);
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
    format(stream, "%s", reason);
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
  if (~test | test(result))
    let result-status = result.result-status;
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

define method print-null-report
    (result :: <result>, stream :: <stream>) => ()
end;

define method print-summary-report
    (result :: <result>, stream :: <stream>) => ()
  let stream = colorize-stream(stream);
  local method print-class-summary (result, name, class) => ()
          print-result-summary(result, name, stream, test: rcurry(instance?, class))
        end;
  write(stream, "\n");
  print-class-summary(result, "check", <check-result>);

  // The expectation is that tests and benchmarks should be in different
  // libraries so we try to print only one or the other here. If there are
  // neither tests nor benchmarks something is wrong so print both.
  let benches = count-results-of-type(result, <benchmark-result>);
  let tests = count-results-of-type(result, <test-result>);
  if (benches > 0 | tests = 0)
    print-class-summary(result, "benchmark", <benchmark-result>);
  end;
  if (tests > 0 | benches = 0)
    print-class-summary(result, "test", <test-result>);
  end;

  let result-status = result.result-status;
  format(stream, "%=%s%= in %s seconds\n",
         result-status-to-text-attributes(result-status),
         result-status.status-name.as-uppercase,
         $reset-text-attributes,
         result.result-time);
end method;

define method print-failures-report
    (result :: <result>, stream :: <stream>) => ()
  if (result.result-status ~= $passed)
    print-result-info (result, stream,
                       test: method (result)
                               let status = result.result-status;
                               status ~== $passed & status ~== $skipped
                             end);
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
