Module:       dylan-user
Synopsis:     A library for building specification test suites
Author:       Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define library testworks-specs
  use common-dylan;
  use io;
  use testworks;

  export testworks-specs;
end library testworks-specs;

define module testworks-specs
  use common-dylan;
  use format;
  use testworks;

  // The macros
  export \library-spec-definer,
         \module-spec-definer,
         \protocol-spec-definer,
         \definition-test-definer,
         \constant-test-definer,
         \variable-test-definer,
         \class-test-definer,
         \function-test-definer,
         \macro-test-definer;

  // The classes
  export <spec>,
         <definition-spec>,
         <constant-spec>,
         <variable-spec>,
         <class-spec>,
         <function-spec>;

  // Useful accessors
  export spec-name,
         spec-title;

  // The test functions
  export make-test-instance,
         destroy-test-instance,
         class-test-function;

  //---*** Hygiene glitches
  export \protocol-spec-constant-definer,
         \protocol-spec-bindings-definer,
         \module-spec-protocol-definer,
         \module-spec-suite-definer
         check-class-specification,
         check-function-specification,
         check-variable-specification,
         check-constant-specification,
         check-macro-specification;
end module testworks-specs;
