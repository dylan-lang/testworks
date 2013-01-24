Usage
*****

.. current-library:: testworks
.. current-module:: testworks

Defining Tests
==============

Checks
------

Checks are the fundamental elements of writing a test-suite. A check
accepts an expression to evaluate and report back on, saying if the
expression passed, failed, or crashed. Checks are of the form:

.. code-block:: dylan

    check(name :: <string>, func :: <function>, #rest arguments);

Here the function is applied to the arguments, and the result is reported.
The following are some examples of simple checks::

    TESTWORKS 1 ?  check("Test less than operator", \<, 2, 3);
    Ran check: Test less than operator passed

    TESTWORKS 2 ? check("Test my method",
                    method (a, b, c) a + b = c end,
                    3, 5, 10);
    Ran check: Test my method failed

    TESTWORKS 3 ? check("Flamed check", \<, 5, 'c');
    Ran check: Flamed check crashed [No applicable methods for
               <STANDARD-GENERIC-FUNCTION < 1096F208> with args
               (5 #\c)]

    TESTWORKS 4 ? check("Bad Arguments", zero?, asdfdf);
    Ran check: Bad Arguments crashed [The variable
             DYLAN+DYLAN/TESTWORKS::ASDFDF is unbound]

There are five additional types of checks: :func:`check-equal`,
:func:`check-true`, :func:`check-false`, :func:`check-instance?`
and :func:`check-condition`. As the mnemonic names suggest they
are very useful in testing code in a variety of situations.

The format for :func:`check-equal` is:

.. code-block:: dylan

    check-equal(name :: <string>, expression-1, expression-2);

The objective of this check is to see if ``expression-1`` and ``expression-2``
evaluate to the same object.  Examples::

    TESTWORKS 7 ? check-equal("Test the addition operator", 4, 1 + 3);
    Ran check: Test the addition operator passed

    TESTWORKS 8 ? check-equal("Intentional failure", 3, 4);
    Ran check: Intentional failure failed [3 not = 4]

The format for :func:`check-true` is the following:

.. code-block:: dylan

    check-true(name :: <string>, expression);

Its objective is to see if the expression does not evaluate to ``#f``. An
example of this check would be::

    TESTWORKS 9 ? check-true("Test zero?", zero?(0));
    Ran check: Test zero? passed

:func:`check-false` is of the same form as :func:`check-true`, except that
it sees if the expression evaluates to ``#f``. If you want to explicitly
check if an expression evaluates to ``#t``, you should use :func:`check-equal`
to explicitly check.

The format for :func:`check-instance?` is the following:

.. code-block:: dylan

    check-instance?(name :: <string>, type, expression);

The objective of this check is to see if ``expression`` results in an
instance of ``type``.

:func:`check-condition` is the final variety of checks. Its basic format
is:

.. code-block:: dylan

    check-condition(name :: <string>, the-condition :: subclass(<condition>), expression);

This check determines if the evaluation of expression results in
an instance of ``the-condition`` being signaled.  Examples::

    TESTWORKS 10 ? check-condition("Raise simple-error", <simple-error>,
                                   error("My simple error"));
    Ran check: Raise simple-error passed

    TESTWORKS 11? check-condition("Look for wrong error",
                                  <end-of-stream-error>,
                                  signal(make(<error>)));
    Ran check: Look for wrong error crashed [The variable
             DYLAN+DYLAN/TESTWORKS::<END-OF-STREAM-ERROR> is
             unbound.]


Tests
-----

Tests are objects which contain checks and any arbitrary code. Tests
may be defined with a set of optional arguments, namely:

 * ``name``: A required keyword - an instance of ``<string>``.
 * ``description``: An instance of ``<string>``.

Tests are of the format:

.. code-block:: dylan

    define test _name_ (#key description)
      body
    end test _name_;

An example of a simple test is:

.. code-block:: dylan

    define test my-test (description: "A sample test")
      check-equal("Basic integer test", 2, 2);
      check-equal("Basic boolean test", #f, #f);
      check("Check indentity function", identity, #t);
    end test my-test;

Once a test has been defined, it can be executed using the function
:func:`perform-test`. For example::

    TESTWORKS 13 ? perform-test(my-test);
    MY-TEST passed

    MY-TEST summary:
      Ran 0 suites: 0 passed (100%), 0 failed, 0 not executed, 0 crashed
      Ran 1 test:  1 passed (100.0%), 0 failed, 0 not executed, 0 crashed
      Ran 3 checks: 3 passed (100.0%), 0 failed, 0 not executed, 0 crashed

    TESTWORKS 14 ? define test example-test ()
                       check-equal("Symbol test", #"ChickEN", #"chICken");
                       check-equal("Integer failure", 2, 3);
                       check-true("Passes", #t);
                       check("Fails", instance?, #t, <integer>);
                   end test example-test;

    TESTWORKS 15 ? perform-test(example-test);

    EXAMPLE-TEST failed
      Integer failure failed [2 not = 3]
      Fails failed

    EXAMPLE-TEST summary:
      Ran 0 suites: 0 passed (100%), 0 failed, 0 not executed, 0 crashed
      Ran 1 test:  0 passed (0.0%), 1 failed, 0 not executed, 0 crashed
      Ran 4 checks: 2 passed (50.0%), 2 failed, 0 not executed, 0 crashed


Suites
------

Suites are objects which contain tests and other suites. A suite may be
defined with the following arguments:

 * ``name``: A required keyword - an instance of ``<string>``.
 * ``description``: An instance of ``<string>``.
 * ``setup-function``: An instance of ``<function>``.
 * ``cleanup-function``: An instance of ``<function>``.

The format of a suite is:

.. code-block:: dylan

    define suite _name_ (#key description, setup-function, cleanup-function)
        test _name_;
        suite _name_;
    end suite;

Some examples are:

.. code-block:: dylan

    define suite my-suite (description: "my first suite")
      test my-test;
      test example-test;
      test my-test-2;
    end;
    define suite second-suite ()
      suite my-suite;
      test my-test;
    end;

Similar to :func:`perform-test`, there is a function called
:func:`perform-suite` which is used to execute the suite::

    TESTWORKS 28 ? perform-suite(my-suite);
    MY-SUITE failed

    EXAMPLE-TEST failed
          Integer failure failed [2 not = 3]
          Fails failed

    MY-SUITE summary:
      Ran 1 suite:  0 passed (0.0%), 1 failed, 0 not executed, 0 crashed
      Ran 3 tests: 2 passed (66.7%), 1 failed, 0 not executed, 0 crashed
      Ran 8 checks: 6 passed (75.0%), 2 failed, 0 not executed, 0 crashed


Organzing Your Test Suites
==========================

Tests and suites should be viewed as "super" objects to organize and
observe control over checks.  The test suite library may look something like:

.. code-block:: dylan

    define library xxx-test-suite
      use dylan;
      use testworks;
      use xxx;       // <- the library you are testing
    end library;

The number of checks per test should be kept to a minimum since it is
much easier to track failures and errors in smaller tests. Putting
names on checks and descriptions on tests and suites is something that
is often ignored. It might seem like too much work at first but
introducing names and descriptions allows better error tracking and
saves significant time by providing information at a glance.

(In the future, there should be support for check failures to include
the source file line number for the check, but even then the check
name can be useful, for example if it is being run inside a loop.)

Tests can be used to combine similar checks into a unit and suites can
further organize similar or related tests into units.

It is common for the test suite for library xxx to export a single
test suite named xxx-test-suite, which is further subdivided into
sub-suites and tests as appropriate for that library.  The test suite
is exported so that it can be included in combined test suites that
cover multiple related libraries.


Running Your Tests As A Stand-alone Application
===============================================

Just exporting your main test suite from your test library doesn't do
you much good unless something actually runs that suite.  The standard
way to run the test suite as an application is to define an
application library named "xxx-test-suite-app" which calls
:func:`run-test-application` on the "xxx-test-suite".

Here's an example of such an application library:

1. The file ``library.dylan`` which must use at least the library that
exports the test suite, and ``testworks``:

.. code-block:: dylan

    Module:    dylan-user
    Synopsis:  An application library for xxx-test-suite

    define library xxx-test-suite-app
      use xxx-test-suite;
      use testworks;
    end;

    define module xxx-test-suite-app
      use xxx-test-suite;
      use testworks;
    end;

2. The file ``xxx-test-suite-app.dylan`` which simply contains a call
to the method :func:`run-test-application` with the suite-name as an
argument:

.. code-block:: dylan

    Module: xxx-test-suite-app

    run-test-application(xxx-test-suite);

3. The file ``xxx-test-suite-app.lid`` which specifies the names of
the source files:

.. code-block:: dylan

    Library: xxx-test-suite-app
    Target-type: executable
    Files: library
           xxx-test-suite-app

Once a library has been defined in this fashion it can be compiled
into an executable using a compiler like Open Dylan's ``dylan-compiler``.


Setup and Cleanup Functions
============================

Suites can specify setup and cleanup functions using the keyword arguments
``setup-function`` and ``cleanup-function``. These can be used for things
like establishing database connections, initializing sockets and so on.

A simple example of doing this can be seen in Koala, an HTTP server:

.. code-block:: dylan

    define suite koala-test-suite
        (setup-function: start-sockets)
      suite http-server-test-suite;
      suite http-client-test-suite;
    end suite koala-test-suite;


Tags
====

An additional slot on :class:`<test>` and :class:`<suite>` objects is
``tags``: - an instance of ``<sequence>``.

The ``tags`` argument to :func:`perform-test` and :func:`perform-suite`
controls whether a test defined with certain tags is performed or not.
Tags are either a list of symbols or the constant :const:`$all`.
For example:

.. code-block:: dylan

    define test my-test-2 (tags: #[#"one", #"two"])
      let a = 2;
      check-equal("Let test", a, 2);
    end test;

::

    TESTWORKS 21 ? perform-test(my-test-2, tags: #[#"one"]);
    MY-TEST-2 passed

    MY-TEST-2 summary:
      Ran 0 suites: 0 passed (100%), 0 failed, 0 not executed, 0  crashed
      Ran 1 test:  1 passed (100.0%), 0 failed, 0 not executed, 0 crashed
      Ran 1 check:  1 passed (100.0%), 0 failed, 0 not executed, 0 crashed

    TESTWORKS 22 ? perform-test(my-test-2, tags: #[#"two", #"three"]);
    MY-TEST-2 passed

    MY-TEST-2 summary:
      Ran 0 suites: 0 passed (100%), 0 failed, 0 not executed, 0 crashed
      Ran 1 test:  1 passed (100.0%), 0 failed, 0 not executed, 0 crashed
      Ran 1 check:  1 passed (100.0%), 0 failed, 0 not executed, 0 crashed

    TESTWORKS 23 ? perform-test(my-test-2,
                tags: #[#"four", #"five", #"turkey"]);
    MY-TEST-2 passed

    MY-TEST-2 summary:
      Ran 0 suites: 0 passed (100%), 0 failed, 0 not executed, 0 crashed
      Ran 0 tests: 0 passed (100%), 0 failed, 1 not executed, 0 crashed
      Ran 0 checks: 0 passed (100%), 0 failed, 0 not executed, 0 crashed

    TESTWORKS 24 ? perform-test(my-test-2, tags: $all);
    MY-TEST-2 passed

    MY-TEST-2 summary:
      Ran 0 suites: 0 passed (100%), 0 failed, 0 not executed, 0 crashed
      Ran 1 test:  1 passed (100.0%), 0 failed, 0 not executed, 0 crashed
      Ran 1 check:  1 passed (100.0%), 0 failed, 0 not executed, 0 crashed

    TESTWORKS 25 ? perform-test(my-test-2,
                tags: #[#"one", #"water", #"two"]);
    MY-TEST-2 passed

    MY-TEST-2 summary:
      Ran 0 suites: 0 passed (100%), 0 failed, 0 not executed, 0 crashed
      Ran 1 test:  1 passed (100.0%), 0 failed, 0 not executed, 0 crashed
      Ran 1 check:  1 passed (100.0%), 0 failed, 0 not executed, 0 crashed

If tags is set to ``$all``, then the test will be performed regardless of
its tags. By default ``tags = $all``.


Report Functions
================

Testworks provides the user with multiple report functions:

:func:`summary-report-function`
  Prints out only a summary of how many checks, tests and suites
  were executed, passed, failed or crashed.
:func:`failures-report-function`
  Prints out only the list of failures and a summary.
:func:`full-report-function`
  Prints the result of every single check - whether it passed, failed
  or crashed and then a summary at the end.
:func:`null-report-function`
  Prints nothing at all.

The default is the :func:`failures-report-function`.


Progress Functions
==================

At present there is only one progress function provided by Testworks
which is the :func:`full-progress-function`. This essentially prints
the outcome of each check as soon as the check is executed. The advantage
of this is very obvious when running large suites as it may take some
time before the entire suite is executed (reports are printed in the end).
So, a user can get "active" information as the check gets executed. This
option can be disabled by using the :func:`null-progress-function`. The
default is the :func:`full-progress-function`.


Comparing Test Results
======================

*** To be filled in ***


Test Specifications
===================

*** To be filled in ***


Generating Test Specifications
==============================

*** To be filled in ***

