Module: testworks-report-test-suite

define function string-parser (s) s end;

define test test-read-json-report ()
    let json-text = #:string:({"bytes":0,
                               "name":"suite-1.0",
                               "status":"passed", "reason":false, "seconds":0, "type":"test",
                               "microseconds":165,
                                 "children":
                                 [{"bytes":0,
                                   "name":"test-1.0",
                                   "children":
                                     [{"name":"check 1.0", "status":"passed", "reason":false, "type":"check"},
                                      {"name":"check 1.1", "status":"failed", "reason":false, "type":"check"}],
                                   "status":"passed", "reason":false, "seconds":0, "type":"test",
                                   "microseconds":166
                                     },
                                  {"bytes":0,
                                   "name":"test-1.1",
                                   "children":
                                     [{"name":"check 2.0", "status":"passed", "reason":false, "type":"check"},
                                      {"name":"check 2.1", "status":"passed", "reason":false, "type":"check"}],
                                   "status":"passed", "reason":false, "seconds":0, "type":"test",
                                   "microseconds":167
                                     }]});
  let stream = make(<string-stream>, contents: json-text);
  let result = read-json-report(stream, "/tmp/whatever");
  assert-equal(result.result-name, "suite-1.0");
  assert-equal(result.result-subresults.size, 2);
  assert-equal(result.result-subresults[0].result-name, "test-1.0");
  assert-equal(result.result-subresults[1].result-name, "test-1.1");
end;

run-test-application();
