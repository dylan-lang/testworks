Module:       testworks-test-suite
Summary:      A test suite to test the testworks harness
Author:       Andy Armstrong, James Kirsch, Shri Amit
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// Some utilities for testing TestWorks

define function run-component (comp, #key components)
  if (~components)
    components := make(<stretchy-vector>);
    do-components(comp, curry(add!, components));
  end;
  let runner = make(<test-runner>,
                    components: components,
                    progress: $progress-none);
  run-tests(runner, comp)
end function;

// Given a function that runs exactly one assertion, run it as a test and
// return the assertion's result: $passed, $failed, etc.
define function do-with-result
    (thunk :: <function>) => (status :: <result>)
  let test = make(<test>,
                  name: "anonymous",
                  function: thunk);
  let result = run-component(test);
  let subresults = result.result-subresults;
  assert-equal(1, subresults.size,
               "assertion-status thunk had exactly one assertion?");
  subresults[0]
end function;

define macro with-result-status
    { with-result-status () ?:body end }
 => { let result = do-with-result(method () ?body end);
      result-status(result)
    }
end macro;

define macro with-result
    { with-result () ?:body end }
 => { do-with-result(method () ?body end) }
end macro;

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
  assert-equal($passed,
               with-result-status ()
                 check-true($internal-check-name, #t)
               end,
               "check-true(#t) passes");
  assert-equal($failed,
               with-result-status ()
                 check-true($internal-check-name, #f)
               end,
               "check-true(#f) fails");
  assert-equal($crashed,
               with-result-status ()
                 check-true($internal-check-name, test-error())
               end,
               "check-true of error crashes");
end test;

define test test-expect ()
  expect(always(#t));
  expect(identity(#t));
  expect(3 = 3);
  assert-equal($passed,
               with-result-status () expect(#t) end,
               "expect(#t) passes");
  assert-equal($failed,
               with-result-status () expect(#f) end,
               "expect(#f) fails");
  assert-equal($crashed,
               with-result-status () expect(test-error()) end,
               "expect of error crashes");
end test;

define test test-expect-true ()
  expect-true(always(#t));
  expect-true(identity(#t));
  expect-true(3 = 3);
  assert-equal($passed,
               with-result-status () expect-true(#t) end,
               "expect(#t) passes");
  assert-equal($failed,
               with-result-status () expect-true(#f) end,
               "expect(#f) fails");
  assert-equal($crashed,
               with-result-status () expect-true(test-error()) end,
               "expect of error crashes");
end test;

define test testworks-assert-true-test ()
  assert-true(#t);
  assert-true(#t, "#t is true with description");
  assert-equal($passed, with-result-status () assert-true(#t) end);
  assert-equal($failed, with-result-status () assert-true(#f) end);
  assert-equal($crashed, with-result-status () assert-true(test-error()) end);
end test;

define test testworks-check-false-test ()
  assert-equal($failed,
               with-result-status ()
                 check-false($internal-check-name, #t)
               end,
               "check-false(#t) fails");
  assert-equal($passed,
               with-result-status ()
                 check-false($internal-check-name, #f)
               end,
               "check-false(#f) passes");
  assert-equal($crashed,
               with-result-status ()
                 check-false($internal-check-name, test-error())
               end,
               "check-false of error crashes");
end test;

define test test-expect-false ()
  assert-equal($failed,
               with-result-status () expect-false(#t) end,
               "expect-false(#t) fails");
  assert-equal($passed,
               with-result-status () expect-false(#f) end,
               "expect-false(#f) passes");
  assert-equal($crashed,
               with-result-status () expect-false(test-error()) end,
               "expect-false of error crashes");
end test;

define test testworks-assert-false-test ()
  assert-false(#f);
  assert-false(#f, "#f is false with description");
  assert-equal($failed, with-result-status () assert-false(#t) end);
  assert-equal($passed, with-result-status () assert-false(#f) end);
  assert-equal($crashed, with-result-status () assert-false(test-error()) end);
end test;

define test testworks-check-equal-test ()
  assert-equal($passed,
               with-result-status ()
                 check-equal($internal-check-name, 1, 1)
               end,
               "check-equal(1, 1) passes");
  assert-equal($passed,
               with-result-status ()
                 check-equal($internal-check-name, "1", "1")
               end,
               "check-equal(\"1\", \"1\") passes");
  assert-equal($failed,
               with-result-status ()
                 check-equal($internal-check-name, 1, 2)
               end,
               "check-equal(1, 2) fails");
  assert-equal($crashed,
               with-result-status ()
                 check-equal($internal-check-name, 1, test-error())
               end,
               "check-equal of error crashes");
end test;

define test test-expect-equal ()
  assert-equal($passed,
               with-result-status () expect-equal(1, 1) end,
               "expect-equal(1, 1) passes");
  assert-equal($passed,
               with-result-status () expect-equal("1", "1") end,
               """expect-equal("1", "1") passes""");
  assert-equal($failed,
               with-result-status () expect-equal(1, 2) end,
               "expect-equal(1, 2) fails");
  assert-equal($crashed,
               with-result-status () expect-equal(1, test-error()) end,
               "expect-equal of error crashes");
end test;

define test testworks-assert-equal-failure-detail ()
  let result = with-result ()
                 assert-equal(#[1, 2, 3], #[1, 3, 2])
               end;
  let reason = result.result-reason;
  assert-true(reason & find-substring(reason, "element 1 is"));
end test;


define test testworks-assert-equal-test ()
  assert-equal(8, 8);
  assert-equal(8, 8, "8 = 8 with description");
  assert-equal($passed, with-result-status () assert-equal(1, 1) end);
  assert-equal($passed, with-result-status () assert-equal("1", "1") end);
  assert-equal($failed, with-result-status () assert-equal(1, 2) end);
  assert-equal($crashed, with-result-status () assert-equal(1, test-error()) end);
end test;

define test testworks-assert-not-equal-test ()
  assert-not-equal(8, 9);
  assert-not-equal(8, 9, "8 ~= 9 with description");
  assert-equal($passed, with-result-status () assert-not-equal(1, 2) end);
  assert-equal($passed, with-result-status () assert-not-equal("1", "2") end);
  assert-equal($failed, with-result-status () assert-not-equal(1, 1) end);
  assert-equal($crashed, with-result-status () assert-not-equal(1, test-error()) end);
end test;

define test test-expect-not-equal ()
  expect-not-equal(8, 9);
  expect-not-equal(8, 9, "8 ~= 9 with description");
  assert-equal($passed, with-result-status () expect-not-equal(1, 2) end);
  assert-equal($passed, with-result-status () expect-not-equal("1", "2") end);
  assert-equal($failed, with-result-status () expect-not-equal(1, 1) end);
  assert-equal($crashed, with-result-status () expect-not-equal(1, test-error()) end);
end test;

define test testworks-check-instance?-test ()
  assert-equal($passed,
               with-result-status ()
                 check-instance?($internal-check-name, <integer>, 1)
               end,
               "check-instance?(<integer>, 1) passes");
  assert-equal($failed,
               with-result-status ()
                 check-instance?($internal-check-name, <string>, 1)
               end,
               "check-instance?(<string>, 1) fails");
  assert-equal($crashed,
               with-result-status ()
                 check-instance?($internal-check-name, <integer>, test-error())
               end,
               "check-instance? of error crashes");
end test;

define test test-expect-instance? ()
  assert-equal($passed,
               with-result-status () expect-instance?(<integer>, 1) end,
               "expect-instance?(<integer>, 1) passes");
  assert-equal($failed,
               with-result-status () expect-instance?(<string>, 1) end,
               "expect-instance?(<string>, 1) fails");
  assert-equal($crashed,
               with-result-status ()
                 expect-instance?(<integer>, test-error())
               end,
               "expect-instance? of error crashes");
end test;

define test testworks-assert-instance?-test ()
  assert-equal($passed,
               with-result-status ()
                 assert-instance?(<integer>, 1)
               end,
               "assert-instance?(<integer>, 1) passes");
  assert-equal($failed,
               with-result-status ()
                 assert-instance?(<string>, 1)
               end,
               "assert-instance?(<string>, 1) fails");
  assert-equal($crashed,
               with-result-status ()
                 assert-instance?(<integer>, test-error())
               end,
               "assert-instance? of error crashes");
end test;

define test testworks-assert-not-instance?-test ()
  assert-equal($passed,
               with-result-status ()
                 assert-not-instance?(<string>, 1)
               end,
               "assert-not-instance?(<string>, 1) passes");
  assert-equal($failed,
               with-result-status ()
                 assert-not-instance?(<integer>, 1)
               end,
               "assert-not-instance?(<integer>, 1) fails");
  assert-equal($crashed,
               with-result-status ()
                 assert-not-instance?(<integer>, test-error())
               end,
               "assert-not-instance? of error crashes");
end test;

define test test-assert-not-instance? ()
  assert-equal($passed,
               with-result-status ()
                 expect-not-instance?(<string>, 1)
               end,
               "expect-not-instance?(<string>, 1) passes");
  assert-equal($failed,
               with-result-status ()
                 expect-not-instance?(<integer>, 1)
               end,
               "expect-not-instance?(<integer>, 1) fails");
  assert-equal($crashed,
               with-result-status ()
                 expect-not-instance?(<integer>, test-error())
               end,
               "expect-not-instance? of error crashes");
end test;

define test testworks-check-condition-test ()
  assert-equal($passed,
               with-result-status ()
                 check-condition($internal-check-name, <test-error>, test-error())
               end,
               "check-condition catches <test-error>");
  assert-equal($failed,
               with-result-status ()
                 check-condition($internal-check-name, <test-error>, #f)
               end,
               "check-condition fails if no condition");
  assert-equal($failed,
               with-result-status ()
                 check-condition($internal-check-name, <test-error>, test-warning())
               end,
               "check-condition doesn't catch wrong condition");
end test;

define test test-expect-condition ()
  assert-equal($passed,
               with-result-status ()
                 expect-condition(<test-error>, test-error())
               end,
               "expect-condition catches <test-error>");
  assert-equal($failed,
               with-result-status ()
                 expect-condition(<test-error>, #f)
               end,
               "expect-condition fails if no condition");
  assert-equal($failed,
               with-result-status ()
                 expect-condition(<test-error>, test-warning())
               end,
               "expect-condition doesn't catch wrong condition");
end test;

define test testworks-assert-condition-test ()
  assert-condition(<error>, error("foo"));
  assert-condition(<error>, error("foo"), "error signals error w/ description");
  assert-equal($passed,
               with-result-status ()
                 assert-condition(<test-error>, test-error())
               end);
  assert-equal($failed,
               with-result-status ()
                 assert-condition(<test-error>, #f)
               end);
  assert-equal($failed,
               with-result-status ()
                 assert-condition(<test-error>, test-warning())
               end);
end test;

define test testworks-check-no-errors-test ()
  assert-equal($passed,
               with-result-status ()
                 check-no-errors($internal-check-name, #t)
               end,
               "check-no-errors of #t passes");
  assert-equal($passed,
               with-result-status ()
                 check-no-errors($internal-check-name, #f)
               end,
               "check-no-errors of #f passes");
  assert-equal($crashed,
               with-result-status ()
                 check-no-errors($internal-check-name, test-error())
               end,
               "check-no-errors of error crashes");
end test;

define test testworks-assert-no-errors-test ()
  assert-equal($passed, with-result-status () assert-no-errors(#t) end);
  assert-equal($passed, with-result-status () assert-no-errors(#f) end);
  assert-equal($crashed, with-result-status () assert-no-errors(test-error()) end);
end test;

define test test-expect-no-condition ()
  assert-equal($passed, with-result-status () expect-no-condition(#t) end);
  assert-equal($passed, with-result-status () expect-no-condition(#f) end);
  assert-equal($crashed, with-result-status () expect-no-condition(test-error()) end);
end test;


define suite testworks-assertion-macros-suite ()
  test testworks-check-test;
  test testworks-check-true-test;
  test testworks-check-false-test;
  test testworks-check-equal-test;
  test testworks-check-instance?-test;
  test testworks-check-condition-test;
  test testworks-check-no-errors-test;

  test testworks-assert-true-test;
  test testworks-assert-false-test;
  test testworks-assert-equal-test;
  test testworks-assert-equal-failure-detail;
  test testworks-assert-not-equal-test;
  test testworks-assert-instance?-test;
  test testworks-assert-not-instance?-test;
  test testworks-assert-condition-test;
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
  let test-results = run-component(testworks-check-test);
  assert-true(instance?(test-results, <test-result>),
              "run-tests returns <test-result> when running a <test>");
  assert-equal($passed, test-results.result-status,
               "run-tests returns $passed when passing");
  assert-true(instance?(test-results.result-subresults, <vector>),
              "run-tests sub-results are in a vector");

  let bench-results = run-component(basic-benchmark);
  assert-true(instance?(bench-results, <benchmark-result>),
              "run-tests returns <benchmark-result> when running a <benchmark>");
end test test-run-tests/test;

define test test-run-tests/suite ()
  let suite-to-check = testworks-assertion-macros-suite;
  let suite-results = run-component(suite-to-check);
  assert-true(instance?(suite-results, <suite-result>),
              "run-tests returns <suite-result> when running a <suite>");
  assert-equal($passed, suite-results.result-status,
               "run-tests returns $passed when passing");
  assert-true(instance?(suite-results.result-subresults, <vector>),
              "run-tests sub-results are in a vector");
end test test-run-tests/suite;

define test test-run-tests/suite-setup-failure ()
  let suite
    = make-suite("setup-failure-suite",
                 vector(make(<test>,
                             name: "setup-failure-passing-test",
                             function: method () assert-true(#t) end)),
                 setup-function:
                   curry(error, "error in setup-failure-suite setup function"));
  let suite-result = run-component(suite);
  assert-equal($crashed, suite-result.result-status,
               "run-tests returns $crashed when suite setup fails");
  assert-equal(1, suite-result.result-subresults.size);
  let test-result = suite-result.result-subresults.first;
  assert-equal($skipped, test-result.result-status,
               "passing test skipped when suite setup fails")
end test;

define test test-run-tests/suite-cleanup-failure ()
  let suite
    = make(<suite>,
           name: "cleanup-failure-suite",
           components:
             vector(make(<test>,
                         name: "cleanup-failure-passing-test",
                         function: method () assert-true(#t) end)),
           cleanup-function:
             curry(error, "error in cleanup-failure-suite cleanup function"));
  let suite-result = run-component(suite);
  assert-equal($crashed, suite-result.result-status,
               "run-tests returns $crashed when suite cleanup fails");
  let test-result = suite-result.result-subresults.first;
  assert-equal($passed, test-result.result-status,
               "passing test passes when suite cleanup fails")
end test;

// Verify that if a specific test is requested on the command-line and that test is part
// of a suite with a setup function, the setup and cleanup are run.
define test test-suite-setup-for-specified-test ()
  let top-setup?       = #f;
  let top-cleanup?     = #f;
  let middle1-setup?   = #f;
  let middle1-cleanup? = #f;
  let middle2-setup?   = #f;
  let middle2-cleanup? = #f;
  let top
    = make-suite("top",
                 list(make-suite("middle1",
                                 list(make(<test>,
                                           name: "test1",
                                           function: method () assert-true(#t) end),
                                      make(<test>,
                                           name: "test2",
                                           function: curry(error, "test2 error"))),
                                 setup-function:   method () middle1-setup?   := #t end,
                                 cleanup-function: method () middle1-cleanup? := #t end),
                      make-suite("middle2",
                                 list(make(<test>,
                                           name: "test3",
                                           function: method () assert-true(#t) end)),
                                 setup-function:   method () middle2-setup?   := #t end,
                                 cleanup-function: method () middle2-cleanup? := #t end)),
                 setup-function: method () top-setup? := #t end,
                 cleanup-function: method () top-cleanup? := #t end);
  let result = run-component(top, components: compute-components(top, #[], #["test2"], #[]));
  expect(top-setup?);
  expect(top-cleanup?);
  expect(middle1-setup?);
  expect(middle1-cleanup?);
  expect(#f == middle2-setup?);
  expect(#f == middle2-cleanup?);
end test;

// The following tests and suites are defined without using their
// respective -definer macros so that they don't get registered and
// then run as normal tests (which would fail).

define constant test-expected-to-fail-always
  = make(<test>,
         name: "test-expected-to-fail-always",
         function: method () assert-true(#f) end,
         // Intentionally not passing `expected-to-fail-test:` here. The test
         // should be expected to fail because a reason is provided.
         expected-to-fail-reason: "because of assert-true(#f)");

define constant test-expected-to-fail-maybe
  = make(<test>,
         name: "test-expected-to-fail-maybe",
         function: method () assert-true(#f) end,
         expected-to-fail-test: method () #t end,
         expected-to-fail-reason: "because of assert-true(#f)");

define constant test-expected-to-crash-always
  = make(<test>,
         name: "test-expected-to-crash-always",
         function: curry(error, "test-expected-to-crash-always"),
         expected-to-fail-test: method () #t end,
         expected-to-fail-reason: "because of error(...)");

define constant expected-to-fail-suite
  = make(<suite>,
         name: "expected-to-fail-suite",
         components: vector(test-expected-to-fail-always,
                            test-expected-to-fail-maybe,
                            test-expected-to-crash-always));

define constant test-unexpected-success
  = make(<test>,
         name: "test-unexpected-success",
         function: method () assert-true(#t) end,
         expected-to-fail-test: always(#t),
         expected-to-fail-reason: "because of assert-true(#t)");

define constant unexpected-success-suite
  = make(<suite>,
         name: "unexpected-success-suite",
         components: vector(test-unexpected-success));

define test test-run-tests-expect-failure/suite ()
  assert-true(result-passing?(run-component(expected-to-fail-suite)),
              "expected-to-fail-suite should pass because all of its tests"
                " fail and are expected to fail");
  assert-false(result-passing?(run-component(unexpected-success-suite)),
               "unexpected-success-suite should fail because its tests"
                 " pass but are expected to fail");
end test;

define test test-run-tests-expect-failure/test ()
  let test-results = run-component(test-expected-to-fail-always);
  assert-equal($expected-failure, test-results.result-status);

  let test-results = run-component(test-expected-to-fail-maybe);
  assert-equal($expected-failure, test-results.result-status);

  let test-results = run-component(test-unexpected-success);
  assert-equal($unexpected-success, test-results.result-status);
  assert-true(find-substring(test-results.result-reason, "because of assert-true(#t)"));
end test;

define suite testworks-results-suite ()
  test test-run-tests/suite;
  test test-run-tests/test;
  test test-run-tests-expect-failure/suite;
  test test-run-tests-expect-failure/test;
end;

// Make sure that if one `check-*` expression fails the remaining assertions
// are still executed.
define test test-check-failure-continues ()
  let x = #f;
  block ()
    without-recording ()
      check-true($internal-check-name, #f);            // fail
      check-true($internal-check-name, error("blah")); // fail
    end;
    x := #t;
  cleanup
    assert-true(x);
  end;
end test;

// Make sure that if one `expect-*` expression fails the remaining assertions
// are still executed.
define test test-expect-failure-continues ()
  let x = #f;
  block ()
    without-recording ()
      expect(#f);            // fail
      expect(error("blah")); // fail
    end;
    x := #t;
  cleanup
    assert-true(x);
  end;
end test;

// Make sure that if one `assert-*` expression fails the rest of the test is
// NOT executed.
define test test-assertion-failure-terminates ()
  let x = #f;
  block ()
    without-recording ()
      assert-true(#f);
    end;
    x := #t;
  cleanup
    assert-false(x);
  end;
end test;

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

define test test-current-test ()
  assert-instance?(<test>, *component*);
end;

define benchmark test-current-benchmark ()
  assert-instance?(<benchmark>, *component*);
end;

define test test-test-temp-directory () // yes that's a lot of "test"
  let dir = test-temp-directory();
  assert-instance?(<directory-locator>, dir);
  assert-true(fs/file-exists?(dir));
end;

define test test-test-temp-directory/slash-replaced? ()
  let dir = test-temp-directory();
  assert-equal("test-test-temp-directory_slash-replaced?",
               locator-name(dir));
end;

define test test-write-test-file ()
  let x = write-test-file("x");
  assert-instance?(<file-locator>, x);
  assert-equal("x", locator-name(x));
  assert-equal("", fs/with-open-file (stream = x)
                     read-to-end(stream)
                   end);

  let y = write-test-file("y", contents: "abc");
  assert-equal("abc", fs/with-open-file (stream = y)
                        read-to-end(stream)
                      end);
end test;

define test test-register-component--duplicate-test-name-causes-error ()
  let n = size($components);
  let test = make(<test>, name: "t", function: method() end);
  assert-no-errors(register-component(test));
  assert-equal(size($components), n + 1);
  assert-signals(<error>, register-component(test));
  assert-equal(size($components), n + 1); // no change
  remove!($components, test);
  assert-equal(size($components), n);
end;

define test test-that-not-implemented-is-not-a-failure ()
  let test = make(<test>,
                  name: "not-implemented-test",
                  function: method () end);
  let suite = make(<suite>,
                   name: "not-implemented-suite",
                   components: vector(test));
  let result = run-component(suite);
  assert-equal($not-implemented, result.result-status);
end;

define test test-that-not-implemented-plus-passed-is-passed ()
  let test1 = make(<test>,
                   name: "not-implemented",
                   function: method () end);
  let test2 = make(<test>,
                   name: "passed",
                   function: method () assert-true(#t); end);
  let suite = make(<suite>,
                   name: "not-implemented-suite",
                   components: vector(test1, test2));
  let result = run-component(suite);
  assert-equal($passed, result.result-status);
end;

define test test-included-in-suite-multiple-times ()
  let test1 = make(<test>,
                   name: "tarantella",
                   function: always("tarantella"));
  let test2 = make(<test>,
                   name: "bach cello suites",
                   function: always("bach cello suites"));
  let benchmark1 = make(<benchmark>,
                        name: "initials",
                        function: always("initials"));
  assert-no-errors(make(<suite>,
                        name: "suite 1",
                        components: list(test1, test2, benchmark1)));
  // TODO(cgay): signal <testwork-error> throughout testworks code
  assert-signals(<error>,
                 make(<suite>,
                      name: "suite 2",
                      components: list(test1, test1)));
  assert-signals(<error>,
                 make(<suite>,
                      name: "suite 3",
                      components: list(test1, make(<suite>,
                                                   name: "suite 4",
                                                   components: list(test1)))));
end test;

define function check-description (test-function, want-string)
  let test = make(<test>,
                  name: "no name",
                  function: test-function);
  let result = run-component(test);
  let report = with-output-to-string (stream)
                 print-full-report(result, stream)
               end;
  check-true(format-to-string("find %= in %=", want-string, report),
             find-substring(report, want-string));
end function;

define test test-assertion-description ()
  // assert-equal
  check-description(method () assert-equal(#t, #t);            end, "#t = #t");
  check-description(method () assert-equal(#t, #t, 123);       end, "123");
  check-description(method () assert-equal(#t, #t, "abc");     end, "abc");
  check-description(method () assert-equal(#t, #t, "%d", 456); end, "456");

  // assert-true
  check-description(method () assert-true(#t);            end, "PASSED: #t");
  check-description(method () assert-true(#t, 123);       end, "123");
  check-description(method () assert-true(#t, "abc");     end, "abc");
  check-description(method () assert-true(#t, "%d", 456); end, "456");

  // assert-false
  check-description(method () assert-false(#f);            end, "#f evaluates to #f");
  check-description(method () assert-false(#f, 123);       end, "123");
  check-description(method () assert-false(#f, "abc");     end, "abc");
  check-description(method () assert-false(#f, "%d", 456); end, "456");

  // assert-instance?
  check-description(method ()
                      assert-instance?(<boolean>, #t);
                    end,
                    "#t is an instance of <boolean>");
  check-description(method ()
                      assert-instance?(<boolean>, #t, 123);
                    end,
                    "123");
  check-description(method ()
                      assert-instance?(<boolean>, #t, "abc");
                    end, "abc");
  check-description(method ()
                      assert-instance?(<boolean>, #t, "%d", 456);
                    end,
                    "456");

  // assert-signals
  check-description(method ()
                      assert-signals(<error>, error("x"));
                    end,
                    "signals condition <error>");
  check-description(method ()
                      assert-signals(<error>, error("x"), 123);
                    end,
                    "123");
  check-description(method ()
                      assert-signals(<error>, error("x"), "abc");
                    end,
                    "abc");
  check-description(method ()
                      assert-signals(<error>, error("x"), "%d", 456);
                    end,
                    "456");
end test;

define class <test-object> (<object>) end;

define test test-check-equal-failure-detail ()
  check-description(method ()
                      check-equal("list, same size, different elements",
                                  #("a", "b", "c", "d"),
                                  #("a", "b", "x", "d"));
                    end,
                    "element 2 is the first mismatch");
  check-description(method ()
                      check-equal("list, different sizes",
                                  #("a", "b", "c", "d"),
                                  #("a", "b", "c", "d", "e"));
                    end,
                    "sizes differ (4 and 5)");
  check-description(method ()
                      check-equal("integer, different", 123, 456);
                    end,
                    "want: 123"); // no detail in this case
  check-description(method ()
                      check-equal("table, same size, different elements",
                                  tabling(<string-table>, "a" => 1, "b" => 2, "c" => 3),
                                  tabling(<string-table>, "a" => 1, "x" => 2, "c" => 3));
                    end,
                    "table1 is missing keys \"x\"; table2"); // could be better
  check-description(method ()
                      check-equal("table, different sizes",
                                  tabling(<string-table>, "a" => 1, "b" => 2, "c" => 3),
                                  tabling(<string-table>, "a" => 1, "x" => 2, "c" => 3, "d" => 4));
                    end,
                    "table1 is missing keys"); // needs regex to match more
  check-description(method ()
                      check-equal("table, different typed keys and (unsortable) values",
                                  tabling(1 => 1, "b" => "b",
                                          make(<test-object>) => make(<test-object>)),
                                  tabling(1 => 1, "b" => "b", #() => #f));
                    end,
                    "table2 is missing keys {<test-object>");
  check-description(method ()
                      check-equal("string, same size different elements",
                                  "abcd", "axcd");
                    end,
                    "element 1 is the first mismatch");
  check-description(method ()
                      check-equal("string, different sizes",
                                  "abcd", "abcde");
                    end,
                    "sizes differ (4 and 5)");
end test;

define test test-decide-suite-status ()
  assert-equal($not-implemented, decide-suite-status(#[]));
  let v = vector;
  for (item in v(// First the simple one-subresult cases...
                 v($passed,  v($passed)),
                 v($failed,  v($failed)),
                 v($crashed, v($crashed)),
                 v($skipped, v($skipped)),
                 v($expected-failure,   v($expected-failure)),
                 v($unexpected-success, v($unexpected-success)),
                 v($not-implemented, v($not-implemented)),
                 // Now a few combinations...
                 v($failed, v($passed, $failed)),
                 v($failed, v($passed, $unexpected-success)),
                 v($passed, v($passed, $expected-failure, $skipped, $not-implemented)),
                 v($crashed, v($crashed, $failed)),
                 v($failed, v($unexpected-success, $failed))))
    let (expected-status, subresult-statuses)
      = apply(values, item);
    let subresults = map(method (status)
                           make(<result>,
                                status: status,
                                name: status-name(status))
                         end,
                         subresult-statuses);
    assert-equal(expected-status,
                 decide-suite-status(subresults),
                 format-to-string("%= == decide-suite-status(%=)",
                                  expected-status, subresult-statuses));
  end for;
end test;


define test test-component-test/suite ()
  let suite
    = make-suite("ct-suite",
                 list(make(<test>,
                           name: "ct-test",
                           function: method ()
                                       expect(#t);
                                     end)),
                 when: method ()
                         values(#f, "reason")
                       end);
  let result = run-component(suite);
  assert-equal($skipped, result.result-status);
  assert-equal("reason", result.result-reason);
  assert-equal(1, result.result-subresults.size);

  let test-result = result.result-subresults[0];
  assert-equal($skipped, test-result.result-status,
               "test skipped due to disabled suite");
  assert-equal("reason", test-result.result-reason,
               "test skipped due to disabled suite inherits the reason");
end test;

define test test-component-test/test ()
  let suite
    = make-suite("ct-suite2",
                 list(make(<test>,
                           name: "ct-test2",
                           function: method ()
                                       expect(#t);
                                     end,
                           when: method ()
                                   values(#f, "reason")
                                 end),
                      make(<test>,
                           name: "ct-test3",
                           function: method ()
                                       expect(#t);
                                     end)));
  let result = run-component(suite);
  assert-equal($passed, result.result-status);
  assert-false(result.result-reason);
  assert-equal(2, result.result-subresults.size);

  let test-result = result.result-subresults[0];
  assert-equal($skipped, test-result.result-status,
               "test skipped due to being disabled");
  assert-equal("reason", test-result.result-reason,
               "test result has non-#f reason due to being disabled");
end test;

// Make sure the when: keyword is exercised for each component type.
define test test-component-test-true (when: always(#t))
  expect(#t);
end test;

define test test-component-test-false (when: always(#f))
  expect(#f);
end test;

define benchmark component-test-benchmark (when: always(#f))
end;

define suite component-test-suite (when: always(#t))
  test test-component-test/suite;
  test test-component-test/test;
  test test-component-test-true;      // should be PASSED
  test test-component-test-false;     // should be SKIPPED
  benchmark component-test-benchmark; // should be SKIPPED
end suite;

/* Leaving this here because actually running these failing checks makes it
 much easier to debug, compared to running the above test, and there's more
 work to be done in this area so I expect to use these more.

define test test-assert-equal-output ()
  expect(2 > 3);
  expect-instance?(<string>, 1);
  expect-not-instance?(<string>, "b");
  expect-true(3 < 2);
  expect-false(3 == 3);
  expect-condition(<error>, "no error");
  expect-no-condition(error("foo"));
  check-equal("list, same size, different elements",
              #("a", "b", "c", "d"),
              #("a", "b", "x", "d"));
  check-equal("list, different sizes",
              #("a", "b", "c", "d"),
              #("a", "b", "c", "d", "e"));
  check-equal("integer, different",
              123, 456);
  let t1 = tabling(<string-table>, "a" => 1, "b" => 2, "c" => 3);
  let t2 = tabling(<string-table>, "a" => 1, "x" => 2, "c" => 3);
  check-equal("table, same size, different elements",
              t1, t2);
  let t1 = tabling(<string-table>, "a" => 1, "b" => 2, "c" => 3);
  let t2 = tabling(<string-table>, "a" => 1, "x" => 2, "c" => 3, "d" => 4);
  check-equal("table, different sizes",
              t1, t2);
  check-equal("string, same size different elements",
              "abcd", "axcd");
  check-equal("string, different sizes",
              "abcd", "abcde");
  check-equal("table, different typed keys and (unsortable) values",
              tabling(1 => 1, "b" => "b",
                      make(<test-object>) => make(<test-object>)),
              tabling("a" => 1, "x" => 2, "c" => 3));
end test;
*/

define test test-debug-option--crashes ()
  let crashing-test
    = make(<test>,
           name: "test-debug-option-1",
           function: curry(error, "error in test-debug-option-1"));
  let result-1 = #f;
  let runner-1 = make(<test-runner>,
                      components: list(crashing-test),
                      progress: $progress-none,
                      debug: $debug-none);
  assert-no-errors(result-1 := run-tests(runner-1, crashing-test),
                   "crashes are handled by default");
  assert-equal($crashed, result-1.result-status);

  let result-2 = #f;
  let runner-2 = make(<test-runner>,
                      components: list(crashing-test),
                      progress: $progress-none,
                      debug: $debug-crashes);
  assert-signals(<error>, result-2 := run-tests(runner-2, crashing-test),
                 "--debug crashes allows errors to escape");
  assert-equal(#f, result-2);
end test;

define test test-debug-option--failures ()
  let failing-test
    = make(<test>,
           name: "test-debug-option-2",
           function: method ()
                       assert-true(#f, "failed assertion in test-debug-option-2");
                     end);
  let result-1 = #f;
  let runner-1 = make(<test-runner>,
                      components: list(failing-test),
                      progress: $progress-none,
                      debug: $debug-none);
  assert-no-errors(result-1 := run-tests(runner-1, failing-test),
                   "failures are handled by default");
  assert-equal($failed, result-1.result-status);

  let result-2 = #f;
  let runner-2 = make(<test-runner>,
                      components: list(failing-test),
                      progress: $progress-none,
                      debug: $debug-failures);
  assert-signals(<assertion-failure>,
                 result-2 := run-tests(runner-2, failing-test),
                 "--debug failures signals <assertion-failure>");
  assert-equal(#f, result-2);
end test;

// https://github.com/dylan-lang/testworks/issues/183 --debug crashes should not cause
// assertions to act like expectations.
define test test-bug-183 ()
  let it = #f;
  let failing-test
    = make(<test>,
           name: "test-bug-183",
           function: method ()
                       assert-true(#f);
                       it := #t;
                     end);
  let runner = make(<test-runner>,
                    components: list(failing-test),
                    progress: $progress-none,
                    debug: $debug-crashes);
  let result = run-tests(runner, failing-test);
  assert-equal($failed, result.result-status);
  assert-false(it);
end test;
