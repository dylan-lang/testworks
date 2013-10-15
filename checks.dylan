Module:       testworks
Synopsis:     Testworks testing harness
Author:       Andrew Armstrong, James Kirsch
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// Check/assert macros

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
    %check-equal(method () ?name end,
                 method ()
                   values(?expr2, ?expr2, ?"expr1", ?"expr2")
                 end)
  }
end macro check-equal;

define macro assert-equal
  { assert-equal (?expr1:expression, ?expr2:expression)
  } => {
    assert-equal(?expr1, ?expr2, ?"expr1" " = " ?"expr2")
  }
  { assert-equal (?expr1:expression, ?expr2:expression, ?description:expression)
  } => {
    %check-equal(method () ?description end,
                 method ()
                   values(?expr1, ?expr2, ?"expr1", ?"expr2")
                 end)
  }
end macro assert-equal;

define function %check-equal
    (get-name :: <function>, get-arguments :: <function>)
 => (status :: <result-status>)
  let phase = "evaluating check name";
  let name = #f;
  block (return)
    let handler <serious-condition>
        = method (condition, next-handler)
            if (*debug?*)
              next-handler()  // decline to handle it
            else
              record-check(name | format-to-string("*** Invalid check name ***"),
                           $crashed,
                           format-to-string("Error %s: %s", phase, condition));
              return($crashed);
            end;
          end method;
    name := get-name();
    phase := "evaluating check arguments";
    let (val1, val2, expr1, expr2) = get-arguments();
    phase := format-to-string("while comparing %s and %s for equality",
                              expr1, expr2);
    let (status, reason)
      = if (val1 = val2)
          $passed
        else
          phase := "getting check-equal failure detail";
          let detail = check-equal-failure-detail(val1, val2);
          values($failed,
                 format-to-string("%s (from expression %=) and %s (from "
                                    "expression %=) are not equal (=).%s%s",
                                  val1, expr1, val2, expr2,
                                  if (detail) "  " else "" end,
                                  detail | ""))
        end;
    record-check(name, status, reason);
    status
  end block
end function %check-equal;

// Users can potentially override this for their own classes.
define open generic check-equal-failure-detail
    (val1 :: <object>, val2 :: <object>) => (detail :: false-or(<string>));

define method check-equal-failure-detail
    (val1 :: <object>, val2 :: <object>) => (detail :: false-or(<string>))
  #f
end;

define method check-equal-failure-detail
    (val1 :: <sequence>, val2 :: <sequence>) => (detail :: false-or(<string>))
  // TODO(cgay):
end;

define method check-equal-failure-detail
    (val1 :: <collection>, val2 :: <collection>) => (detail :: false-or(<string>))
  // TODO(cgay):
end;

define macro check-instance?
  { check-instance? (?check-name:expression, ?type:expression, ?value:expression)
  } => {
    %check-instance?(method () ?check-name end,
                     method ()
                       values(?type, ?value, ?"value")
                     end)
  }
end macro check-instance?;

define function %check-instance?
    (get-name :: <function>, get-arguments :: <function>)
 => (status :: <result-status>)
  let phase = "evaluating check name";
  let name = #f;
  block (return)
    let handler <serious-condition>
        = method (condition, next-handler)
            if (*debug?*)
              next-handler()  // decline to handle it
            else
              record-check(name | format-to-string("*** Invalid check name ***"),
                           $crashed,
                           format-to-string("Error %s: %s", phase, condition));
              return($crashed);
            end;
          end method;
    name := get-name();
    phase := "evaluating check arguments";
    let (type :: <type>, value, value-expr :: <string>) = get-arguments();
    phase := format-to-string("checking if %= is an instance of %s",
                              value-expr, type);
    let (status, reason)
      = if (instance?(value, type))
          $passed
        else
          values($failed,
                 format-to-string("%s (from expression %=) is not an instance of %s.",
                                  value, value-expr, type))
        end;
    record-check(name, status, reason);
    status
  end block
end function %check-instance?;

define macro check-true
  { check-true (?check-name:expression, ?expr:expression)
  } => {
    %check-true(method () ?check-name end,
                method ()
                  values(?expr, ?"expr")
                end)
  }
end macro check-true;

define macro assert-true
  { assert-true (?expr:expression)
  } => {
    assert-true(?expr, ?"expr" " evaluates to true (not #f)")
  }

  { assert-true (?expr:expression, ?description:expression)
  } => {
    %check-true(method () ?description end,
                method () values(?expr, ?"expr") end)
  }
end macro assert-true;

define function %check-true
    (get-name :: <function>, get-arguments :: <function>)
 => (status :: <result-status>)
  let phase = "evaluating check name";
  let name = #f;
  block (return)
    let handler <serious-condition>
        = method (condition, next-handler)
            if (*debug?*)
              next-handler()  // decline to handle it
            else
              record-check(name | format-to-string("*** Invalid check name ***"),
                           $crashed,
                           format-to-string("Error %s: %s", phase, condition));
              return($crashed);
            end;
          end method;
    name := get-name();
    phase := "evaluating check arguments";
    let (value, value-expr :: <string>) = get-arguments();
    phase := format-to-string("checking if %= evaluates to a true value",
                              value-expr);
    let (status, reason)
      = if (value)
          $passed
        else
          values($failed,
                 format-to-string("expression %= evaluates to #f, not a true value.",
                                  value-expr))
        end;
    record-check(name, status, reason);
    status
  end block
end function %check-true;

define macro check-false
   { check-false (?check-name:expression, ?expr:expression)
   } => {
     %check-false(method () ?check-name end,
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
    %check-false(method () ?description end,
                 method ()
                   values(?expr, ?"expr")
                 end)
  }
end macro assert-false;

define function %check-false
    (get-name :: <function>, get-arguments :: <function>)
 => (status :: <result-status>)
  let phase = "evaluating check name";
  let name = #f;
  block (return)
    let handler <serious-condition>
        = method (condition, next-handler)
            if (*debug?*)
              next-handler()  // decline to handle it
            else
              record-check(name | format-to-string("*** Invalid check name ***"),
                           $crashed,
                           format-to-string("Error %s: %s", phase, condition));
              return($crashed);
            end;
          end method;
    name := get-name();
    phase := "evaluating check arguments";
    let (value, value-expr :: <string>) = get-arguments();
    phase := format-to-string("checking if %= evaluates to #f", value-expr);
    let (status, reason)
      = if (~value)
          $passed
        else
          values($failed,
                 format-to-string("expression %= does not evaluate to #f.",
                                  value-expr))
        end;
    record-check(name, status, reason);
    status
  end block
end function %check-false;

define macro check-condition
  { check-condition(?check-name:expression, ?condition:expression,
                    ?expr:expression)
  } => {
    %check-condition(method () ?check-name end,
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
    %check-condition(method () ?description end,
                     method ()
                       values(?condition, method () ?expr end, ?"expr")
                     end)
  }
end macro assert-signals;

define function %check-condition
    (get-name :: <function>, get-arguments :: <function>)
 => (status :: <result-status>)
  let phase = "evaluating check name";
  let name = #f;
  block (return)
    let handler <serious-condition>
        = method (condition, next-handler)
            if (*debug?*)
              next-handler()  // decline to handle it
            else
              record-check(name | format-to-string("*** Invalid check name ***"),
                           $crashed,
                           format-to-string("Error %s: %s", phase, condition));
              return($crashed);
            end;
          end method;
    name := get-name();
    phase := "evaluating check arguments";
    let (condition-class :: subclass(<condition>),
         thunk :: <function>, expr :: <string>) = get-arguments();
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
                                             "expected a condition of class %s",
                                           ex.object-class, condition-class))
        end;
    record-check(name, status, reason);
    status
  end block
end function %check-condition;


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


/// Check progress functions

define method print-check-progress
    (result :: <unit-result>) => ()
  let status = result.result-status;
  let name = result.result-name;
  select (status)
    $skipped =>
      test-output("Ignored check: %s", name);
    otherwise =>
      test-output("Ran check: %s %s", name, status-name(status));
  end;
  test-output(" [%s]\n", result.result-reason);
end method print-check-progress;


/// Check recording

define thread variable *check-recording-function* = print-check-progress;

define method record-check
    (name :: <string>,
     status :: <result-status>,
     reason :: false-or(<string>))
 => (status :: <result-status>)
  let result = make(<check-result>,
                    name: name, status: status, reason: reason);
  *check-recording-function*(result);
  status
end method record-check;
