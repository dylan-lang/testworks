Module:       %testworks
Synopsis:     Testworks testing harness
Author:       Andrew Armstrong, James Kirsch
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define constant $invalid-description = "*** invalid description ***";

// This is used to do a non-local exit to the end of a test and skip remaining assertions.
define class <assertion-failure> (<condition>) end;

/// Assertion macros

// The check-* macros are non-terminating, require the caller to provide a
// name, and are DEPRECATED. Use expect-* instead in new code.
//
// The expect-* macros are non-terminating and auto-generate a description if
// none is provided.
//
// The assert-* macros are terminating (they cause the remainder of a test to
// be skipped when they fail) and they auto-generate a description by default.

// Note that these macros wrap up the real macro arguments inside
// methods to delay their evaluation until they are within the scope
// of whatever condition handling is required.

define function eval-check-description
    (thunk :: <function>) => (description :: <string>)
  let (description, #rest args) = thunk();
  if (empty?(args))
    format-to-string("%s", description)
  else
    apply(format-to-string, description, args)
  end
end function;

// Deprecated; use expect.
define macro check
    { check(?description:expression, ?fun:expression, ?args:*) }
 => { expect(?fun(?args), ?description) }
end macro;

define macro expect
    { expect(?expr:expression) }
 => { expect(?expr, ?"expr" " is true") }

    { expect(?expr:expression, ?description:*) }
 => { do-check-true(method () values(?description) end,
                    method () values(?expr, ?"expr") end,
                    "expect",
                    terminate?: #f)
  }
end macro;

// This is for symmetry with expect-false. Usually expect is preferred.
define macro expect-true
    { expect-true(?expr:expression) }
 => { expect-true(?expr, ?"expr" " is true") }

    { expect-true(?expr:expression, ?description:*) }
 => { do-check-true(method () values(?description) end,
                    method () values(?expr, ?"expr") end,
                    "expect",
                    terminate?: #f)
  }
end macro;

// Deprecated; use expect-equal.
define macro check-equal
    { check-equal(?description:expression, ?want:expression, ?got:expression) }
 => { expect-equal(?want, ?got, ?description) }
end macro;

define macro assert-equal
  { assert-equal (?want:expression, ?got:expression)
  } => {
    assert-equal(?want, ?got, ?"want" " = " ?"got")
  }
  { assert-equal (?want:expression, ?got:expression, ?description:*)
  } => {
    do-check-equal(method () values(?description) end,
                   method ()
                     values(?want, ?got, ?"want", ?"got")
                   end,
                   "assert-equal",
                   terminate?: #t)
  }
end macro assert-equal;

define macro expect-equal
    { expect-equal(?want:expression, ?got:expression) }
 => { expect-equal(?want, ?got, ?"want" " = " ?"got") }

    { expect-equal(?want:expression, ?got:expression, ?description:*) }
 => { do-check-equal(method () values(?description) end,
                     method () values(?want, ?got, ?"want", ?"got") end,
                     "expect-equal",
                     terminate?: #f) }
end macro;

define function do-check-equal
    (description-thunk :: <function>, arguments-thunk :: <function>, caller :: <string>,
     #key terminate? :: <boolean>)
 => ()
  let phase = format-to-string("evaluating %s description", caller);
  let description :: false-or(<string>) = #f;
  block ()
    description := eval-check-description(description-thunk);
    phase := format-to-string("evaluating %s expressions", caller);
    let (want, got, want-expr, got-expr) = arguments-thunk();
    phase := format-to-string("while comparing %s and %s for equality",
                              want-expr, got-expr);
    if (want = got)
      record-check(description, $passed, #f);
    else
      phase := format-to-string("getting %s failure detail", caller);
      let detail = check-equal-failure-detail(want, got);
      let detail = if (detail)
                     format-to-string("\n%s%sdetail: %s",
                                      *indent*, $indent-step, detail)
                   else
                     ""
                   end;
      record-check(description, $failed,
                   format-to-string("want: %=\n%s%sgot:  %=%s",
                                    want, *indent*, $indent-step, got, detail));
      terminate? & signal(make(<assertion-failure>));
    end;
  exception (err :: <serious-condition>, test: method (cond) ~debug?() end)
    record-check(description | $invalid-description,
                 $crashed,
                 format-to-string("Error %s: %s", phase, err));
    terminate? & signal(make(<assertion-failure>));
  end block
end function;

define macro expect-not-equal
    { expect-not-equal(?expr1:expression, ?expr2:expression) }
 => { expect-not-equal(?expr1, ?expr2, ?"expr1" " ~= " ?"expr2") }

    { expect-not-equal(?expr1:expression, ?expr2:expression, ?description:*) }
 => { do-check-not-equal(method () values(?description) end,
                         method () values(?expr1, ?expr2, ?"expr1", ?"expr2") end,
                         "expect-not-equal",
                         terminate?: #f) }
end macro;

define macro assert-not-equal
  { assert-not-equal (?expr1:expression, ?expr2:expression)
  } => {
    assert-not-equal(?expr1, ?expr2, ?"expr1" " ~= " ?"expr2")
  }
  { assert-not-equal (?expr1:expression, ?expr2:expression, ?description:*)
  } => {
    do-check-not-equal(method () values(?description) end,
                       method ()
                         values(?expr1, ?expr2, ?"expr1", ?"expr2")
                       end,
                       "assert-not-equal",
                       terminate?: #t)
  }
end macro assert-not-equal;

define function do-check-not-equal
    (description-thunk :: <function>, arguments-thunk :: <function>, caller :: <string>,
     #key terminate? :: <boolean>)
 => ()
  let phase = format-to-string("evaluating %s description", caller);
  let description :: false-or(<string>) = #f;
  block ()
    description := eval-check-description(description-thunk);
    phase := format-to-string("evaluating %s expressions", caller);
    let (val1, val2, expr1, expr2) = arguments-thunk();
    phase := format-to-string("while comparing %s and %s for inequality",
                              expr1, expr2);
    if (val1 ~= val2)
      record-check(description, $passed, #f);
    else
      phase := format-to-string("getting %s failure detail", caller);
      record-check(description, $failed,
                   format-to-string("%= and %= are =.", val1, val2));
      terminate? & signal(make(<assertion-failure>));
    end;
  exception (err :: <serious-condition>, test: method (cond) ~debug?() end)
    record-check(description | $invalid-description,
                 $crashed,
                 format-to-string("Error %s: %s", phase, err));
    terminate? & signal(make(<assertion-failure>));
  end block
end function;

// Return a string with details about why two objects are not =.
// Users can override this for their own classes. The output should
// be indented 4 spaces if you want it to display nicely.
define open generic check-equal-failure-detail
    (val1 :: <object>, val2 :: <object>) => (detail :: false-or(<string>));

define method check-equal-failure-detail
    (val1 :: <object>, val2 :: <object>) => (detail :: false-or(<string>))
  #f  // We have no details.
end;

define method check-equal-failure-detail
    (coll1 :: <collection>, coll2 :: <collection>) => (detail :: false-or(<string>))
  if (coll1.size ~= coll2.size)
    format-to-string("sizes differ (%d and %d)", coll1.size, coll2.size)
  end
end method;

define method check-equal-failure-detail
    (seq1 :: <sequence>, seq2 :: <sequence>) => (detail :: false-or(<string>))
  let detail1 = next-method();
  let detail2 = #f;
  for (e1 in seq1, e2 in seq2, i from 0, while: e1 = e2)
  finally
    if (i < seq1.size & i < seq2.size)
      detail2 := format-to-string("element %d is the first mismatch", i);
    end;
  end for;
  join(choose(identity, vector(detail1, detail2)), "; ")
end method;

// TODO: limit the total number of keys/values output
define method check-equal-failure-detail
    (t1 :: <table>, t2 :: <table>) => (detail :: false-or(<string>))
  let detail1 = next-method();
  let t1-missing-keys = make(<stretchy-vector>);
  let t2-missing-keys = make(<stretchy-vector>);
  for (_ keyed-by k in t2)
    if (unfound?(element(t1, k, default: $unfound)))
      add!(t1-missing-keys, k);
    end;
  end;
  for (_ keyed-by k in t1)
    if (unfound?(element(t2, k, default: $unfound)))
      add!(t2-missing-keys, k);
    end;
  end;
  let eformat = curry(format-to-string, "%="); // e for escape
  let detail2 = (~empty?(t1-missing-keys)
                   & concatenate("table1 is missing keys ",
                                 join(t1-missing-keys, ", ", key: eformat)));
  let detail3 = (~empty?(t2-missing-keys)
                   & concatenate("table2 is missing keys ",
                                 join(t2-missing-keys, ", ", key: eformat)));
  join(choose(identity, vector(detail1, detail2, detail3)), "; ")
end method;

// Deprecated; use expect-instance?.
define macro check-instance?
    { check-instance?(?description:expression, ?type:expression, ?value:expression) }
 => { expect-instance?(?type, ?value, ?description) }
end macro;

define macro expect-instance?
    { expect-instance?(?type:expression, ?value:expression) }
 => { expect-instance?(?type, ?value, ?"value" " is an instance of " ?"type") }

    { expect-instance?(?type:expression, ?value:expression, ?description:*) }
 => { do-check-instance?(method () values(?description) end,
                         method () values(?type, ?value, ?"value") end,
                         "expect-instance?",
                         terminate?: #f)
    }
end macro;

define macro assert-instance?
  { assert-instance? (?type:expression, ?value:expression)
  } => {
    assert-instance? (?type, ?value, ?"value" " is an instance of " ?"type")
  }
  { assert-instance? (?type:expression, ?value:expression, ?description:*)
  } => {
    do-check-instance?(method () values(?description) end,
                       method ()
                         values(?type, ?value, ?"value")
                       end,
                       "assert-instance?",
                       negate?: #f,
                       terminate?: #t)
  }
end macro assert-instance?;

define macro expect-not-instance?
    { expect-not-instance?(?type:expression, ?value:expression) }
 => { expect-not-instance?(?type, ?value, ?"value" " is not an instance of " ?"type") }

    { expect-not-instance?(?type:expression, ?value:expression, ?description:*) }
 => { do-check-instance?(method () values(?description) end,
                         method () values(?type, ?value, ?"value") end,
                         "expect-not-instance?",
                         negate?: #t,
                         terminate?: #f)
    }
end macro;

define macro assert-not-instance?
  { assert-not-instance? (?type:expression, ?value:expression)
  } => {
    assert-not-instance? (?type, ?value, ?"value" " is not an instance of " ?"type")
  }
  { assert-not-instance? (?type:expression, ?value:expression, ?description:*)
  } => {
    do-check-instance?(method () values(?description) end,
                       method ()
                         values(?type, ?value, ?"value")
                       end,
                       "assert-not-instance?",
                       negate?: #t,
                       terminate?: #t)
  }
end macro assert-not-instance?;

define function do-check-instance?
    (description-thunk :: <function>, get-arguments :: <function>, caller :: <string>,
     #key negate? :: <boolean>,
          terminate? :: <boolean>)
 => ()
  let phase = format-to-string("evaluating %s description", caller);
  let description :: false-or(<string>) = #f;
  block ()
    description := eval-check-description(description-thunk);
    phase := format-to-string("evaluating %s expressions", caller);
    let (type :: <type>, value, value-expr :: <string>) = get-arguments();
    phase := format-to-string("checking if %= is %=an instance of %s",
                              value-expr, if (negate?) "not " else "" end, type);
    if (instance?(value, type) ~= negate?)
      record-check(description, $passed, #f);
    else
      record-check(description, $failed,
                   format-to-string("%s (from expression %=) is not an instance of %s.",
                                    value, value-expr, type));
      terminate? & signal(make(<assertion-failure>));
    end;
  exception (err :: <serious-condition>, test: method (cond) ~debug?() end)
    record-check(description | $invalid-description,
                 $crashed,
                 format-to-string("Error %s: %s", phase, err));
    terminate? & signal(make(<assertion-failure>));
  end block
end function do-check-instance?;

// Deprecated; use expect.
define macro check-true
    { check-true(?description:expression, ?expr:expression) }
 => { expect(?expr, ?description) }
end macro;

define macro assert-true
  { assert-true (?expr:expression)
  } => {
    assert-true(?expr, ?"expr" " is true")
  }

  { assert-true (?expr:expression, ?description:*)
  } => {
    do-check-true(method () values(?description) end,
                  method () values(?expr, ?"expr") end,
                  "assert-true",
                  terminate?: #t)
  }
end macro assert-true;

define function do-check-true
    (description-thunk :: <function>, get-arguments :: <function>, caller :: <string>,
     #key terminate? :: <boolean>)
 => ()
  let phase = format-to-string("evaluating %s description", caller);
  let description :: false-or(<string>) = #f;
  block ()
    description := eval-check-description(description-thunk);
    phase := format-to-string("evaluating %s expression", caller);
    let (value, value-expr :: <string>) = get-arguments();
    phase := format-to-string("checking if %= evaluates to true", value-expr);
    if (value)
      record-check(description, $passed, #f);
    else
      record-check(description, $failed,
                   format-to-string("expression %= evaluates to #f.", value-expr));
      terminate? & signal(make(<assertion-failure>));
    end;
  exception (err :: <serious-condition>, test: method (cond) ~debug?() end)
    record-check(description | $invalid-description,
                 $crashed,
                 format-to-string("Error %s: %s", phase, err));
    terminate? & signal(make(<assertion-failure>));
  end block
end function do-check-true;

// Deprecated; use expect-false.
define macro check-false
    { check-false(?description:expression, ?expr:expression) }
 => { expect-false(?expr, ?description) }
end macro;

define macro expect-false
    { expect-false(?expr:expression) }
 => { expect-false(?expr, ?"expr" " evaluates to #f") }

    { expect-false (?expr:expression, ?description:*) }
 => { do-check-false(method () values(?description) end,
                     method () values(?expr, ?"expr") end,
                     "expect-false",
                     terminate?: #f)
    }
end macro;

define macro assert-false
  { assert-false (?expr:expression)
  } => {
    assert-false(?expr, ?"expr" " evaluates to #f")
  }

  { assert-false (?expr:expression, ?description:*)
  } => {
    do-check-false(method () values(?description) end,
                   method ()
                     values(?expr, ?"expr")
                   end,
                   "assert-false",
                   terminate?: #t)
  }
end macro assert-false;

define function do-check-false
    (description-thunk :: <function>, get-arguments :: <function>, caller :: <string>,
     #key terminate? :: <boolean>)
 => ()
  let phase = format-to-string("evaluating %s description", caller);
  let description :: false-or(<string>) = #f;
  block ()
    description := eval-check-description(description-thunk);
    phase := format-to-string("evaluating %s expression", caller);
    let (value, value-expr :: <string>) = get-arguments();
    phase := format-to-string("checking if %= evaluates to #f", value-expr);
    if (~value)
      record-check(description, $passed, #f);
    else
      record-check(description, $failed,
                   format-to-string("expression %= evaluates to %=; expected #f.",
                                    value-expr, value));
      terminate? & signal(make(<assertion-failure>));
    end;
  exception (err :: <serious-condition>, test: method (cond) ~debug?() end)
    record-check(description | $invalid-description,
                 $crashed,
                 format-to-string("Error %s: %s", phase, err));
    terminate? & signal(make(<assertion-failure>));
  end block
end function do-check-false;

// Deprecated; use expect-condition.
define macro check-condition
    { check-condition(?description:expression, ?condition:expression, ?expr:expression) }
 => { expect-condition(?condition, ?expr, ?description) }
end macro;

define macro expect-condition
    { expect-condition(?condition:expression, ?expr:expression) }
 => { expect-condition(?condition, ?expr, ?"expr" " signals condition " ?"condition") }

    { expect-condition(?condition:expression, ?expr:expression, ?description:*) }
 => { do-check-condition(method () values(?description) end,
                         method () values(?condition, method () ?expr end, ?"expr") end,
                         "expect-condition",
                         terminate?: #f) }
end macro;

// Deprecated; use assert-condition.
define macro assert-signals
  { assert-signals(?condition:expression, ?expr:expression)
  } => {
    assert-signals(?condition, ?expr, ?"expr" " signals condition " ?"condition")
  }

  { assert-signals(?condition:expression, ?expr:expression, ?description:*)
  } => {
    do-check-condition(method () values(?description) end,
                       method ()
                         values(?condition, method () ?expr end, ?"expr")
                       end,
                       "assert-signals",
                       terminate?: #t)
  }
end macro assert-signals;

define macro assert-condition
    { assert-condition(?condition:expression, ?expr:expression) }
 => { assert-condition(?condition, ?expr, ?"expr" " signals condition " ?"condition") }

    { assert-condition(?condition:expression, ?expr:expression, ?description:*) }
 => { do-check-condition(method () values(?description) end,
                         method () values(?condition, method () ?expr end, ?"expr") end,
                         "assert-condition",
                         terminate?: #t) }
end macro;

define function do-check-condition
    (description-thunk :: <function>, get-arguments :: <function>, caller :: <string>,
     #key terminate? :: <boolean>)
 => ()
  let phase = format-to-string("evaluating %s description", caller);
  let description :: false-or(<string>) = #f;
  block ()
    description := eval-check-description(description-thunk);
    phase := format-to-string("evaluating %s expression", caller);
    let (condition-class, thunk :: <function>, expr :: <string>) = get-arguments();
    phase := format-to-string("checking if %= signals a condition of class %s",
                              expr, condition-class);
    block ()
      thunk();
      record-check(description, $failed, "no condition signaled");
      terminate? & signal(make(<assertion-failure>));
    exception (ex :: condition-class)
      record-check(description, $passed, #f);
      // Not really sure if this should catch something broader, like
      // <condition>, but leaving it this way for compat with old code.
    exception (ex :: <serious-condition>)
      record-check(description, $failed,
                   format-to-string("condition of class %s signaled; "
                                      "expected a condition of class %s. "
                                      "The error was: %s",
                                    ex.object-class, condition-class, ex));
      terminate? & signal(make(<assertion-failure>));
    end;
  exception (err :: <serious-condition>, test: method (cond) ~debug?() end)
    record-check(description | $invalid-description,
                 $crashed,
                 format-to-string("Error %s: %s", phase, err));
    terminate? & signal(make(<assertion-failure>));
  end block
end function do-check-condition;


// Deprecated; use expect-no-condition.
// Same as check-no-errors, for symmetry with check-condition...
define macro check-no-condition
    { check-no-condition(?description:expression, ?expr:expression) }
 => { expect-no-condition(?expr, ?description) }
end macro;

// Deprecated; use expect-no-condition.
define macro check-no-errors
    { check-no-errors(?description:expression, ?expr:expression) }
 => { expect-no-condition(?expr, ?description) }
end macro;

define macro expect-no-condition
    { expect-no-condition(?expr:expression) }
 => { expect(begin ?expr; #t end) }

    { expect-no-condition(?expr:expression, ?description:*) }
 => { expect(begin ?expr; #t end, ?description) }
end macro;

// Deprecated; use assert-no-condition.
define macro assert-no-errors
  { assert-no-errors(?expr:expression)
  } => {
    assert-no-errors(?expr, ?"expr" " doesn't signal an error ")
  }

  { assert-no-errors(?expr:expression, ?description:*)
  } => {
    assert-true(begin ?expr; #t end, ?description)
  }
end macro assert-no-errors;

define macro assert-no-condition
    { assert-no-condition(?expr:expression) }
 => { assert-no-condition(?expr, ?"expr" " doesn't signal an error ") }

    { assert-no-condition(?expr:expression, ?description:*) }
 => { assert-true(begin ?expr; #t end, ?description) }
end macro;

/// Check recording

define thread variable *check-recording-function* = always(#f);

define method record-check
    (name :: <string>, status :: <result-status>, reason :: false-or(<string>))
 => (status :: <result>)
  if ((status = $failed | status = $crashed)
        & expected-to-fail?(*component*))
    // If a test is expected to fail it propagates to the test's assertions,
    // otherwise they would turn the result red incorrectly.
    status := $expected-failure;
  end;
  let result = make(<check-result>,
                    name: name, status: status, reason: reason);
  *check-recording-function*(result);
  result
end method record-check;
