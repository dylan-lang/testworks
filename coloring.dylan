Module: %testworks
Synopsis: Utilities and code that needs to be loaded early.
Copyright: Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
           All rights reserved.
License: See License.txt in this distribution for details.
Warranty: Distributed WITHOUT WARRANTY OF ANY KIND


define constant $passed-text-attributes             = text-attributes(foreground: $color-green);
define constant $skipped-text-attributes            = text-attributes(foreground: $color-cyan);
define constant $not-implemented-text-attributes    = text-attributes(foreground: $color-cyan);
define constant $failed-text-attributes             = text-attributes(foreground: $color-red);
define constant $crashed-text-attributes            = text-attributes(foreground: $color-red);
define constant $expected-failure-text-attributes   = text-attributes(foreground: $color-cyan);
define constant $unexpected-success-text-attributes = text-attributes(foreground: $color-red);
define constant $component-name-text-attributes     = text-attributes(intensity: $bright-intensity);
define constant $total-text-attributes              = text-attributes(intensity: $bright-intensity);
define constant $count-text-attributes              = text-attributes(intensity: $bright-intensity);

define function result-status-to-text-attributes
    (result :: <result-status>)
 => (ansi-codes :: <text-attributes>)
  select (result)
    $passed => $passed-text-attributes;
    $failed => $failed-text-attributes;
    $crashed => $crashed-text-attributes;
    $skipped => $skipped-text-attributes;
    $expected-failure => $expected-failure-text-attributes;
    $unexpected-success => $unexpected-success-text-attributes;
    $not-implemented => $not-implemented-text-attributes;
    otherwise =>
      error("Unrecognized test result status: %=.  This is a testworks bug.",
            result);
  end
end function;
