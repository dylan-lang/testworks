Module:       testworks
Summary:      TestWorks a test harness library
Author:       Andrew Armstrong, Shri Amit, James Kirsch
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define constant $all-tags = #[#"all"];

/// Result handling

define constant $passed = #"passed";
define constant $failed = #"failed";
define constant $crashed = #"crashed";
define constant $skipped = #"skipped";
define constant $not-implemented  = #"nyi";

define constant <result-status>
  = one-of($passed, $failed, $crashed, $skipped, $not-implemented);

// It looks like this and testworks-reports:parse-status are meant to
// be inverses.
define method status-name
    (status :: <result-status>) => (name :: <string>)
  select (status)
    $passed => "passed";
    $failed => "failed";
    $crashed => "crashed";
    $skipped => "skipped";
    $not-implemented => "not implemented";
    otherwise =>
      error("Unrecognized test result status: %=.  This is a testworks bug.",
            status);
  end
end method status-name;

define class <result> (<object>)
  constant slot result-name :: <string>,
    required-init-keyword: name:;
  constant slot result-status :: <result-status>,
    required-init-keyword: status:;
end class <result>;

define generic result-reason
    (result :: <result>) => (reason :: false-or(<string>));

define method result-reason
    (result :: <result>) => (reason :: false-or(<string>))
  #f
end;

define open generic result-type-name
    (result :: <result>) => (name :: <string>);

define method \=
    (result1 :: <result>, result2 :: <result>)
 => (equal? :: <boolean>)
  result1.result-name = result2.result-name
  & (result1.result-status = result2.result-status
     | result1.result-reason = result2.result-reason)
end;


///*** State Variables ***///

define thread variable *debug?* = #f;

define thread variable *format-function* = format-out;

define thread variable *announce-checks?* :: <boolean> = #f;

define thread variable *announce-check-function* :: false-or(<function>) = #f;

define method announce-component
    (component :: <component>) => ()
  test-output("Running %s %s...\n",
              component.component-type-name, component.component-name);
end;

define thread variable *announce-function* :: false-or(<function>) = announce-component;

define method debug-failures?
    () => (debug-failures? :: <boolean>)
  *debug?* == #t
end method debug-failures?;

define method debug?
    () => (debug? :: <boolean>)
  *debug?* ~= #f
end method debug?;

define method test-output
    (format-string :: <string>, #rest format-args) => ()
  apply(*format-function*, format-string, format-args)
end method test-output;

///*** Generic Classes, Helper Functions, and Helper Macros ***///

define method plural (n :: <integer>) => (ending :: <string>)
  if (n == 1) "" else "s" end if
end;

define macro maybe-trap-errors
  { maybe-trap-errors (?body:body) }
    => { local method maybe-trap-errors-body () ?body end;
         if (*debug?*)
           maybe-trap-errors-body();
         else
           block ()
             maybe-trap-errors-body();
           exception (cond :: <serious-condition>)
             cond
           end;
         end; }
end macro maybe-trap-errors;

define method tags-match? (run-tags :: <sequence>, object-tags :: <sequence>)
 => (bool :: <boolean>)
  run-tags = $all-tags | ~empty?(intersection(run-tags, object-tags))
end method tags-match?;


/// Perform options

// this class defines all the options that might be used
// to control test suite performing.

define open class <perform-options> (<object>)
  slot perform-tags :: <sequence> = $all-tags,
    init-keyword: tags:;
  slot perform-announce-function :: false-or(<function>) = *announce-function*,
    init-keyword: announce-function:;
  slot perform-announce-checks? :: <boolean> = *announce-checks?*,
    init-keyword: announce-checks?:;
  slot perform-progress-format-function = *format-function*,
    init-keyword: progress-format-function:;
  slot perform-progress-function = *default-progress-function*,
    init-keyword: progress-function:;
  slot perform-debug? = *debug?*,
    init-keyword: debug?:;
end class <perform-options>;
