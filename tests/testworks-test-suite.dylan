Module:       testworks-test-suite
Summary:      A test suite to test the testworks harness
Author:       Andy Armstrong, James Kirsch, Shri Amit
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// Some utilities for testing TestWorks

// Given a function that runs exactly one assertion, run it as a test and
// return the assertion's result: $passed, $failed, etc.
define function do-with-result
    (thunk :: <function>) => (status :: <result>)
  let test = make(<test>,
                  name: "anonymous",
                  function: thunk);
  let result = run-tests(make(<test-runner>, progress: $progress-none),
                         test);
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

define test testworks-check-condition-test ()
  begin
    let success? = #f;
    assert-equal($passed,
                 with-result-status ()
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

define test testworks-assert-signals-test ()
  assert-signals(<error>, error("foo"));
  assert-signals(<error>, error("foo"), "error signals error w/ description");
  begin
    let success? = #f;
    assert-equal($passed,
                 with-result-status ()
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
               with-result-status ()
                 assert-signals(<test-error>, #f)
               end);
  assert-equal($failed,
               with-result-status ()
                 assert-signals(<test-error>, test-warning())
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
  let runner = make(<test-runner>, progress: $progress-none);
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
  let runner = make(<test-runner>, progress: $progress-none);
  let suite-results = run-tests(runner, suite-to-check);
  assert-true(instance?(suite-results, <suite-result>),
              "run-tests returns <suite-result> when running a <suite>");
  assert-equal($passed, suite-results.result-status,
               "run-tests returns $passed when passing");
  assert-true(instance?(suite-results.result-subresults, <vector>),
              "run-tests sub-results are in a vector");
end test test-run-tests/suite;

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
  let runner = make(<test-runner>, progress: $progress-none);

  let suite-results = run-tests(runner, expected-to-fail-suite);
  assert-equal($passed, suite-results.result-status,
               "expected-to-fail-suite should pass because all of its tests"
                 " fail and are expected to fail");

  let suite-results = run-tests(runner, unexpected-success-suite);
  assert-equal($failed, suite-results.result-status,
               "unexpected-success-suite should fail because its tests"
                 " pass but are expected to fail");
end test;

define test test-run-tests-expect-failure/test ()
  let runner = make(<test-runner>, progress: $progress-none);

  let test-results = run-tests(runner, test-expected-to-fail-always);
  assert-equal($expected-failure, test-results.result-status);

  let test-results = run-tests(runner, test-expected-to-fail-maybe);
  assert-equal($expected-failure, test-results.result-status);

  let test-results = run-tests(runner, test-unexpected-success);
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
  let runner = make(<test-runner>, progress: $progress-none);
  let result = run-tests(runner, suite);
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
  let runner = make(<test-runner>, progress: $progress-none);
  let result = run-tests(runner, suite);
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
  let result = run-tests(make(<test-runner>, progress: $progress-none),
                         test);
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
  check-description(method () assert-true(#t);            end, "#t is true");
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

/* Leaving this here because actually running these failing checks makes it
 much easier to debug, compared to running the above test, and there's more
 work to be done in this area so I expect to use these more.

define test test-assert-equal-output ()
  check-instance?("b", <string>, 1);
  check-true("d", 3 < 2);
  check-false("e", 3 == 3);
  check-condition("f", <error>, "no error");
  check-no-condition("g", error("foo"));
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
