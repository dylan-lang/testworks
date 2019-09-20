Module: testworks-test-suite

define test test-$skipped ()
  //---*** Fill this in...
end;

define test test-result-microseconds ()
  //---*** Fill this in...
end;

define test test-<test-result> ()
  //---*** Fill this in...
end;

define test test-execute-component? ()
  //---*** Fill this in...
end;

define test test-result-time ()
  //---*** Fill this in...
end;

define test test-parse-tags ()
  //---*** Fill this in...
end;

define test test-summary-report-function ()
  //---*** Fill this in...
end;

define test test-debug? ()
  //---*** Fill this in...
end;

define test test-suite-cleanup-function ()
  //---*** Fill this in...
end;

define test test-<unit-result> ()
  //---*** Fill this in...
end;

define test test-result-seconds ()
  //---*** Fill this in...
end;

define test test-$xml-version-header ()
  //---*** Fill this in...
end;

define test test-status-name ()
  //---*** Fill this in...
end;

define test test-*check-recording-function* ()
  //---*** Fill this in...
end;

define test test-make-suite ()
  //---*** Fill this in...
end;

define test test-result-type-name ()
  //---*** Fill this in...
end;

define test test-<check-result> ()
  //---*** Fill this in...
end;

define test test-<test-unit> ()
  //---*** Fill this in...
end;

define test test-show-progress ()
  //---*** Fill this in...
end;

define test test-log-report-function ()
  //---*** Fill this in...
end;

define test test-<suite> ()
  //---*** Fill this in...
end;

define test test-null-report-function ()
  //---*** Fill this in...
end;

define test test-<component> ()
  //---*** Fill this in...
end;

define test test-failures-report-function ()
  //---*** Fill this in...
end;

define test test-xml-report-function ()
  //---*** Fill this in...
end;

define test test-<component-result> ()
  //---*** Fill this in...
end;

define test test-$not-implemented ()
  //---*** Fill this in...
end;

define test test-debug-failures? ()
  //---*** Fill this in...
end;

define test test-make-runner-from-command-line ()
  //---*** Fill this in...
end;

define test test-result-name ()
  //---*** Fill this in...
end;

define test test-$passed ()
  //---*** Fill this in...
end;

define test test-surefire-report-function ()
  //---*** Fill this in...
end;

define test test-suite-setup-function ()
  //---*** Fill this in...
end;

define test test-result-status ()
  //---*** Fill this in...
end;

define test test-result-bytes ()
  //---*** Fill this in...
end;

define test test-<suite-result> ()
  //---*** Fill this in...
end;

define test test-$crashed ()
  //---*** Fill this in...
end;

define test test-full-report-function ()
  //---*** Fill this in...
end;

define test test-$test-log-footer ()
  //---*** Fill this in...
end;

define test test-component-name ()
  //---*** Fill this in...
end;

define test test-do-results ()
  //---*** Fill this in...
end;

define test test-<test> ()
  //---*** Fill this in...
end;

define test test-<benchmark> ()
  //---*** Fill this in...
end;

define test test-<runnable> ()
  //---*** Fill this in...
end;

define test test-test-function ()
  //---*** Fill this in...
end;

define test test-$failed ()
  //---*** Fill this in...
end;

define test test-plural ()
  //---*** Fill this in...
end;

define test test-$default ()
  //---*** Fill this in...
end;

define test test-suite-components ()
  //---*** Fill this in...
end;

define test test-parse-args ()
  //---*** Fill this in...
end;

define test test-<test-unit-result> ()
  //---*** Fill this in...
end;

define test test-<tag> ()
  //---*** Fill this in...
end;

define test test-<result> ()
  //---*** Fill this in...
end;

define test test-test-tags ()
  //---*** Fill this in...
end;

define test test-$test-log-header ()
  //---*** Fill this in...
end;

define test test-$verbose ()
  //---*** Fill this in...
end;

define test test-result-reason ()
  //---*** Fill this in...
end;

define test test-result-subresults ()
  //---*** Fill this in...
end;

define test test-test-requires-assertions? ()
  //---*** Fill this in...
end;


// Module: testworks

define test test-assert-instance?-test ()
  //---*** Fill this in...
end;

define test test-check-instance?-test ()
  //---*** Fill this in...
end;

define test test-assert-not-instance?-test ()
  //---*** Fill this in...
end;

define test test-check-no-condition-test ()
  //---*** Fill this in...
end;

define test test-assert-equal-test ()
  //---*** Fill this in...
end;

define test test-check-no-errors-test ()
  //---*** Fill this in...
end;

define test test-run-test-application ()
  //---*** Fill this in...
end;

define test test-assert-not-equal-test ()
  //---*** Fill this in...
end;

define test test-<test-runner> ()
  //---*** Fill this in...
end;

define test test-check-equal-failure-detail ()
  //---*** Fill this in...
end;

define test test-run-tests ()
  //---*** Fill this in...
end;

define test test-assert-false-test ()
  //---*** Fill this in...
end;

define test test-assert-signals-test ()
  //---*** Fill this in...
end;

define test test-check-condition-test ()
  //---*** Fill this in...
end;

define test test-check-test ()
  //---*** Fill this in...
end;

define test test-suite-definer-test ()
  //---*** Fill this in...
end;

define test test-runner-skip ()
  //---*** Fill this in...
end;

define test test-test-output ()
  //---*** Fill this in...
end;

define test test-test-option ()
  check-instance?("test-option returns a <string>",
                  <string>,
                  test-option("foo", default: "bleah"));
end;

define test test-with-test-unit-test ()
  //---*** Fill this in...
end;

define test test-test-definer-test ()
  //---*** Fill this in...
end;

define test test-debug-runner? ()
  //---*** Fill this in...
end;

define test test-runner-output-stream ()
  //---*** Fill this in...
end;

define test test-check-false-test ()
  //---*** Fill this in...
end;

define test test-assert-no-errors-test ()
  //---*** Fill this in...
end;

define test test-assert-true-test ()
  //---*** Fill this in...
end;

define test test-runner-tags ()
  //---*** Fill this in...
end;

define test test-check-true-test ()
  //---*** Fill this in...
end;

define test test-runner-progress ()
  //---*** Fill this in...
end;

define test test-check-equal-test ()
  //---*** Fill this in...
end;

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
  function null-report-function (<result>, <stream>) => ();
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
  abstract class <runnable> (<component>);
  class <test> (<runnable>);
  class <benchmark> (<runnable>);
  function test-function (<runnable>) => (<function>);
  function test-requires-assertions? (<runnable>) => (<boolean>);
  constant $failed :: <object>;
  function plural (<integer>) => (<string>);
  constant $default :: <object>;
  function suite-components (<suite>) => (<sequence>);
  function parse-args (<sequence>) => (<command-line-parser>);
  class <test-unit-result> (<test-result>, <unit-result>);
  instantiable class <tag> (<object>);
  class <result> (<object>);
  function test-tags (<runnable>) => (<sequence>);
  constant $test-log-header :: <object>;
  constant $verbose :: <object>;
  function result-reason (<result>) => (false-or(<string>));
  function result-subresults (<component-result>) => (<sequence>);
end module-spec %testworks;

define module-spec testworks ()
  macro-test assert-instance?-test;
  macro-test check-instance?-test;
  macro-test assert-not-instance?-test;
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
  function test-option (<string>, #"key", #"default") => (<string>);
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

define library-spec testworks ()
  module %testworks;
  module testworks;

  suite testworks-assertion-macros-suite;
  suite testworks-results-suite;
  suite command-line-test-suite;
  suite testworks-benchmarks-suite;
  test test-with-test-unit;
  test test-assertion-failure-continue;
  test test-many-assertions;
  test test-tags-match?;
  test test-negative-tags-on-tests;
  test test-make-test-converts-strings-to-tags;
end library-spec testworks;
