Module:       dylan-user
Synopsis:     A tool to generate reports from test run logs
Author:       Shri Amit, Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define library testworks-report
  use common-dylan;
  use io;
  use system;
  use testworks;
  use xml-parser,
    import: { xml-parser };

  export testworks-report;
end library testworks-report;

define module testworks-report
  use common-dylan;
  use format-out;
  use streams;
  use file-system;
  use operating-system;
  use threads,
    import: { dynamic-bind };
  use testworks;
  use xml-parser,
    prefix: "xml/";

  export read-log-file,
         perform-test-diff;
end module testworks-report;

