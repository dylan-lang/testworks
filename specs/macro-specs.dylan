Module:       testworks-specs
Synopsis:     A library for building specification test suites
Author:       Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// A useful macro to define a macro test

define macro macro-test-definer
  { define ?protocol-name:name macro-test ?macro-name:name ()
      ?body:body
    end }
    => { define ?protocol-name definition-test ?macro-name () ?body end }
end macro macro-test-definer;
