Module:       dylan-user
Summary:      A test suite to test the testworks harness
Author:       Andy Armstrong, James Kirsch, Shri Amit
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define library testworks-test-suite
  use collections,
    import: { table-extensions };
  use command-line-parser;
  use common-dylan;
  use io,
    import: { format };
  use strings;
  use testworks;
  use testworks-specs;

  export testworks-test-suite;
end library testworks-test-suite;

define module testworks-test-suite
  use command-line-parser;
  use common-dylan;
  use format;
  use strings;
  use table-extensions,
    import: { table => tabling };
  use testworks;
  use testworks-specs;
  use %testworks;

  export testworks-test-suite;
end module testworks-test-suite;
