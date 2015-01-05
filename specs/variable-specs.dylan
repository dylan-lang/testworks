Module:       testworks-specs
Synopsis:     A library for building specification test suites
Author:       Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// Variable specs

define abstract class <abstract-variable-spec> (<definition-spec>)
  constant slot variable-spec-type :: <type>,
    required-init-keyword: type:;
  constant slot variable-spec-getter :: <function>,
    required-init-keyword: getter:;
end class <abstract-variable-spec>;

define class <variable-spec> (<abstract-variable-spec>)
  constant slot variable-spec-setter :: <function>,
    required-init-keyword: setter:;
end class <variable-spec>;

define class <constant-spec> (<abstract-variable-spec>)
end class <constant-spec>;


/// A useful macro to define the class specs

define macro variable-test-definer
  { define ?protocol-name:name variable-test ?variable-name:name ()
      ?body:body
    end }
    => { define test "test-variable-" ## ?variable-name (requires-assertions?: #f)
           ?body
         end }
end macro variable-test-definer;

define macro constant-test-definer
  { define ?protocol-name:name constant-test ?constant-name:name ()
      ?body:body
    end }
    => { define test "test-constant-" ## ?constant-name (requires-assertions?: #f)
           ?body
         end }
end macro constant-test-definer;


/// Variable testing

define function check-variable-specification
    (variable-spec :: <variable-spec>)
 => ()
  let title = spec-title(variable-spec);
  check-instance?(format-to-string("Variable %s has the correct type", title),
                  variable-spec-type(variable-spec),
                  variable-spec-getter(variable-spec)());
  check-true(format-to-string("Variable %s can be set to itself", title),
             begin
               let value = variable-spec-getter(variable-spec)();
               variable-spec-setter(variable-spec)(value) = value
             end);
end function check-variable-specification;

define function check-constant-specification
    (constant-spec :: <constant-spec>)
 => ()
  let title = spec-title(constant-spec);
  check-instance?(format-to-string("Constant %s has the correct type", title),
                  variable-spec-type(constant-spec),
                  variable-spec-getter(constant-spec)());
end function check-constant-specification;
