Module: testworks-test-suite
Synopsis: Tests for command-line.dylan


// Verify that command-line options create a <test-runner> correctly.
define test test-make-runner-from-command-line ()
  let args = list(list("--debug", debug-runner?, #t),
                  list("--debug=no", debug-runner?, #f),
                  list("--debug=crashes", debug-runner?, #"crashes"),
                  list("--debug=failures", debug-runner?, #t));
  let dummy-component = make(<suite>,
                             name: "Dummy",
                             description: "not used",
                             components: #());
  for (item in args)
    let (arg, getter, expected) = apply(values, item);
    let parser = parse-args(list(arg));
    let (_, runner, _) = make-runner-from-command-line(dummy-component, parser);
    let actual = getter(runner);
    check-equal(arg, expected, actual);
  end;
end test test-make-runner-from-command-line;

define suite command-line-test-suite ()
  test test-make-runner-from-command-line;
end;
