Module:       testworks-test-suite
Summary:      A test suite to test the testworks harness
Author:       Andy Armstrong, James Kirsch, Shri Amit
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// Some utilities for testing TestWorks

define macro without-recording
  { without-recording () ?body:body end }
    => { let old-check-recording-function = *check-recording-function*;

         // This prevents default-handler(condition :: <warning>) from
         // outputting a message to stderr when these warnings are
         // signaled.
         let handler <test-warning> = always(#f);
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
  assert-equal(without-recording ()
                 check-true($internal-check-name, #t)
               end,
               $passed,
               "check-true(#t) passes");
  assert-equal(without-recording ()
                 check-true($internal-check-name, #f)
               end,
               $failed,
               "check-true(#f) fails");
  assert-equal(without-recording ()
                 check-true($internal-check-name, test-error())
               end,
               $crashed,
               "check-true of error crashes");
end test testworks-check-true-test;

define test testworks-assert-true-test ()
  assert-true(#t);
  assert-true(#t, "#t is true with description");
  assert-equal($passed, without-recording () assert-true(#t) end);
  assert-equal($failed, without-recording () assert-true(#f) end);
  assert-equal($crashed, without-recording () assert-true(test-error()) end);
end test testworks-assert-true-test;

define test testworks-check-false-test ()
  assert-equal(without-recording ()
                 check-false($internal-check-name, #t)
               end,
               $failed,
               "check-false(#t) fails");
  assert-equal(without-recording ()
                 check-false($internal-check-name, #f)
               end,
               $passed,
               "check-false(#f) passes");
  assert-equal(without-recording ()
                 check-false($internal-check-name, test-error())
               end,
               $crashed,
               "check-false of error crashes");
end test testworks-check-false-test;

define test testworks-assert-false-test ()
  assert-false(#f);
  assert-false(#f, "#f is false with description");
  assert-equal($failed, without-recording () assert-false(#t) end);
  assert-equal($passed, without-recording () assert-false(#f) end);
  assert-equal($crashed, without-recording () assert-false(test-error()) end);
end test testworks-assert-false-test;

define test testworks-check-equal-test ()
  assert-equal(without-recording ()
                 result-status(check-equal($internal-check-name, 1, 1))
               end,
               $passed,
               "check-equal(1, 1) passes");
  assert-equal(without-recording ()
                 result-status(check-equal($internal-check-name, "1", "1"))
               end,
               $passed,
               "check-equal(\"1\", \"1\") passes");
  assert-equal(without-recording ()
                 result-status(check-equal($internal-check-name, 1, 2))
               end,
               $failed,
               "check-equal(1, 2) fails");
  assert-equal(without-recording ()
                 result-status(check-equal($internal-check-name, 1, test-error()))
               end,
               $crashed,
               "check-equal of error crashes");
end test testworks-check-equal-test;

define test testworks-assert-equal-failure-detail ()
  let result = without-recording ()
                 assert-equal(#[1, 2, 3], #[1, 3, 2])
               end;
  let reason = result.result-reason;
  assert-true(reason & find-substring(reason, "element 1 is"));
end test testworks-assert-equal-failure-detail;


define test testworks-assert-equal-test ()
  assert-equal(8, 8);
  assert-equal(8, 8, "8 = 8 with description");
  assert-equal($passed, without-recording () result-status(assert-equal(1, 1)) end);
  assert-equal($passed, without-recording () result-status(assert-equal("1", "1")) end);
  assert-equal($failed, without-recording () result-status(assert-equal(1, 2)) end);
  assert-equal($crashed, without-recording ()
                           result-status(assert-equal(1, test-error()))
                         end);
end test testworks-assert-equal-test;

define test testworks-assert-not-equal-test ()
  assert-not-equal(8, 9);
  assert-not-equal(8, 9, "8 ~= 9 with description");
  assert-equal($passed, without-recording () result-status(assert-not-equal(1, 2)) end);
  assert-equal($passed, without-recording () result-status(assert-not-equal("1", "2")) end);
  assert-equal($failed, without-recording () result-status(assert-not-equal(1, 1)) end);
  assert-equal($crashed, without-recording ()
                           result-status(assert-not-equal(1, test-error()))
                         end);
end test testworks-assert-not-equal-test;

define test testworks-check-instance?-test ()
  assert-equal(without-recording ()
                 check-instance?($internal-check-name, <integer>, 1)
               end,
               $passed,
               "check-instance?(<integer>, 1) passes");
  assert-equal(without-recording ()
                 check-instance?($internal-check-name, <string>, 1)
               end,
               $failed,
               "check-instance?(<string>, 1) fails");
  assert-equal(without-recording ()
                 check-instance?($internal-check-name, <integer>, test-error())
               end,
               $crashed,
               "check-instance? of error crashes");
end test testworks-check-instance?-test;

define test testworks-assert-instance?-test ()
  assert-equal(without-recording ()
                 assert-instance?(1, <integer>)
               end,
               $passed,
               "assert-instance?(1, <integer>) passes");
  assert-equal(without-recording ()
                 assert-instance?(1, <string>)
               end,
               $failed,
               "assert-instance?(1, <string>) fails");
  assert-equal(without-recording ()
                 assert-instance?(test-error(), <integer>)
               end,
               $crashed,
               "assert-instance? of error crashes");
end test testworks-assert-instance?-test;

define test testworks-assert-not-instance?-test ()
  assert-equal(without-recording ()
                 assert-not-instance?(1, <string>)
               end,
               $passed,
               "assert-not-instance?(1, <string>) passes");
  assert-equal(without-recording ()
                 assert-not-instance?(1, <integer>)
               end,
               $failed,
               "assert-not-instance?(1, <integer>) fails");
  assert-equal(without-recording ()
                 assert-not-instance?(test-error(), <integer>)
               end,
               $crashed,
               "assert-not-instance? of error crashes");
end test testworks-assert-not-instance?-test;

define test testworks-check-condition-test ()
  begin
    let success? = #f;
    assert-equal($passed,
                 without-recording ()
                   check-condition($internal-check-name,
                                   <test-error>,
                                   begin
                                     // default-handler for <warning> returns #f
                                     test-warning();
                                     success? := #t;
                                     test-error()
                                   end)
                 end,
                 "check-condition catches <test-error>");
    assert-true(success?,
                "check-condition for <test-error> doesn't catch <warning>");
  end;
  assert-equal(without-recording ()
                 check-condition($internal-check-name, <test-error>, #f)
               end,
               $failed,
               "check-condition fails if no condition");
  assert-equal($failed,
               without-recording ()
                 check-condition($internal-check-name,
                                 <test-error>,
                                 test-warning());
               end,
               "check-condition doesn't catch wrong condition");
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
  assert-equal($passed,
               without-recording ()
                 check-no-errors($internal-check-name, #t)
               end,
               "check-no-errors of #t passes");
  assert-equal($passed,
               without-recording ()
                 check-no-errors($internal-check-name, #f)
               end,
               "check-no-errors of #f passes");
  assert-equal($crashed,
               without-recording ()
                 check-no-errors($internal-check-name, test-error())
               end,
               "check-no-errors of error crashes");
end test testworks-check-no-errors-test;

define test testworks-assert-no-errors-test ()
  assert-equal($passed, without-recording () assert-no-errors(#t) end);
  assert-equal($passed, without-recording () assert-no-errors(#f) end);
  assert-equal($crashed, without-recording () assert-no-errors(test-error()) end);
end test testworks-assert-no-errors-test;

define suite testworks-assertion-macros-suite ()
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
  test testworks-assert-equal-failure-detail;
  test testworks-assert-not-equal-test;
  test testworks-assert-instance?-test;
  test testworks-assert-not-instance?-test;
  test testworks-assert-signals-test;
  test testworks-assert-no-errors-test;
end suite testworks-assertion-macros-suite;


define benchmark basic-benchmark ()
  "just exercise basic benchmark functionality"
end;

define suite testworks-benchmarks-suite ()
  benchmark basic-benchmark;
end;


/// Verify the result objects

define test test-run-tests/test ()
  let runner = make(<test-runner>, progress: #f);
  let test-results = run-tests(runner, testworks-check-test);
  assert-true(instance?(test-results, <test-result>),
              "run-tests returns <test-result> when running a <test>");
  assert-equal($passed, test-results.result-status,
               "run-tests returns $passed when passing");
  assert-true(instance?(test-results.result-subresults, <vector>),
              "run-tests sub-results are in a vector");

  let bench-results = run-tests(runner, basic-benchmark);
  assert-true(instance?(bench-results, <benchmark-result>),
              "run-tests returns <benchmark-result> when running a <benchmark>");
end test test-run-tests/test;

define test test-run-tests/suite ()
  let suite-to-check = testworks-assertion-macros-suite;
  let runner = make(<test-runner>, progress: #f);
  let suite-results = run-tests(runner, suite-to-check);
  assert-true(instance?(suite-results, <suite-result>),
              "run-tests returns <suite-result> when running a <suite>");
  assert-equal($passed, suite-results.result-status,
               "run-tests returns $passed when passing");
  assert-true(instance?(suite-results.result-subresults, <vector>),
              "run-tests sub-results are in a vector");
end test test-run-tests/suite;

// This simply exercises the with-test-unit macro.  It'll catch
// compile time warnings at least, but doesn't actually verify
// anything else.
define test test-with-test-unit ()
  with-test-unit ("foo-unit")
    assert-equal(2, 2);
  end;
  with-test-unit ("bar-unit")
    assert-equal(3, 3);
  end;
end test test-with-test-unit;

define test test-expected-failure-always(expected-failure?: #t)
  assert-true(#f);
end test;

define test test-expected-failure-maybe(expected-failure?: method () #t end)
  assert-true(#f);
end test;

define test test-unexpected-success(expected-failure?: #t)
  assert-true(#t);
end test;

define suite expected-failure-suite ()
  test test-expected-failure-always;
  test test-expected-failure-maybe;
end suite;

define suite unexpected-success-suite ()
  test test-unexpected-success;
end suite;

define test test-run-tests-expect-failure/suite ()
  let suite-to-check = expected-failure-suite;
  let runner = make(<test-runner>, progress: #f);
  let suite-results = run-tests(runner, suite-to-check);
  assert-equal($passed, suite-results.result-status);

  let suite-to-check = unexpected-success-suite;
  let suite-results = run-tests(runner, suite-to-check);
  assert-equal($failed, suite-results.result-status);
end test test-run-tests-expect-failure/suite;

define test test-run-tests-expect-failure/test ()
  let test-to-check = test-expected-failure-always;
  let runner = make(<test-runner>, progress: #f);
  let test-results = run-tests(runner, test-to-check);
  assert-equal($expected-failure, test-results.result-status);

  let test-to-check = test-expected-failure-maybe;
  let test-results = run-tests(runner, test-to-check);
  assert-equal($expected-failure, test-results.result-status);

  let test-to-check = test-unexpected-success;
  let test-results = run-tests(runner, test-to-check);
  assert-equal($unexpected-success, test-results.result-status);
end test test-run-tests-expect-failure/test;

define suite testworks-results-suite ()
  test test-run-tests/suite;
  test test-run-tests/test;
  test test-run-tests-expect-failure/suite;
  test test-run-tests-expect-failure/test;
end;

// Make sure that if one assertion fails the remaining assertions
// are still executed.
define test test-assertion-failure-continue ()
  let x = #f;
  block ()
    without-recording ()
      assert-true(#f);            // fail
      assert-true(error("blah")); // fail
    end;
    assert-true(x := #t);
  cleanup
    assert-true(x);
  end;
end test test-assertion-failure-continue;

// Have one test that does a lot of assertions, which can affect the
// progress reports.
define test test-many-assertions (tags: #("verbose"))
  for (i from 1 to 1000)
    assert-true(#t);
  end;
end;

define test test-tags-match? ()
  let test-tags = parse-tags(#("foo", "bar", "baz"));
  let inputs = list(list(#t, #()),
                    list(#t, list("foo")),
                    list(#t, list("bar", "foo")),
                    list(#f, list("quux")),
                    list(#f, list("-foo")),
                    list(#f, list("foo", "-bar")),
                    list(#f, list("foo", "-bar", "baz")));
  for (input in inputs)
    let (match-expected?, input-strings) = apply(values, input);
    let requested-tags = parse-tags(input-strings);
    let test = make(<test>,
                    tags: test-tags,
                    name: "test",
                    function: method () end);
    assert-equal(match-expected?, tags-match?(requested-tags, test),
                 format-to-string("Requested tags: %=", requested-tags));
  end;
  assert-true(tags-match?(parse-tags(#("-verbose")),
                          make(<test>, tags: #(), name: "test", function: method() end)),
              "Negative tags match tests with no tags.");
  assert-false(tags-match?(parse-tags(#("verbose")),
                           make(<test>, tags: #(), name: "test", function: method() end)),
              "Positive tags do not match tests with no tags.");
end test test-tags-match?;

// Negated tags shouldn't be allowed in test definitions.
define test test-negative-tags-on-tests ()
  assert-signals(<error>, make(<test>, name: "t", tags: #("-foo"), function: method() end));
end;

define test test-make-test-converts-strings-to-tags ()
  let test = make(<test>, name: "t", tags: #("foo"), function: method() end);
  assert-true(every?(rcurry(instance?, <tag>), test.test-tags));
end;
