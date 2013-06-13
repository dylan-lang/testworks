Module:       dylan-user
Synopsis:     TestWorks GUI - a simple GUI wrapper for TestWorks
Author:       Hugh Greene
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define library testworks-gui
  use common-dylan;
  use testworks, export: all;
  use duim;

  export testworks-gui;
end library testworks-gui;

define module testworks-gui
  use common-dylan;
  use testworks, export: all;
  use threads;
  use duim;

  export <progress-window>,
         *progress-window*,
         gui-progress-display-message,
         gui-progress-clear-all-messages,
         gui-progress-pause,
         gui-progress-pause-with-check-name,
         gui-announce-function,
         start-progress-window,
         exit-progress-window,
         gui-perform-suite,
         gui-perform-test;
end module testworks-gui;
