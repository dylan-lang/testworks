Module: testworks-test-suite

define interface-specification-suite testworks-interface-specification-test-suite ()
  function run-test-application (#"rest") => (false-or(<result>));
  function test-output (<string>, #"rest") => ();
  function test-temp-directory () => (false-or(<directory-locator>));
  open generic function check-equal-failure-detail (<object>, <object>) => (false-or(<string>));

  // For extending the runner capabilities.
  function debug-runner? (<test-runner>) => (<object>);
  function run-tests (<test-runner>, <component>) => (<component-result>);
  function runner-output-stream (<test-runner>) => (<stream>);
  function runner-progress (<test-runner>) => (one-of(#f, $default, $verbose));
  function runner-skip (<test-runner>) => (<sequence>);
  function runner-tags (<test-runner>) => (<sequence>);
  function test-option (<string>, #"key", #"default") => (<string>);
  open instantiable class <test-runner> (<object>);
end;

define suite testworks-test-suite ()
  suite testworks-interface-specification-test-suite;
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
end suite;
