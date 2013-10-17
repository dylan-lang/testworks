Module: testworks
Synopsis: Utilities and code that needs to be loaded early.
Copyright: Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
           All rights reserved.
License: See License.txt in this distribution for details.
Warranty: Distributed WITHOUT WARRANTY OF ANY KIND


define thread variable *debug?* = #f;

define thread variable *format-function* = format-out;

define thread variable *announce-checks?* :: <boolean> = #f;

define thread variable *announce-check-function* :: false-or(<function>) = #f;

define thread variable *announce-function* :: false-or(<function>) = method (c) end;
