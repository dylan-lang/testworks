Module: testworks-test-suite
Synopsis: Tests for command-line.dylan


define constant $dummy-suite = make(<suite>, name: "Dummy", components: #());

define test command-line-options-test ()
  let args = list(list("--debug=none", runner-debug, $debug-none, #f),
                  list("--debug=crashes", runner-debug, $debug-crashes, #f),
                  list("--debug=all", runner-debug, $debug-all, #f),
                  list("--debug=foo", runner-debug, $debug-none, #t),
                  list("--options key1 = val1 --options key2 = val2", runner-options,
                       begin
                         let t = make(<string-table>);
                         t["key1"] := "val1";
                         t["key2"] := "val2";
                         t
                       end,
                       #f),
                  list("key", runner-options, #f, #t)  // error, not key=val form
                  );
  for (item in args)
    let (options, getter, expected, expect-error?) = apply(values, item);
    // TODO(cgay): We should export something near system:os:application-arguments
    // that parses a string into command line arguments. This split call isn't very
    // accurate, but should work well enough for this test:
    if (expect-error?)
      assert-signals(<usage-error>,
                     begin
                       let parser = parse-args(split(options, " "));
                       make-runner-from-command-line($dummy-suite, parser);
                     end,
                     options);
    else
      let parser = parse-args(split(options, " "));
      let (_, runner, _) = make-runner-from-command-line($dummy-suite, parser);
      let actual = getter(runner);
      assert-equal(actual, expected, options);
    end;
  end;
end;

define suite command-line-test-suite ()
  test command-line-options-test;
end;
