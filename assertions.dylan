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

// The check-* macros require the caller to provide a name.
// The assert-* macros auto-generate a name by default.

// Note that these macros wrap up the real macro arguments inside
// methods to delay their evaluation until they are within the scope
// of whatever condition handling is required.

define function eval-check-description
    (thunk :: <function>) => (description :: <string>)
  let (description, #rest args) = thunk();
  if (empty?(args))
    if (instance?(description, <string>))
      description
    else
      format-to-string("%s", description)
    end
  else
    apply(format-to-string, description, args)
  end
end function;

define macro check
  { check (?check-name:expression,
           ?check-function:expression, ?check-args:*)
  } => {
    check-true(?check-name, apply(?check-function, vector(?check-args)))
  }
end macro check;

define macro check-equal
  { check-equal (?name:expression, ?expr1:expression, ?expr2:expression)
  } => {
    do-check-equal(method () ?name end,
                   method ()
                     values(?expr1, ?expr2, ?"expr1", ?"expr2")
                   end,
                   negate?: #f,
                   terminate?: #f)
  }
end macro check-equal;

define macro assert-equal
  { assert-equal (?expr1:expression, ?expr2:expression)
  } => {
    assert-equal(?expr1, ?expr2, ?"expr1" " = " ?"expr2")
  }
  { assert-equal (?expr1:expression, ?expr2:expression, ?description:*)
  } => {
    do-check-equal(method () values(?description) end,
                   method ()
                     values(?expr1, ?expr2, ?"expr1", ?"expr2")
                   end,
                   negate?: #f,
                   terminate?: #t)
  }
end macro assert-equal;

define macro assert-not-equal
  { assert-not-equal (?expr1:expression, ?expr2:expression)
  } => {
    assert-not-equal(?expr1, ?expr2, ?"expr1" " ~= " ?"expr2")
  }
  { assert-not-equal (?expr1:expression, ?expr2:expression, ?description:*)
  } => {
    do-check-equal(method () values(?description) end,
                   method ()
                     values(?expr1, ?expr2, ?"expr1", ?"expr2")
                   end,
                   negate?: #t,
                   terminate?: #t)
  }
end macro assert-not-equal;

define function do-check-equal
    (description-thunk :: <function>, get-arguments :: <function>,
     #key negate? :: <boolean>,
          terminate? :: <boolean>)
 => ()
  let phase = "evaluating assertion description";
  let description :: false-or(<string>) = #f;
  block ()
    description := eval-check-description(description-thunk);
    phase := "evaluating assertion expressions";
    let (val1, val2, expr1, expr2) = get-arguments();
    phase := format-to-string("while comparing %s and %s for %sequality",
                              expr1, expr2,
                              if (negate?) "in" else "" end);
    let compare = if (negate?) \~= else \= end;
    if (compare(val1, val2))
      record-check(description, $passed, #f);
    else
      phase := format-to-string("getting assert-%sequal failure detail",
                                if (negate?) "not-" else "" end);
      let detail = if (negate?)
                     ""
                   else
                     check-equal-failure-detail(val1, val2)
                   end;
      record-check(description, $failed,
                   format-to-string("%= and %= are %s=.%s%s",
                                    val1, val2,
                                    if (negate?) "" else "not " end,
                                    if (detail) "  " else "" end,
                                    detail | ""));
      terminate? & signal(make(<assertion-failure>));
    end;
  exception (err :: <serious-condition>, test: method (cond) ~debug?() end)
    record-check(description | $invalid-description,
                 $crashed,
                 format-to-string("Error %s: %s", phase, err));
    terminate? & signal(make(<assertion-failure>));
  end block
end function do-check-equal;

// Return a string with details about why two objects are not =.
// Users can override this for their own classes.
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
end method check-equal-failure-detail;

define method check-equal-failure-detail
    (seq1 :: <sequence>, seq2 :: <sequence>) => (detail :: false-or(<string>))
  let detail1 = next-method();
  let detail2 = #f;
  for (e1 in seq1, e2 in seq2, i from 0, while: e1 = e2)
  finally
    if (i < seq1.size & i < seq2.size)
      // TODO(cgay): show the two element values.
      detail2 := format-to-string("element %d is the first non-matching element", i);
    end;
  end for;
  join(choose(identity, vector(detail1, detail2)), ", ")
end method check-equal-failure-detail;

// TODO: if key sets are same, compare values. Limit to showing 1 mismatch?
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
  let detail2 = (~empty?(t1-missing-keys)
                   & concatenate("table1 is missing keys ",
                                 join(sort(t1-missing-keys), ", ")));
  let detail3 = (~empty?(t2-missing-keys)
                   & concatenate("table2 is missing keys ",
                                 join(sort(t2-missing-keys), ", ")));
  join(choose(identity, vector(detail1, detail2, detail3)), "; ")
end method;

define macro check-instance?
  { check-instance? (?check-name:expression, ?type:expression, ?value:expression)
  } => {
    do-check-instance?(method () ?check-name end,
                       method ()
                         values(?type, ?value, ?"value")
                       end,
                       negate?: #f,
                       terminate?: #f)
  }
end macro check-instance?;

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
                       negate?: #f,
                       terminate?: #t)
  }
end macro assert-instance?;

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
                       negate?: #t,
                       terminate?: #t)
  }
end macro assert-not-instance?;

define function do-check-instance?
    (description-thunk :: <function>, get-arguments :: <function>,
     #key negate? :: <boolean>,
          terminate? :: <boolean>)
 => ()
  let phase = "evaluating assertion description";
  let description :: false-or(<string>) = #f;
  block ()
    description := eval-check-description(description-thunk);
    phase := "evaluating assertion expressions";
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

define macro check-true
  { check-true (?check-name:expression, ?expr:expression)
  } => {
    do-check-true(method () ?check-name end,
                  method ()
                    values(?expr, ?"expr")
                  end,
                  terminate?: #f)
  }
end macro check-true;

define macro assert-true
  { assert-true (?expr:expression)
  } => {
    assert-true(?expr, ?"expr" " is true")
  }

  { assert-true (?expr:expression, ?description:*)
  } => {
    do-check-true(method () values(?description) end,
                  method () values(?expr, ?"expr") end,
                  terminate?: #t)
  }
end macro assert-true;

define function do-check-true
    (description-thunk :: <function>, get-arguments :: <function>,
     #key terminate? :: <boolean>)
 => ()
  let phase = "evaluating assertion description";
  let description :: false-or(<string>) = #f;
  block ()
    description := eval-check-description(description-thunk);
    phase := "evaluating assertion expression";
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

define macro check-false
   { check-false (?check-name:expression, ?expr:expression)
   } => {
     do-check-false(method () ?check-name end,
                    method ()
                      values(?expr, ?"expr")
                    end,
                    terminate?: #f)
   }
end macro check-false;

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
                   terminate?: #t)
  }
end macro assert-false;

define function do-check-false
    (description-thunk :: <function>, get-arguments :: <function>,
     #key terminate? :: <boolean>)
 => ()
  let phase = "evaluating assertion description";
  let description :: false-or(<string>) = #f;
  block ()
    description := eval-check-description(description-thunk);
    phase := "evaluating assertion expression";
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

define macro check-condition
  { check-condition(?check-name:expression, ?condition:expression,
                    ?expr:expression)
  } => {
    do-check-condition(method () ?check-name end,
                       method ()
                         values(?condition, method () ?expr end, ?"expr")
                       end,
                       terminate?: #f)
  }
end macro check-condition;

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
                       terminate?: #t)
  }
end macro assert-signals;

define function do-check-condition
    (description-thunk :: <function>, get-arguments :: <function>,
     #key terminate? :: <boolean>)
 => ()
  let phase = "evaluating assertion description";
  let description :: false-or(<string>) = #f;
  block ()
    description := eval-check-description(description-thunk);
    phase := "evaluating assertion expression";
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


// Same as check-no-errors, for symmetry with check-condition...
define macro check-no-condition
  { check-no-condition(?check-name:expression, ?check-body:expression)
  } => {
    check-true(?check-name, begin ?check-body; #t end)
  }
end macro check-no-condition;

define macro check-no-errors
  { check-no-errors(?check-name:expression, ?check-body:expression)
  } => {
    check-true(?check-name, begin ?check-body; #t end)
  }
end macro check-no-errors;

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
