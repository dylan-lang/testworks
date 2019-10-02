Module:       %testworks
Synopsis:     Testworks testing harness
Author:       Andrew Armstrong, James Kirsch
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

// TODO(cgay): Try and figure out a good way to remove some of the
// duplicate code in the do-check* functions.


/// Assertion macros

// The check-* macros are deprecated.
// The check-* macros require the caller to provide a name.
// The assert-* macros auto-generate a name by default.

// Note that these macros wrap up the real macro arguments inside
// methods to delay their evaluation until they are within the scope
// of whatever condition handling is required.

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
                   #f)
  }
end macro check-equal;

define macro assert-equal
  { assert-equal (?expr1:expression, ?expr2:expression)
  } => {
    assert-equal(?expr1, ?expr2, ?"expr1" " = " ?"expr2")
  }
  { assert-equal (?expr1:expression, ?expr2:expression, ?description:expression)
  } => {
    do-check-equal(method () ?description end,
                   method ()
                     values(?expr1, ?expr2, ?"expr1", ?"expr2")
                   end,
                   #f)
  }
end macro assert-equal;

define macro assert-not-equal
  { assert-not-equal (?expr1:expression, ?expr2:expression)
  } => {
    assert-not-equal(?expr1, ?expr2, ?"expr1" " ~= " ?"expr2")
  }
  { assert-not-equal (?expr1:expression, ?expr2:expression, ?description:expression)
  } => {
    do-check-equal(method () ?description end,
                   method ()
                     values(?expr1, ?expr2, ?"expr1", ?"expr2")
                   end,
                   #t)
  }
end macro assert-not-equal;

define function do-check-equal
    (get-name :: <function>, get-arguments :: <function>, negate? :: <boolean>)
 => (result :: <result>)
  let phase = "evaluating assertion description";
  let name = #f;
  block (return)
    let handler <serious-condition>
        = method (condition, next-handler)
            if (debug?())
              next-handler()  // decline to handle it
            else
              return(record-check(name | "*** Invalid description ***",
                                  $crashed,
                                  format-to-string("Error %s: %s", phase, condition)));
            end;
          end method;
    name := get-name();
    phase := "evaluating assertion expressions";
    let (val1, val2, expr1, expr2) = get-arguments();
    phase := format-to-string("while comparing %s and %s for %sequality",
                              expr1, expr2,
                              if (negate?) "in" else "" end);
    let compare = if (negate?) \~= else \= end;
    let (status, reason)
      = if (compare(val1, val2))
          $passed
        else
          phase := format-to-string("getting assert-%sequal failure detail",
                                    if (negate?) "not-" else "" end);
          let detail = if (negate?)
                         ""
                       else
                         check-equal-failure-detail(val1, val2)
                       end;
          values($failed,
                 format-to-string("%= and %= are %s=.%s%s",
                                  val1, val2,
                                  if (negate?) "" else "not " end,
                                  if (detail) "  " else "" end,
                                  detail | ""))
        end;
    record-check(name, status, reason)
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

define macro check-instance?
  { check-instance? (?check-name:expression, ?type:expression, ?value:expression)
  } => {
    do-check-instance?(method () ?check-name end,
                       method ()
                         values(?type, ?value, ?"value")
                       end,
                       #f)
  }
end macro check-instance?;

define macro assert-instance?
  { assert-instance? (?type:expression, ?value:expression)
  } => {
    assert-instance? (?type, ?value, ?"value" " is an instance of " ?"type")
  }
  { assert-instance? (?type:expression, ?value:expression, ?description:expression)
  } => {
    do-check-instance?(method () ?description end,
                       method ()
                         values(?type, ?value, ?"value")
                       end,
                       #f)
  }
end macro assert-instance?;

define macro assert-not-instance?
  { assert-not-instance? (?type:expression, ?value:expression)
  } => {
    assert-not-instance? (?type, ?value, ?"value" " is not an instance of " ?"type")
  }
  { assert-not-instance? (?type:expression, ?value:expression, ?description:expression)
  } => {
    do-check-instance?(method () ?description end,
                       method ()
                         values(?type, ?value, ?"value")
                       end,
                       #t)
  }
end macro assert-not-instance?;

define function do-check-instance?
    (get-name :: <function>, get-arguments :: <function>, negate? :: <boolean>)
 => (result :: <result>)
  let phase = "evaluating assertion description";
  let name = #f;
  block (return)
    let handler <serious-condition>
        = method (condition, next-handler)
            if (debug?())
              next-handler()  // decline to handle it
            else
              return(record-check(name | "*** Invalid description ***",
                                  $crashed,
                                  format-to-string("Error %s: %s", phase, condition)))
            end;
          end method;
    name := get-name();
    phase := "evaluating assertion expressions";
    let (type :: <type>, value, value-expr :: <string>) = get-arguments();
    phase := format-to-string("checking if %= is %=an instance of %s",
                              value-expr, if (negate?) "not " else "" end, type);
    let (status, reason)
      = if (instance?(value, type) ~= negate?)
          $passed
        else
          values($failed,
                 format-to-string("%s (from expression %=) is not an instance of %s.",
                                  value, value-expr, type))
        end;
    record-check(name, status, reason)
  end block
end function do-check-instance?;

define macro check-true
  { check-true (?check-name:expression, ?expr:expression)
  } => {
    do-check-true(method () ?check-name end,
                  method ()
                    values(?expr, ?"expr")
                  end)
  }
end macro check-true;

define macro assert-true
  { assert-true (?expr:expression)
  } => {
    assert-true(?expr, ?"expr" " is true")
  }

  { assert-true (?expr:expression, ?description:expression)
  } => {
    do-check-true(method () ?description end,
                  method () values(?expr, ?"expr") end)
  }
end macro assert-true;

define function do-check-true
    (get-name :: <function>, get-arguments :: <function>)
 => (result :: <result>)
  let phase = "evaluating assertion description";
  let name = #f;
  block (return)
    let handler <serious-condition>
        = method (condition, next-handler)
            if (debug?())
              next-handler()  // decline to handle it
            else
              return(record-check(name | "*** Invalid description ***",
                                  $crashed,
                                  format-to-string("Error %s: %s", phase, condition)))
            end;
          end method;
    name := get-name();
    phase := "evaluating assertion expression";
    let (value, value-expr :: <string>) = get-arguments();
    phase := format-to-string("checking if %= evaluates to true", value-expr);
    let (status, reason)
      = if (value)
          $passed
        else
          values($failed,
                 format-to-string("expression %= evaluates to #f.", value-expr))
        end;
    record-check(name, status, reason)
  end block
end function do-check-true;

define macro check-false
   { check-false (?check-name:expression, ?expr:expression)
   } => {
     do-check-false(method () ?check-name end,
                    method ()
                      values(?expr, ?"expr")
                    end)
   }
end macro check-false;

define macro assert-false
  { assert-false (?expr:expression)
  } => {
    assert-false(?expr, ?"expr" " evaluates to #f")
  }

  { assert-false (?expr:expression, ?description:expression)
  } => {
    do-check-false(method () ?description end,
                   method ()
                     values(?expr, ?"expr")
                   end)
  }
end macro assert-false;

define function do-check-false
    (get-name :: <function>, get-arguments :: <function>)
 => (result :: <result>)
  let phase = "evaluating assertion description";
  let name = #f;
  block (return)
    let handler <serious-condition>
        = method (condition, next-handler)
            if (debug?())
              next-handler()  // decline to handle it
            else
              return(record-check(name | "*** Invalid description ***",
                                  $crashed,
                                  format-to-string("Error %s: %s", phase, condition)))
            end;
          end method;
    name := get-name();
    phase := "evaluating assertion expression";
    let (value, value-expr :: <string>) = get-arguments();
    phase := format-to-string("checking if %= evaluates to #f", value-expr);
    let (status, reason)
      = if (~value)
          $passed
        else
          values($failed,
                 format-to-string("expression %= evaluates to %=; expected #f.",
                                  value-expr, value))
        end;
    record-check(name, status, reason)
  end block
end function do-check-false;

define macro check-condition
  { check-condition(?check-name:expression, ?condition:expression,
                    ?expr:expression)
  } => {
    do-check-condition(method () ?check-name end,
                       method ()
                         values(?condition, method () ?expr end, ?"expr")
                       end)
  }
end macro check-condition;

define macro assert-signals
  { assert-signals(?condition:expression, ?expr:expression)
  } => {
    assert-signals(?condition, ?expr, ?"expr" " signals condition " ?"condition")
  }

  { assert-signals(?condition:expression, ?expr:expression, ?description:expression)
  } => {
    do-check-condition(method () ?description end,
                       method ()
                         values(?condition, method () ?expr end, ?"expr")
                       end)
  }
end macro assert-signals;

define function do-check-condition
    (get-name :: <function>, get-arguments :: <function>)
 => (result :: <result>)
  let phase = "evaluating assertion description";
  let name = #f;
  block (return)
    let handler <serious-condition>
        = method (condition, next-handler)
            if (debug?())
              next-handler()  // decline to handle it
            else
              return(record-check(name | "*** Invalid description ***",
                                  $crashed,
                                  format-to-string("Error %s: %s", phase, condition)))
            end;
          end method;
    name := get-name();
    phase := "evaluating assertion expression";
    let (condition-class, thunk :: <function>, expr :: <string>) = get-arguments();
    phase := format-to-string("checking if %= signals a condition of class %s",
                              expr, condition-class);
    let (status, reason)
      = block ()
          thunk();
          values($failed, "no condition signaled")
        exception (ex :: condition-class)
          $passed
        // Not really sure if this should catch something broader, like
        // <condition>, but leaving it this way for compat with old code.
        exception (ex :: <serious-condition>)
          values($failed, format-to-string("condition of class %s signaled; "
                                             "expected a condition of class %s. "
                                             "The error was: %s",
                                           ex.object-class, condition-class, ex))
        end;
    record-check(name, status, reason)
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

  { assert-no-errors(?expr:expression, ?description:expression)
  } => {
    assert-true(begin ?expr; #t end, ?description)
  }
end macro assert-no-errors;


/// Check recording

define thread variable *check-recording-function* = always(#f);

define method record-check
    (name :: <string>, status :: <result-status>, reason :: false-or(<string>))
 => (status :: <result>)
  let result = make(<check-result>,
                    name: name, status: status, reason: reason);
  *check-recording-function*(result);
  result
end method record-check;
