Module:       %testworks
Summary:      Test result classes, APIs, and utilities directly related to them.
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND


define constant $passed = #"passed";
define constant $failed = #"failed";
define constant $crashed = #"crashed";
define constant $skipped = #"skipped";
define constant $expected-failure = #"expected-failure";
define constant $unexpected-success = #"unexpected-success";
define constant $not-implemented  = #"nyi";

define constant <result-status>
  = one-of($passed, $failed, $crashed, $skipped,
           $expected-failure, $unexpected-success,
           $not-implemented);

// It looks like this and testworks-reports:parse-status are meant to
// be inverses.  (This would be a good use for an <enum> class.)
define method status-name
    (status :: <result-status>) => (name :: <string>)
  select (status)
    $passed => "passed";
    $failed => "failed";
    $crashed => "crashed";
    $skipped => "skipped";
    $expected-failure => "failed as expected";
    $unexpected-success => "unexpectedly succeeded";
    $not-implemented => "not implemented";
    otherwise =>
      error("Unrecognized test result status: %=.  This is a testworks bug.",
            status);
  end
end method status-name;

define generic result-name   (result :: <result>) => (name :: <string>);
define generic result-status (result :: <result>) => (status :: <result-status>);
define generic result-reason (result :: <result>) => (reason :: false-or(<string>));

define class <result> (<object>)
  constant slot result-name :: <string>,
    required-init-keyword: name:;
  constant slot result-status :: <result-status>,
    required-init-keyword: status:;
  // This is #f if the test passed; otherwise a string.
  constant slot result-reason :: false-or(<string>) = #f,
    required-init-keyword: reason:;
end class <result>;

define generic result-seconds      (result :: <metered-result>) => (sec :: false-or(<integer>));
define generic result-microseconds (result :: <metered-result>) => (usec :: false-or(<integer>));
define generic result-bytes        (result :: <metered-result>) => (bytes :: false-or(<integer>));

define class <metered-result> (<result>)
  constant slot result-seconds :: false-or(<integer>),
    required-init-keyword: seconds:;
  constant slot result-microseconds :: false-or(<integer>),
    required-init-keyword: microseconds:;
  // Hopefully nothing will allocate more than 536MB haha...
  constant slot result-bytes :: false-or(<integer>),
    required-init-keyword: bytes:;
end class <metered-result>;

define generic result-subresults   (result :: <component-result>) => (subresults :: <sequence>);

define class <component-result> (<metered-result>)
  constant slot result-subresults :: <sequence> = make(<stretchy-vector>),
    init-keyword: subresults:;
end class <component-result>;

define class <test-result> (<component-result>)
end;

define class <suite-result> (<component-result>)
end;

define class <unit-result> (<result>)
end;

define class <check-result> (<unit-result>)
end;

define class <test-unit-result> (<test-result>, <unit-result>)
end;


// I believe this is for testworks-report.  --cgay
define method \=
    (result1 :: <result>, result2 :: <result>)
 => (equal? :: <boolean>)
  result1.result-name = result2.result-name
  & (result1.result-status = result2.result-status
     | result1.result-reason = result2.result-reason)
end;


define open generic result-type-name
    (result :: <result>) => (name :: <string>);

define method result-type-name
    (result :: <test-result>) => (name :: <string>)
  "test"
end;

define method result-type-name
    (result :: <suite-result>) => (name :: <string>)
  "suite"
end;

define method result-type-name
    (result :: <check-result>) => (name :: <string>)
  "check"
end;

define method result-type-name
    (result :: <test-unit-result>) => (name :: <string>)
  "test-unit"
end;


define method result-time
    (result :: <metered-result>, #key pad-seconds-to :: false-or(<integer>))
 => (seconds :: <string>)
  time-to-string(result.result-seconds, result.result-microseconds,
                 pad-seconds-to: pad-seconds-to)
end method result-time;

define function time-to-string
    (seconds :: false-or(<integer>), microseconds :: false-or(<integer>),
     #key pad-seconds-to :: false-or(<integer>))
 => (seconds :: <string>)
  if (seconds & microseconds)
    concatenate(integer-to-string(seconds, size: pad-seconds-to | 1, fill: ' '),
                ".",
                integer-to-string(microseconds, size: 6))
  else
    "N/A"
  end
end function time-to-string;

define function float-time-to-string
    (time :: <double-float>, #key pad-seconds-to :: false-or(<integer>))
 => (seconds :: <string>)
  let seconds = truncate(time);
  time-to-string(seconds, truncate((time - seconds) * 1.0d6),
                 pad-seconds-to: pad-seconds-to)
end;
