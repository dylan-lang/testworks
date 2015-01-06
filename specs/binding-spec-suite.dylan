Module:       testworks-specs
Synopsis:     A library for building specification test suites
Author:       Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

// A macro for building a suite out of a list of binding specifications

define macro binding-spec-suite-definer
  { define binding-spec-suite ?suite-name:name (?options:*)
      ?specs:*
    end }
    => { define suite ?suite-name (?options)
           ?specs
         end }
 specs:
  { } => { }
  { ?spec:*; ... } => { ?spec ... }
 spec:
  { protocol ?protocol-name:name }
    => { suite ?protocol-name ## "-protocol-test-suite"; }
  { ?modifiers:* class ?class-name:name (?superclasses:*); }
    => { test "check-class-specification-" ## ?class-name;
         test "test-class-" ## ?class-name; }
  { ?modifiers:* function ?function-name:name (?parameters:*) => (?results:*); }
    => { test "check-function-specification-" ## ?function-name;
         test "test-function-" ## ?function-name; }
  { ?modifiers:* generic-function ?function-name:name (?parameters:*) => (?results:*); }
    => { test "check-function-specification-" ## ?function-name;
         test "test-function-" ## ?function-name; }
  { ?modifiers:* variable ?variable-name:name :: ?type:expression; }
    => { test "check-variable-specification-" ## ?variable-name;
         test "test-variable-" ## ?variable-name; }
  { ?modifiers:* constant ?constant-name:name :: ?type:expression; }
    => { test "check-constant-specification-" ## ?constant-name;
         test "test-constant-" ## ?constant-name; }
  { ?modifiers:* macro-test ?macro-name:name; }
    => { test "test-macro-" ## ?macro-name; }
  { ?definition:* }
    => { }
end macro binding-spec-suite-definer;
