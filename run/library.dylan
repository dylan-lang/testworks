Module:    dylan-user
Synopsis:  Runner for executing Testworks libraries
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define library testworks-run
  use common-dylan;
  use system;
  use io;
  use testworks;
end library testworks-run;

define module testworks-run
  use common-dylan;
  use format;
  use streams;
  use standard-io;
  use operating-system;
  use testworks;
end module testworks-run;
