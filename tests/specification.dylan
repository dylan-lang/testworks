Module: testworks-test-suite

// This spec is mainly here so that we exercise testworks-specs a bit.
// I'm not planning to try and fill in all the methods with "fill this
// in" below.  There are some notes on how these specs were originally
// generated.  They required some by-hand editing.

define module-spec %testworks ()
  constant $skipped :: <object>;
  // as generated:
  // function result-microseconds ({<component-result> in %testworks}) => (false-or(<integer>));
  function result-microseconds (<component-result>) => (false-or(<integer>));

  class <test-result> (<component-result>);
  open generic-function execute-component? (<component>, <test-runner>) => (<boolean>);
  function result-time (<component-result>, #"key", #"pad-seconds-to") => (<string>);
  function parse-tags (<sequence>) => (<sequence>);
  function summary-report-function (<result>, <stream>) => ();
  function debug? () => (<boolean>);
  // as generated:
  // function suite-cleanup-function ({<suite> in %testworks}) => (<function>);
  function suite-cleanup-function (<suite>) => (<function>);
  class <unit-result> (<result>);
  // as generated:
  // function result-seconds ({<component-result> in %testworks}) => (false-or(<integer>));
  function result-seconds (<component-result>) => (false-or(<integer>));
  function root-suite () => (<suite>);
  constant $xml-version-header :: <object>;
  function status-name (<result-status>) => (<string>);
  variable *check-recording-function* :: <object>;
  function make-suite (<string>, <object>, #"rest") => (<suite>);
  open generic-function result-type-name (<result>) => (<string>);
  class <check-result> (<unit-result>);
  class <test-unit> (<test>);
  function show-progress (<test-runner>, false-or(<component>), false-or(<result>)) => ();
  function log-report-function (<result>, <stream>) => ();
  class <suite> (<component>);
  function find-test (<string>, #"key", #"search-suite") => (false-or(<test>));
  function null-report-function (<result>, <stream>) => ();
  function find-suite (<string>, #"key", #"search-suite") => (false-or(<suite>));
  class <component> (<object>);
  function failures-report-function (<result>, <stream>) => ();
  function xml-report-function (<result>, <stream>) => ();
  class <component-result> (<result>);
  constant $not-implemented :: <object>;
  function debug-failures? () => (<boolean>);
  function make-runner-from-command-line (<component>, <command-line-parser>) => (<component>, <test-runner>, <function>);
  // as generated:
  // function result-name ({<result> in %testworks}) => (<string>);
  function result-name (<result>) => (<string>);
  function tags-match? (<sequence>, <component>) => (<boolean>);
  constant $passed :: <object>;
  function surefire-report-function (<result>, <stream>) => ();
  // as generated:
  // function suite-setup-function ({<suite> in %testworks}) => (<function>);
  function suite-setup-function (<suite>) => (<function>);
  function result-status (<result>) => (<result-status>);
  function result-bytes (<component-result>) => (false-or(<integer>));
  class <suite-result> (<component-result>);
  constant $crashed :: <object>;
  function full-report-function (<result>, <stream>) => ();
  constant $test-log-footer :: <object>;
  function component-name (<component>) => (<string>);
  function do-results (<object>, <object>) => (#"rest");
  class <test> (<component>);
  function test-function (<test>) => (<function>);
  constant $failed :: <object>;
  function plural (<integer>) => (<string>);
  constant $default :: <object>;
  function suite-components (<suite>) => (<sequence>);
  function parse-args (<sequence>) => (<command-line-parser>);
  class <test-unit-result> (<test-result>, <unit-result>);
  instantiable class <tag> (<object>);
  class <result> (<object>);
  function test-tags (<test>) => (<sequence>);
  constant $test-log-header :: <object>;
  constant $verbose :: <object>;
  function result-reason (<result>) => (false-or(<string>));
  function result-subresults (<component-result>) => (<sequence>);
end module-spec %testworks;

define module-spec testworks ()
  macro-test check-instance?-test;
  macro-test check-no-condition-test;
  macro-test assert-equal-test;
  macro-test check-no-errors-test;
  function run-test-application (<component>) => (false-or(<result>));
  macro-test assert-not-equal-test;
  // generated without "instantiable"
  open instantiable class <test-runner> (<object>);
  open generic-function check-equal-failure-detail (<object>, <object>) => (false-or(<string>));
  function run-tests (<test-runner>, <component>) => (<component-result>);
  macro-test assert-false-test;
  macro-test assert-signals-test;
  macro-test check-condition-test;
  macro-test check-test;
  macro-test suite-definer-test;
  function runner-skip (<test-runner>) => (<sequence>);
  function test-output (<string>, #"rest") => ();
  macro-test with-test-unit-test;
  macro-test test-definer-test;
  function debug-runner? (<test-runner>) => (<object>);
  function runner-output-stream (<test-runner>) => (<stream>);
  macro-test check-false-test;
  macro-test assert-no-errors-test;
  macro-test assert-true-test;
  function runner-tags (<test-runner>) => (<sequence>);
  macro-test check-true-test;
  function runner-progress (<test-runner>) => (one-of(#f, $default, $verbose));
  macro-test check-equal-test;
end module-spec testworks;

// Module: %testworks

define %testworks constant-test $skipped ()
  //---*** Fill this in...
end constant-test $skipped;

define %testworks function-test result-microseconds ()
  //---*** Fill this in...
end function-test result-microseconds;

define %testworks class-test <test-result> ()
  //---*** Fill this in...
end class-test <test-result>;

define %testworks function-test execute-component? ()
  //---*** Fill this in...
end function-test execute-component?;

define %testworks function-test result-time ()
  //---*** Fill this in...
end function-test result-time;

define %testworks function-test parse-tags ()
  //---*** Fill this in...
end function-test parse-tags;

define %testworks function-test summary-report-function ()
  //---*** Fill this in...
end function-test summary-report-function;

define %testworks function-test debug? ()
  //---*** Fill this in...
end function-test debug?;

define %testworks function-test suite-cleanup-function ()
  //---*** Fill this in...
end function-test suite-cleanup-function;

define %testworks class-test <unit-result> ()
  //---*** Fill this in...
end class-test <unit-result>;

define %testworks function-test result-seconds ()
  //---*** Fill this in...
end function-test result-seconds;

define %testworks function-test root-suite ()
  //---*** Fill this in...
end function-test root-suite;

define %testworks constant-test $xml-version-header ()
  //---*** Fill this in...
end constant-test $xml-version-header;

define %testworks function-test status-name ()
  //---*** Fill this in...
end function-test status-name;

define %testworks variable-test *check-recording-function* ()
  //---*** Fill this in...
end variable-test *check-recording-function*;

define %testworks function-test make-suite ()
  //---*** Fill this in...
end function-test make-suite;

define %testworks function-test result-type-name ()
  //---*** Fill this in...
end function-test result-type-name;

define %testworks class-test <check-result> ()
  //---*** Fill this in...
end class-test <check-result>;

define %testworks class-test <test-unit> ()
  //---*** Fill this in...
end class-test <test-unit>;

define %testworks function-test show-progress ()
  //---*** Fill this in...
end function-test show-progress;

define %testworks function-test log-report-function ()
  //---*** Fill this in...
end function-test log-report-function;

define %testworks class-test <suite> ()
  //---*** Fill this in...
end class-test <suite>;

define %testworks function-test find-test ()
  //---*** Fill this in...
end function-test find-test;

define %testworks function-test null-report-function ()
  //---*** Fill this in...
end function-test null-report-function;

define %testworks function-test find-suite ()
  //---*** Fill this in...
end function-test find-suite;

define %testworks class-test <component> ()
  //---*** Fill this in...
end class-test <component>;

define %testworks function-test failures-report-function ()
  //---*** Fill this in...
end function-test failures-report-function;

define %testworks function-test xml-report-function ()
  //---*** Fill this in...
end function-test xml-report-function;

define %testworks class-test <component-result> ()
  //---*** Fill this in...
end class-test <component-result>;

define %testworks constant-test $not-implemented ()
  //---*** Fill this in...
end constant-test $not-implemented;

define %testworks function-test debug-failures? ()
  //---*** Fill this in...
end function-test debug-failures?;

define %testworks function-test make-runner-from-command-line ()
  //---*** Fill this in...
end function-test make-runner-from-command-line;

define %testworks function-test result-name ()
  //---*** Fill this in...
end function-test result-name;

define %testworks function-test tags-match? ()
  //---*** Fill this in...
end function-test tags-match?;

define %testworks constant-test $passed ()
  //---*** Fill this in...
end constant-test $passed;

define %testworks function-test surefire-report-function ()
  //---*** Fill this in...
end function-test surefire-report-function;

define %testworks function-test suite-setup-function ()
  //---*** Fill this in...
end function-test suite-setup-function;

define %testworks function-test result-status ()
  //---*** Fill this in...
end function-test result-status;

define %testworks function-test result-bytes ()
  //---*** Fill this in...
end function-test result-bytes;

define %testworks class-test <suite-result> ()
  //---*** Fill this in...
end class-test <suite-result>;

define %testworks constant-test $crashed ()
  //---*** Fill this in...
end constant-test $crashed;

define %testworks function-test full-report-function ()
  //---*** Fill this in...
end function-test full-report-function;

define %testworks constant-test $test-log-footer ()
  //---*** Fill this in...
end constant-test $test-log-footer;

define %testworks function-test component-name ()
  //---*** Fill this in...
end function-test component-name;

define %testworks function-test do-results ()
  //---*** Fill this in...
end function-test do-results;

define %testworks class-test <test> ()
  //---*** Fill this in...
end class-test <test>;

define %testworks function-test test-function ()
  //---*** Fill this in...
end function-test test-function;

define %testworks constant-test $failed ()
  //---*** Fill this in...
end constant-test $failed;

define %testworks function-test plural ()
  //---*** Fill this in...
end function-test plural;

define %testworks constant-test $default ()
  //---*** Fill this in...
end constant-test $default;

define %testworks function-test suite-components ()
  //---*** Fill this in...
end function-test suite-components;

define %testworks function-test parse-args ()
  //---*** Fill this in...
end function-test parse-args;

define %testworks class-test <test-unit-result> ()
  //---*** Fill this in...
end class-test <test-unit-result>;

define %testworks class-test <tag> ()
  //---*** Fill this in...
end class-test <tag>;

define %testworks class-test <result> ()
  //---*** Fill this in...
end class-test <result>;

define %testworks function-test test-tags ()
  //---*** Fill this in...
end function-test test-tags;

define %testworks constant-test $test-log-header ()
  //---*** Fill this in...
end constant-test $test-log-header;

define %testworks constant-test $verbose ()
  //---*** Fill this in...
end constant-test $verbose;

define %testworks function-test result-reason ()
  //---*** Fill this in...
end function-test result-reason;

define %testworks function-test result-subresults ()
  //---*** Fill this in...
end function-test result-subresults;

// Module: testworks

define testworks macro-test check-instance?-test ()
  //---*** Fill this in...
end macro-test check-instance?-test;

define testworks macro-test check-no-condition-test ()
  //---*** Fill this in...
end macro-test check-no-condition-test;

define testworks macro-test assert-equal-test ()
  //---*** Fill this in...
end macro-test assert-equal-test;

define testworks macro-test check-no-errors-test ()
  //---*** Fill this in...
end macro-test check-no-errors-test;

define testworks function-test run-test-application ()
  //---*** Fill this in...
end function-test run-test-application;

define testworks macro-test assert-not-equal-test ()
  //---*** Fill this in...
end macro-test assert-not-equal-test;

define testworks class-test <test-runner> ()
  //---*** Fill this in...
end class-test <test-runner>;

define testworks function-test check-equal-failure-detail ()
  //---*** Fill this in...
end function-test check-equal-failure-detail;

define testworks function-test run-tests ()
  //---*** Fill this in...
end function-test run-tests;

define testworks macro-test assert-false-test ()
  //---*** Fill this in...
end macro-test assert-false-test;

define testworks macro-test assert-signals-test ()
  //---*** Fill this in...
end macro-test assert-signals-test;

define testworks macro-test check-condition-test ()
  //---*** Fill this in...
end macro-test check-condition-test;

define testworks macro-test check-test ()
  //---*** Fill this in...
end macro-test check-test;

define testworks macro-test suite-definer-test ()
  //---*** Fill this in...
end macro-test suite-definer-test;

define testworks function-test runner-skip ()
  //---*** Fill this in...
end function-test runner-skip;

define testworks function-test test-output ()
  //---*** Fill this in...
end function-test test-output;

define testworks macro-test with-test-unit-test ()
  //---*** Fill this in...
end macro-test with-test-unit-test;

define testworks macro-test test-definer-test ()
  //---*** Fill this in...
end macro-test test-definer-test;

define testworks function-test debug-runner? ()
  //---*** Fill this in...
end function-test debug-runner?;

define testworks function-test runner-output-stream ()
  //---*** Fill this in...
end function-test runner-output-stream;

define testworks macro-test check-false-test ()
  //---*** Fill this in...
end macro-test check-false-test;

define testworks macro-test assert-no-errors-test ()
  //---*** Fill this in...
end macro-test assert-no-errors-test;

define testworks macro-test assert-true-test ()
  //---*** Fill this in...
end macro-test assert-true-test;

define testworks function-test runner-tags ()
  //---*** Fill this in...
end function-test runner-tags;

define testworks macro-test check-true-test ()
  //---*** Fill this in...
end macro-test check-true-test;

define testworks function-test runner-progress ()
  //---*** Fill this in...
end function-test runner-progress;

define testworks macro-test check-equal-test ()
  //---*** Fill this in...
end macro-test check-equal-test;

define library-spec testworks ()
  module %testworks;
  module testworks;

  suite testworks-assertion-macros-suite;
  suite testworks-results-suite;
  suite command-line-test-suite;
  test test-with-test-unit;
  test test-assertion-failure-continue;
  test test-many-assertions;
  test test-tags-match?;
  test test-negative-tags-on-tests;
  test test-make-test-converts-strings-to-tags;
end library-spec testworks;
