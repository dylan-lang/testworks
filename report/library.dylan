Module:       dylan-user
Synopsis:     A tool to generate reports from test run logs
Author:       Shri Amit, Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define library testworks-report-lib
  use common-dylan;
  use io,
    import: { format, format-out, standard-io, streams };
  use json;
  use strings;
  use system,
    import: { file-system, locators, operating-system, threads };
  use testworks;
  use xml-parser,
    import: { xml-parser };

  export testworks-report-lib;
end library;

define module testworks-report-lib
  use common-dylan;
  use format,
    import: { format-to-string };
  use format-out;
  use json,
    import: { parse-json };
  use locators,
    import: { <file-locator>, locator-extension };
  use standard-io,
    import: { *standard-output* };
  use streams;
  use strings,
    import: { string-equal-ic? };
  use file-system;
  use operating-system;
  use threads,
    import: { dynamic-bind };
  use %testworks;
  use xml-parser,
    prefix: "xml/";

  export
    main,

    // For the test suite
    read-report,
    read-json-report;
end module;
