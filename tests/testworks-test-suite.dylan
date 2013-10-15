Module:       testworks-test-suite
Summary:      A test suite to test the testworks harness
Author:       Andy Armstrong, James Kirsch, Shri Amit
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// Some utilities for testing TestWorks

define macro with-debugging
  { with-debugging () ?body:body end }
    => { let old-debug? = *debug?*;
         block ()
           *debug?* := #t;
           ?body
         cleanup
           *debug?* := old-debug?;
         end }
end macro with-debugging;

define macro without-recording
  { without-recording () ?body:body end }
    => { let old-check-recording-function = *check-recording-function*;
         block ()
           *check-recording-function* := always(#t);
           ?body
         cleanup
           *check-recording-function* := old-check-recording-function
         end }
end macro without-recording;

define class <test-warning> (<warning>)
end class <test-warning>;

define function test-warning ()
  signal(make(<test-warning>, format-string: "internal test warning"))
end function test-warning;

define class <test-error> (<error>)
end class <test-error>;

define function test-error ()
  error(make(<test-error>, format-string: "internal test error"))
end function test-error;


/// Check macros testing

define constant $internal-check-name = "Internal check";

define test testworks-check-test ()
  check("check(always(#t))", always(#t));
  check("check(identity, #t)", identity, #t);
  check("check(\\=, 3, 3)", \=, 3, 3);
end test testworks-check-test;

define test testworks-check-true-test ()
  check-equal("check-true(#t) passes",
              without-recording ()
                check-true($internal-check-name, #t)
              end,
              $passed);
  check-equal("check-true(#f) fails",
              without-recording ()
                check-true($internal-check-name, #f)
              end,
              $failed);
  check-equal("check-true of error crashes",
              without-recording ()
                check-true($internal-check-name, test-error())
              end,
              $crashed);
end test testworks-check-true-test;

define test testworks-assert-true-test ()
  assert-true(#t);
  assert-true(#t, "#t is true with description");
  assert-equal($passed, without-recording () assert-true(#t) end);
  assert-equal($failed, without-recording () assert-true(#f) end);
  assert-equal($crashed, without-recording () assert-true(test-error()) end);
end test testworks-assert-true-test;

define test testworks-check-false-test ()
  check-equal("check-false(#t) fails",
              without-recording ()
                check-false($internal-check-name, #t)
              end,
              $failed);
  check-equal("check-false(#f) passes",
              without-recording ()
                check-false($internal-check-name, #f)
              end,
              $passed);
  check-equal("check-false of error crashes",
              without-recording ()
                check-false($internal-check-name, test-error())
              end,
              $crashed);
end test testworks-check-false-test;

define test testworks-assert-false-test ()
  assert-false(#f);
  assert-false(#f, "#f is false with description");
  assert-equal($failed, without-recording () assert-false(#t) end);
  assert-equal($passed, without-recording () assert-false(#f) end);
  assert-equal($crashed, without-recording () assert-false(test-error()) end);
end test testworks-assert-false-test;

define test testworks-check-equal-test ()
  check-equal("check-equal(1, 1) passes",
              without-recording ()
                check-equal($internal-check-name, 1, 1)
              end,
              $passed);
  check-equal("check-equal(\"1\", \"1\") passes",
              without-recording ()
                check-equal($internal-check-name, "1", "1")
              end,
              $passed);
  check-equal("check-equal(1, 2) fails",
              without-recording ()
                check-equal($internal-check-name, 1, 2)
              end,
              $failed);
  check-equal("check-equal of error crashes",
              without-recording ()
                check-equal($internal-check-name, 1, test-error())
              end,
              $crashed);
end test testworks-check-equal-test;

define test testworks-assert-equal-test ()
  assert-equal(8, 8);
  assert-equal(8, 8, "8 = 8 with description");
  assert-equal($passed, without-recording () assert-equal(1, 1) end);
  assert-equal($passed, without-recording () assert-equal("1", "1") end);
  assert-equal($failed, without-recording () assert-equal(1, 2) end);
  assert-equal($crashed, without-recording () assert-equal(1, test-error()) end);
end test testworks-assert-equal-test;

define test testworks-check-instance?-test ()
  check-equal("check-instance?(1, <integer>) passes",
              without-recording ()
                check-instance?($internal-check-name, <integer>, 1)
              end,
              $passed);
  check-equal("check-instance?(1, <string>) fails",
              without-recording ()
                check-instance?($internal-check-name, <string>, 1)
              end,
              $failed);
  check-equal("check-instance? of error crashes",
              without-recording ()
                check-instance?($internal-check-name,
                                <integer>,
                                test-error())
              end,
              $crashed);
end test testworks-check-instance?-test;

define test testworks-check-condition-test ()
  begin
    let success? = #f;
    check-equal("check-condition catches <test-error>",
                $passed,
                without-recording ()
                  check-condition($internal-check-name,
                                  <test-error>,
                                  begin
                                    // default-handler for <warning> returns #f
                                    test-warning();
                                    success? := #t;
                                    test-error()
                                  end)
                end);
    check-true("check-condition for <test-error> doesn't catch <warning>",
               success?);
  end;
  check-equal("check-condition fails if no condition",
              without-recording ()
                check-condition($internal-check-name,
                                <test-error>,
                                #f)
              end,
              $failed);
  check-equal("check-condition doesn't catch wrong condition",
              $failed,
              without-recording ()
                check-condition($internal-check-name,
                                <test-error>,
                                test-warning());
              end);
end test testworks-check-condition-test;

define test testworks-assert-signals-test ()
  assert-signals(<error>, error("foo"));
  assert-signals(<error>, error("foo"), "error signals error w/ description");
  begin
    let success? = #f;
    assert-equal($passed,
                 without-recording ()
                  assert-signals(<test-error>,
                                 begin
                                   // default-handler for <warning> returns #f
                                   test-warning();
                                   success? := #t;
                                   test-error()
                                 end)
                 end);
    assert-true(success?);
  end;
  assert-equal($failed,
               without-recording ()
                 assert-signals(<test-error>, #f)
               end);
  assert-equal($failed,
               without-recording ()
                 assert-signals(<test-error>, test-warning());
               end);
end test testworks-assert-signals-test;

define test testworks-check-no-errors-test ()
  check-equal("check-no-errors of #t passes",
              without-recording ()
                check-no-errors($internal-check-name, #t)
              end,
              $passed);
  check-equal("check-no-errors of #f passes",
              without-recording ()
                check-no-errors($internal-check-name, #f)
              end,
              $passed);
  check-equal("check-no-errors of error crashes",
              $crashed,
              without-recording ()
                check-no-errors($internal-check-name, test-error())
              end);
end test testworks-check-no-errors-test;

define test testworks-assert-no-errors-test ()
  assert-equal($passed, without-recording () assert-no-errors(#t) end);
  assert-equal($passed, without-recording () assert-no-errors(#f) end);
  assert-equal($crashed, without-recording () assert-no-errors(test-error()) end);
end test testworks-assert-no-errors-test;

define suite testworks-check-macros-suite ()
  test testworks-check-test;
  test testworks-check-true-test;
  test testworks-check-false-test;
  test testworks-check-equal-test;
  test testworks-check-instance?-test;
  test testworks-check-condition-test;
  test testworks-check-no-errors-test;

  // Assert macros (newer).
  test testworks-assert-true-test;
  test testworks-assert-false-test;
  test testworks-assert-equal-test;
  test testworks-assert-signals-test;
  test testworks-assert-no-errors-test;
end suite testworks-check-macros-suite;



/// Verify the result objects

define test testworks-perform-test-results-test ()
  let test-to-check = testworks-check-test;
  let test-results
    = perform-test(test-to-check,
                   progress-function: #f,
                   report-function: #f,
                   announce-function: #f);
  check-true("perform-test returns <test-result>",
             instance?(test-results, <test-result>));
  check-equal("perform-test returns $passed when passing",
              test-results.result-status, $passed);
  check-true("perform-test sub-results are in a vector",
             instance?(test-results.result-subresults, <vector>))
end test testworks-perform-test-results-test;

define test testworks-perform-suite-results-test ()
  let suite-to-check = testworks-check-macros-suite;
  let suite-results
    = perform-suite(suite-to-check, progress-function: #f, report-function: #f);
  check-true("perform-suite returns <suite-result>",
             instance?(suite-results, <suite-result>));
  check-equal("perform-suite returns $passed when passing",
              suite-results.result-status, $passed);
  check-true("perform-suite sub-results are in a vector",
             instance?(suite-results.result-subresults, <vector>))
end test testworks-perform-suite-results-test;

define suite testworks-results-suite ()
  test testworks-perform-test-results-test;
  test testworks-perform-suite-results-test;
end suite testworks-results-suite;


/// The master suite

define suite testworks-test-suite ()
  suite testworks-check-macros-suite;
  suite testworks-results-suite;
  suite command-line-test-suite;
end suite testworks-test-suite;
