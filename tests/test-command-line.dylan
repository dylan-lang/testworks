Module: testworks-test-suite
Synopsis: Tests for command-line.dylan


define test test-perform-options
    (description: "Verify that command-line options set "
       "'perform options' correctly.")
  let args = list(list("--debug", perform-debug?, #t),
                  list("--debug=no", perform-debug?, #f),
                  list("--debug=crashes", perform-debug?, #"crashes"),
                  list("--debug=failures", perform-debug?, #t));
  let dummy-component = make(<suite>,
                             name: "Dummy",
                             description: "not used",
                             components: #());
  for (item in args)
    let (arg, getter, expected) = apply(values, item);
    let parser = parse-args(list(arg));
    let (_, options, _)
      = compute-application-options(dummy-component, parser);
    let actual = getter(options);
    check-equal(arg, expected, actual);
  end;
end test test-perform-options;

define suite command-line-test-suite ()
  test test-perform-options;
end;
