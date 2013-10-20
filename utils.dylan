Module: testworks
Synopsis: Utilities and code that needs to be loaded early.
Copyright: Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
           All rights reserved.
License: See License.txt in this distribution for details.
Warranty: Distributed WITHOUT WARRANTY OF ANY KIND


define thread variable *debug?* = #f;

// The stream on which output is done.  Note that this may be bound to
// different streams during the test run and when the report is
// generated.  e.g., to output the report to a file.
define thread variable *test-output* :: <stream> = *standard-output*;

define thread variable *announce-checks?* :: <boolean> = #f;

define thread variable *announce-check-function* :: false-or(<function>) = #f;

define thread variable *announce-function* :: false-or(<function>) = method (c) end;


define function add-times
    (sec1 :: <integer>, usec1 :: <integer>, sec2 :: <integer>, usec2 :: <integer>)
 => (sec :: <integer>, usec :: <integer>)
  let sec = sec1 + sec2;
  let usec = usec1 + usec2;
  if (usec >= 1000000)
    usec := usec - 1000000;
    sec1 := sec1 + 1;
  end if;
  values(sec, usec)
end function add-times;
