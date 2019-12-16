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
end test;

// TODO: this needs some benchmark and iteration results
define constant $xml-report-text = #:string:{
<?xml version="1.0" encoding="ISO-8859-1"?>
<test-report>
  <suite>
    <name>testworks-results-suite</name>
    <status>passed</status>
    <seconds>0</seconds>
    <microseconds>1682</microseconds>
    <allocation>0</allocation>
    <test>
      <name>test-run-tests/suite</name>
      <status>passed</status>
      <seconds>0</seconds>
      <microseconds>1264</microseconds>
      <allocation>0</allocation>
      <check>
      <name>run-tests returns &lt;suite-result&gt; when running a &lt;suite&gt;</name>
      <status>passed</status>
      </check>
      <check>
      <name>run-tests returns $passed when passing</name>
      <status>passed</status>
      </check>
      <check>
      <name>run-tests sub-results are in a vector</name>
      <status>passed</status>
      </check>
    </test>
    <test>
      <name>test-run-tests-expect-failure/suite</name>
      <status>passed</status>
      <seconds>0</seconds>
      <microseconds>131</microseconds>
      <allocation>0</allocation>
      <check>
      <name>$passed = suite-results.result-status</name>
      <status>passed</status>
      </check>
      <check>
      <name>$failed = suite-results.result-status</name>
      <status>passed</status>
      </check>
    </test>
  </suite>
</test-report>
};

define test test-read-xml-report ()
  let stream = make(<string-stream>, contents: $xml-report-text);
  let result = read-xml-report(stream, "/tmp/whatever");
  assert-equal(result.result-name, "testworks-results-suite");
  assert-equal(result.result-subresults.size, 2);
  assert-equal(result.result-subresults[0].result-name, "test-run-tests/suite");
  assert-equal(result.result-subresults[1].result-name, "test-run-tests-expect-failure/suite");
end test;
