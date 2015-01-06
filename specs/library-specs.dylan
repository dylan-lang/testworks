Module:       testworks-specs
Synopsis:     A library for building specification test suites
Author:       Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

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
