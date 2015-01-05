Module:       testworks-specs
Synopsis:     A library for building specification test suites
Author:       Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// A useful macro to define module specs

define macro module-spec-definer
  { define module-spec ?module-name:name (?options:*)
      ?specs:*
    end}
    => { define module-spec-protocol ?module-name ()
           ?specs
         end;
         define module-spec-suite ?module-name (?options)
           ?specs
         end;
         }
end macro module-spec-definer;

define macro module-spec-protocol-definer
  { define module-spec-protocol ?module-name:name (?options:*)
      ?specs:*
    end }
    => { define protocol-spec ?module-name (?options)
           ?specs
         end }
 specs:
  { } => { }
  { ?spec:*; ... } => { ?spec ... }
 spec:
  { protocol ?protocol-name:name }
    => { }
  { ?definition:* }
    => { ?definition; }
end macro module-spec-protocol-definer;

define macro module-spec-suite-definer
  { define module-spec-suite ?module-name:name (?options:*)
      ?specs:*
    end }
    => { define suite ?module-name ## "-module-test-suite" (?options)
           ?specs
         end }
 specs:
  { } => { }
  { ?spec:*; ... } => { ?spec ... }
 spec:
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
end macro module-spec-suite-definer;


/// Library specs

// Like the "define suite" macro, but allows clauses like "module foo;"
// in its body which expand to "suite foo-module-test-suite".
define macro library-spec-definer
  { define library-spec ?library-name:name (?options:*)
      ?subsuites:*
    end}
    => { define suite ?library-name ## "-test-suite" (?options)
           ?subsuites
         end
         }
 subsuites:
  { } => { }
  { ?thing; ... } => { ?thing; ... }
 thing:
  { module ?module-name:name }
    => { suite ?module-name ## "-module-test-suite" }
  { ?x:* } => { ?x }
end macro library-spec-definer;

