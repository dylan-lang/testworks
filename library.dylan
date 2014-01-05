Module:       dylan-user
Synopsis:     TestWorks - a test harness library for dylan
Author:       Andrew Armstrong, James Kirsch
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define library testworks
  use command-line-parser;
  use common-dylan, import: { common-dylan, threads };
  use io, import: { format, print, standard-io, streams };
  use strings;
  use system, import: { file-system };

  export
    testworks,
    %testworks;
end library testworks;


// Public API
define module testworks

  // Top level and test runners
  create
    run-test-application,
    run-tests,
    <test-runner>,
    runner-tags,
    runner-skip,
    runner-output-stream,
    runner-progress,
    debug-runner?;

  // Checks (deprecated, use assertions)
  create
    check,
    check-condition,
    check-no-condition,
    check-equal,
    check-equal-failure-detail,
    check-false,
    check-no-errors,
    check-instance?,
    check-true;

  // Assertions
  create
    assert-equal,
    assert-not-equal,
    assert-signals,
    assert-no-errors,
    assert-true,
    assert-false;

  // Suites
  create
    suite-definer;

  // Tests
  create
    test-definer,
    with-test-unit;

  // Output
  create
    test-output;

end module testworks;


// Internals, for use by test suite.
define module %testworks
  use command-line-parser;
  use common-dylan, exclude: { format-to-string };
  use file-system;
  use format;
  use print, import: { print-object };
  use standard-io;
  use streams;
  use strings, import: { char-compare-ic, starts-with? };
  use testworks;
  use threads,
    import: { dynamic-bind };

  // Debugging options
  export
    debug-failures?,
    debug?;

  // Formatting
  export
    plural;

  // Components
  export
    <component>,
    execute-component?,
    component-name,
    status-name;

  // Tests
  export
    <test>,
    <test-unit>,
    test-function,
    find-test,
    test-tags;

  // Suites
  export
    <suite>,
    make-suite,   //--- Needed for macro hygiene problems
    suite-setup-function, suite-cleanup-function,
    suite-components,
    root-suite,
    find-suite;

  // Result objects
  export
    <result>,
    result-name,
    result-type-name,
    result-status,
      $passed, $failed, $skipped, $not-implemented, $crashed,
    result-seconds,
    result-microseconds,
    result-time,
    result-bytes,

    <component-result>,
    result-subresults,

    <test-result>,
    <suite-result>,
    <unit-result>,
    result-reason,
    do-results,

    <check-result>,
    <test-unit-result>;

  // Progress
  export
    show-progress,
    $default, $verbose;

  // Report functions
  export
    null-report-function,
    summary-report-function,
    failures-report-function,
    full-report-function,
    log-report-function,
    xml-report-function,
    surefire-report-function;

  // Command line handling
  export
    make-runner-from-command-line,
    parse-args;

  export
    $test-log-header,
    $test-log-footer,
    $xml-version-header,
    *check-recording-function*;

  // Tags
  export
    <tag>,
    parse-tags,
    tags-match?;
end module %testworks;
