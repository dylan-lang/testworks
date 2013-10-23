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
  use io, import: { format, standard-io, streams };
  use system, import: { file-system };

  export
    testworks,
    %testworks;
end library testworks;


// Public API
define module testworks

  // Top level
  create
    run-test-application;

  // Checks
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
    assert-signals,
    assert-no-errors,
    assert-true,
    assert-false;

  // Suites
  create
    perform-suite,
    suite-definer;

  // Tests
  create
    perform-test,
    test-definer,
    with-test-unit;

end module testworks;


// Internals, for use by test suite.
define module %testworks;
  use command-line-parser;
  use common-dylan, exclude: { format-to-string };
  use file-system;
  use format;
  use standard-io;
  use streams;
  use testworks;
  use threads,
    import: { dynamic-bind };

  // Debugging options
  export
    *debug?*,
    debug-failures?,
    debug?;

  // Formatting
  export
    test-output,
    *test-output*,
    plural;

  // Announcing suite/test/check names
  export
    *announce-checks?*,
    *announce-check-function*;

  // Components
  export
    <component>,
    execute-component?,
    perform-component,
    component-name,
    component-tags,
    status-name;

  // Perform options
  export
    <perform-options>,
    perform-tags, perform-tags-setter,
    perform-announce-function, perform-announce-function-setter,
    perform-announce-checks?, perform-announce-checks?-setter,
    perform-progress-function, perform-progress-function-setter,
    perform-debug?, perform-debug?-setter;

  // Tests
  export
    <test>,
    <test-unit>,
    test-function,
    find-test,
    find-test-object,
    test-function,
    find-test,
    find-test-object;

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

  // Progress functions
  export
    *default-progress-function*,
    null-progress-function,
    full-progress-function;

  // Report functions
  export
    *default-report-function*,
    null-report-function,
    summary-report-function,
    failures-report-function,
    full-report-function,
    log-report-function,
    xml-report-function,
    surefire-report-function;

  // Command line handling
  export
    compute-application-options,
    parse-args;

  export
    $test-log-header,
    $test-log-footer,
    $xml-version-header,
    *check-recording-function*;

  // Internals -- mostly due to macro hygiene failures
  export
    $test-objects-table,
    *test-unit-options*;
end module %testworks;
