Module: %testworks
Synopsis: Utilities and code that needs to be loaded early.
Copyright: Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
           All rights reserved.
License: See License.txt in this distribution for details.
Warranty: Distributed WITHOUT WARRANTY OF ANY KIND


define constant $passed-attributes
  = text-attributes(foreground: $color-green);
define constant $skipped-attributes
  = text-attributes(foreground: $color-cyan);
define constant $not-implemented-attributes
  = text-attributes(foreground: $color-cyan);
define constant $failed-attributes
  = text-attributes(foreground: $color-red);
define constant $crashed-attributes
  = text-attributes(foreground: $color-red);
define constant $expected-failure-attributes
  = text-attributes(foreground: $color-cyan);
define constant $unexpected-success-attributes
  = text-attributes(foreground: $color-red);
define constant $component-name-attributes
  = text-attributes(intensity: $bright-intensity);
define constant $total-attributes
  = text-attributes(intensity: $bright-intensity);
define constant $count-attributes
  = text-attributes(intensity: $bright-intensity);

define function result-status-to-attributes
    (result :: <result-status>)
 => (ansi-codes :: <text-attributes>)
  select (result)
    $passed => $passed-attributes;
    $failed => $failed-attributes;
    $crashed => $crashed-attributes;
    $skipped => $skipped-attributes;
    $expected-failure => $expected-failure-attributes;
    $unexpected-success => $unexpected-success-attributes;
    $not-implemented => $not-implemented-attributes;
    otherwise =>
      error("Unrecognized test result status: %=.  This is a testworks bug.",
            result);
  end
end function result-status-to-attributes;
