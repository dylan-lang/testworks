Module: %testworks
Synopsis: Utilities and code that needs to be loaded early.
Copyright: Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
           All rights reserved.
License: See License.txt in this distribution for details.
Warranty: Distributed WITHOUT WARRANTY OF ANY KIND


// The active test run object.
define thread variable *runner* :: false-or(<test-runner>) = #f;


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


define method plural
    (n :: <integer>) => (ending :: <string>)
  if (n == 1) "" else "s" end if
end;


define constant $all-tags = #[#"all"];

define method tags-match?
    (run-tags :: <sequence>, object-tags :: <sequence>)
 => (bool :: <boolean>)
  run-tags = $all-tags | ~empty?(intersection(run-tags, object-tags))
end method tags-match?;

