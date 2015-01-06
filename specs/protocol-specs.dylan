Module:       testworks-specs
Synopsis:     A library for building specification test suites
Author:       Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// A useful macro to define protocol specs
///
/// A protocol spec is a list of binding specifications that
/// is smaller than a module. It is used to more tightly associate
/// a set of bindings rather than having them all within a single
/// module spec.
define macro protocol-spec-definer
  { define protocol-spec ?protocol-name:name (?options:*)
      ?specs:*
    end}
    => { define binding-specs ?protocol-name (?options)
           ?specs
         end;
         define binding-spec-suite ?protocol-name ## "-protocol-test-suite" (?options)
           ?specs
         end }
end macro protocol-spec-definer;
