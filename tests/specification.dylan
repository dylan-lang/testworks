Module: testworks-test-suite

define interface-specification-suite testworks-interface-specification-suite ()
  function run-test-application (#"rest") => ();
  function test-output (<string>, #"rest") => ();
  function test-temp-directory () => (false-or(<directory-locator>));
  open generic function check-equal-failure-detail (<object>, <object>) => (false-or(<string>));

  // For extending the runner capabilities.
  function run-tests (<test-runner>, <component>) => (<component-result>);
  function runner-debug         (<test-runner>) => (<debug-option>);
  function runner-output-stream (<test-runner>) => (<stream>);
  function runner-progress      (<test-runner>) => (<progress-option>);
  function runner-components    (<test-runner>) => (<collection>);
  function test-option (<string>, #"key", #"default") => (<string>);
  open instantiable class <test-runner> (<object>);
end;

define class <expected-to-fail-class> (<object>) end;
define variable *expected-to-fail-variable* = #t;
define constant $expected-to-fail-constant = #"etfc";
define function expected-to-fail-function () end;

define interface-specification-suite testworks-expected-to-fail-specification-suite ()
  variable *expected-to-fail-variable* :: <integer>,
    expected-to-fail-reason: "should be boolean";
  constant $expected-to-fail-constant :: <string>,
    expected-to-fail-reason: "should be symbol";
  instantiable class <expected-to-fail-class> (<integer>),
    expected-to-fail-reason: "should be object";
  function expected-to-fail-function (<object>) => (#"rest"),
    expected-to-fail-reason: "has no args";
end;

define suite testworks-test-suite ()
  suite testworks-interface-specification-suite;
  suite testworks-expected-to-fail-specification-suite;
  suite testworks-assertion-macros-suite;
  suite testworks-results-suite;
  suite command-line-test-suite;
  suite testworks-benchmarks-suite;
  test test-assertion-description;
  test test-assertion-failure-terminates;
  test test-check-failure-continues;
  test test-current-test;
  test test-included-in-suite-multiple-times;
  test test-make-test-converts-strings-to-tags;
  test test-many-assertions;
  test test-negative-tags-on-tests;
  test test-register-component--duplicate-test-name-causes-error;
  test test-tags-match?;
  test test-test-temp-directory;
  test test-that-not-implemented-is-not-a-failure;
  test test-that-not-implemented-plus-passed-is-passed;
end suite;
