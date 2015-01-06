Module:       testworks-specs
Synopsis:     A library for building specification test suites
Author:       Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// A useful macro to define module specs

// This expands a list of binding specifications into a test for each of those
// specifications, as well as a suite that will run both those specification tests
// and the separate test function for each binding.
define macro module-spec-definer
  { define module-spec ?module-name:name (?options:*)
      ?specs:*
    end}
    => { define module-binding-specs ?module-name ()
           ?specs
         end;
         define binding-spec-suite ?module-name ## "-module-test-suite" (?options)
           ?specs
         end }
end macro module-spec-definer;

// This just dispatches to binding-specs, but drops protocol references first.
// protocol references are used to tie a protocol-spec into a module-spec.
define macro module-binding-specs-definer
  { define module-binding-specs ?module-name:name (?options:*)
      ?specs:*
    end }
    => { define binding-specs ?module-name (?options)
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
end macro module-binding-specs-definer;
