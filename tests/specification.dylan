Module: testworks-test-suite

define test test-constant-$skipped ()
  //---*** Fill this in...
end;

define test test-function-result-microseconds ()
  //---*** Fill this in...
end;

define test test-class-<test-result> ()
  //---*** Fill this in...
end;

define test test-function-execute-component? ()
  //---*** Fill this in...
end;

define test test-function-result-time ()
  //---*** Fill this in...
end;

define test test-function-parse-tags ()
  //---*** Fill this in...
end;

define test test-function-summary-report-function ()
  //---*** Fill this in...
end;

define test test-function-debug? ()
  //---*** Fill this in...
end;

define test test-function-suite-cleanup-function ()
  //---*** Fill this in...
end;

define test test-class-<unit-result> ()
  //---*** Fill this in...
end;

define test test-function-result-seconds ()
  //---*** Fill this in...
end;

define test test-constant-$xml-version-header ()
  //---*** Fill this in...
end;

define test test-function-status-name ()
  //---*** Fill this in...
end;

define test test-variable-*check-recording-function* ()
  //---*** Fill this in...
end;

define test test-function-make-suite ()
  //---*** Fill this in...
end;

define test test-function-result-type-name ()
  //---*** Fill this in...
end;

define test test-class-<check-result> ()
  //---*** Fill this in...
end;

define test test-class-<test-unit> ()
  //---*** Fill this in...
end;

define test test-function-show-progress ()
  //---*** Fill this in...
end;

define test test-function-log-report-function ()
  //---*** Fill this in...
end;

define test test-class-<suite> ()
  //---*** Fill this in...
end;

define test test-function-null-report-function ()
  //---*** Fill this in...
end;

define test test-class-<component> ()
  //---*** Fill this in...
end;

define test test-function-failures-report-function ()
  //---*** Fill this in...
end;

define test test-function-xml-report-function ()
  //---*** Fill this in...
end;

define test test-class-<component-result> ()
  //---*** Fill this in...
end;

define test test-constant-$not-implemented ()
  //---*** Fill this in...
end;

define test test-function-debug-failures? ()
  //---*** Fill this in...
end;

define test test-function-make-runner-from-command-line ()
  //---*** Fill this in...
end;

define test test-function-result-name ()
  //---*** Fill this in...
end;

define test test-constant-$passed ()
  //---*** Fill this in...
end;

define test test-function-surefire-report-function ()
  //---*** Fill this in...
end;

define test test-function-suite-setup-function ()
  //---*** Fill this in...
end;

define test test-function-result-status ()
  //---*** Fill this in...
end;

define test test-function-result-bytes ()
  //---*** Fill this in...
end;

define test test-class-<suite-result> ()
  //---*** Fill this in...
end;

define test test-constant-$crashed ()
  //---*** Fill this in...
end;

define test test-function-full-report-function ()
  //---*** Fill this in...
end;

define test test-constant-$test-log-footer ()
  //---*** Fill this in...
end;

define test test-function-component-name ()
  //---*** Fill this in...
end;

define test test-function-do-results ()
  //---*** Fill this in...
end;

define test test-class-<test> ()
  //---*** Fill this in...
end;

define test test-class-<benchmark> ()
  //---*** Fill this in...
end;

define test test-class-<runnable> ()
  //---*** Fill this in...
end;

define test test-function-test-function ()
  //---*** Fill this in...
end;

define test test-constant-$failed ()
  //---*** Fill this in...
end;

define test test-function-plural ()
  //---*** Fill this in...
end;

define test test-constant-$default ()
  //---*** Fill this in...
end;

define test test-function-suite-components ()
  //---*** Fill this in...
end;

define test test-function-parse-args ()
  //---*** Fill this in...
end;

define test test-class-<test-unit-result> ()
  //---*** Fill this in...
end;

define test test-class-<tag> ()
  //---*** Fill this in...
end;

define test test-class-<result> ()
  //---*** Fill this in...
end;

define test test-function-tags-match? ()
  //---*** Fill this in...
end;

define test test-function-test-tags ()
  //---*** Fill this in...
end;

define test test-constant-$test-log-header ()
  //---*** Fill this in...
end;

define test test-constant-$verbose ()
  //---*** Fill this in...
end;

define test test-function-result-reason ()
  //---*** Fill this in...
end;

define test test-function-result-subresults ()
  //---*** Fill this in...
end;

define test test-function-test-requires-assertions? ()
  //---*** Fill this in...
end;


// Module: testworks

define test test-macro-assert-instance?-test ()
  //---*** Fill this in...
end;

define test test-macro-check-instance?-test ()
  //---*** Fill this in...
end;

define test test-macro-assert-not-instance?-test ()
  //---*** Fill this in...
end;

define test test-macro-check-no-condition-test ()
  //---*** Fill this in...
end;

define test test-macro-assert-equal-test ()
  //---*** Fill this in...
end;

define test test-macro-check-no-errors-test ()
  //---*** Fill this in...
end;

define test test-function-run-test-application ()
  //---*** Fill this in...
end;

define test test-macro-assert-not-equal-test ()
  //---*** Fill this in...
end;

define test test-class-<test-runner> ()
  //---*** Fill this in...
end;

define test test-function-check-equal-failure-detail ()
  //---*** Fill this in...
end;

define test test-function-run-tests ()
  //---*** Fill this in...
end;

define test test-macro-assert-false-test ()
  //---*** Fill this in...
end;

define test test-macro-assert-signals-test ()
  //---*** Fill this in...
end;

define test test-macro-check-condition-test ()
  //---*** Fill this in...
end;

define test test-macro-check-test ()
  //---*** Fill this in...
end;

define test test-macro-suite-definer-test ()
  //---*** Fill this in...
end;

define test test-function-runner-skip ()
  //---*** Fill this in...
end;

define test test-function-test-output ()
  //---*** Fill this in...
end;

define test test-function-test-option ()
  check-instance?("test-option returns a <string>",
                  <string>,
                  test-option("foo", default: "bleah"));
end;

define test test-macro-with-test-unit-test ()
  //---*** Fill this in...
end;

define test test-macro-test-definer-test ()
  //---*** Fill this in...
end;

define test test-function-debug-runner? ()
  //---*** Fill this in...
end;

define test test-function-runner-output-stream ()
  //---*** Fill this in...
end;

define test test-macro-check-false-test ()
  //---*** Fill this in...
end;

define test test-macro-assert-no-errors-test ()
  //---*** Fill this in...
end;

define test test-macro-assert-true-test ()
  //---*** Fill this in...
end;

define test test-function-runner-tags ()
  //---*** Fill this in...
end;

define test test-macro-check-true-test ()
  //---*** Fill this in...
end;

define test test-function-runner-progress ()
  //---*** Fill this in...
end;

define test test-macro-check-equal-test ()
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
