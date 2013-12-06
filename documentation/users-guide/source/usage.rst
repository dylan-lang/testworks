Usage
*****

.. current-library:: testworks
.. current-module:: testworks

.. TOC (C-c C-t TAB to insert a new TOC)
   1   Quick Start
   2   Defining Tests
     2.1  Assertions
     2.2  Tests
     2.3  Suites
   3   Organzing Your Test Suites
   4   Running Your Tests As A Stand-alone Application
   5   Setup and Cleanup Functions
   6   Tags
   7   Report Functions
   8   Progress Functions
   9   Comparing Test Results
   10  Test Specifications
   11  Generating Test Specifications

Quick Start
===========

For the impatient, this section summarizes most of what you need to
know to use Testworks.

Add ``use testworks;`` to both your test library and test module.

Suites are used to organize tests into groups and may be nested
arbitrarily.  It is common to have a top-level suite named
*my-library*-test-suite.

.. code-block:: dylan

   // Top-level test suite for the "example" library.
   define suite example-test-suite ()
     suite module1-test-suite;
     suite module2-test-suite;
     test fn1-test;
     test fn2-test;
   end;

Tests contain arbitrary code containing assertions:

.. code-block:: dylan

   // Test fn1
   define test fn1-test ()
     let v = do-something();
     assert-equal(fn1(v), "expected-value");
     assert-equal(fn1(v, key: 7), "seven", "regression test for bug/12345");
   end;

See also: :func:`assert-true`, :func:`assert-false`,
:func:`assert-signals`, and :func:`assert-no-errors`.  Each of these
takes an optional *description* argument, which can be used to
indicate the intent of the assertion if it isn't clear.

To run the test suite call
``run-test-application(example-test-suite)``.

You may want to have both an "example-test-suite" library, which
exports your top-level test suite so it can be included as a sub-suite
in other testing libraries, and an "example-test-suite-app"
executable, which can be used to run just the tests for "example"
itself.  See `Running Your Tests As A Stand-alone Application`_.

:func:`run-test-application` handles parsing the command line and
running the suite.  Use ::

  example-test-suite-app --help

to see the command-line options.


Defining Tests
==============

Assertions
----------

An assertion accepts an expression to evaluate and report back on,
saying if the expression passed, failed, or signaled an
error.  As an example, in

.. code-block:: dylan

    assert-true(foo > bar)

the expression ``foo > bar`` is compared to ``#f``, and the result is
recorded by the test harness.  Failing (or crashing) assertions do not
cause the test to terminate; all assertions are run unless the test
itself signals an error.

See the :doc:`reference` for detailed documentation on the available
assertion macros:

  * :func:`assert-true`
  * :func:`assert-false`
  * :func:`assert-equal`
  * :func:`assert-not-equal`
  * :func:`assert-signals`
  * :func:`assert-no-errors`

Each of these takes an optional description string, after the required
arguments, which will be displayed if the assertion fails.  If the
description isn't provided, Testworks makes one from the expressions
passed to the assertion macro.

In general, testworks should be pretty good at reporting the actual
values that caused the failure so it shouldn't be necessary to include
them in the description.

In the future, there will be support for failures to include the
source file line number for the assertion.

  *Note: You may also find check-\* macros in Testworks test suites.
  These are a deprecated form of assertion.  The only real difference
  between them and the assert-\* macros is that they require a
  description of the assertion as the first argument.*


Tests
-----

Tests contain assertions and arbitrary code needed to support those
assertions. Each test is part of a suite.  Use the
:macro:`test-definer` macro to define a test:

.. code-block:: dylan

    define test NAME (#key DESCRIPTION)
      BODY
    end;

For example:

.. code-block:: dylan

    define test my-test (description: "A sample test")
      assert-equal(2, 3);
      assert-equal(#f, #f);
      assert-true(identity(#t), "Check indentity function");
    end test my-test;

*Note: if a test doesn't execute any assertions then it will be
marked as "not implemented" in the test results.*

Once a test has been defined, it can be executed using the function
:func:`run-tests`. For example:

.. code-block:: dylan

    let runner = make(<test-runner>);
    run-tests(runner, my-test);

The result is output like this::

    $ _build/bin/my-test 
    Running test my-test:
      2 = 3: [2 (from expression "2") and 3 (from expression "3") are not =.]
       FAILED in 0.000256s

    my-test FAILED in 0.000256 seconds:
      Ran 0 suites: 0 passed (100.00000%), 0 failed, 0 skipped, 0 not implemented, 0 crashed
      Ran 1 test: 0 passed (0.0%), 1 failed, 0 skipped, 0 not implemented, 0 crashed
      Ran 3 checks: 2 passed (66.666672%), 1 failed, 0 skipped, 0 not implemented, 0 crashed

Tests may be tagged with arbitrary keywords, providing a way to filter
which tests are run:

.. code-block:: dylan

    define test my-test-2 (tags: #[huge:])
      ...huge test that takes a long time...
    end test;

Tags can then be passed on the Testworks command-line.  For example,
this will skip all tests tagged ``huge:``::

    $ _build/bin/my-test-suite-app --tags="-huge",

*Note: As of this writing the --tags command-line option hasn't
been implemented, but is expected Real Soon Now.*

Suites
------

Suites contain tests and other suites. A suite may be defined with the
:macro:`suite-definer` macro.  The format is:

.. code-block:: dylan

    define suite NAME (#key description, setup-function, cleanup-function)
        test TEST-NAME;
        suite SUITE-NAME;
    end;

For example:

.. code-block:: dylan

    define suite first-suite (description: "my first suite")
      test my-test;
      test example-test;
      test my-test-2;
    end;
    define suite second-suite ()
      suite first-suite;
      test my-test;
    end;

Suites can specify setup and cleanup functions using the keyword
arguments ``setup-function`` and ``cleanup-function``. These can be
used for things like establishing database connections, initializing
sockets and so on.

A simple example of doing this can be seen in Koala, an HTTP server:

.. code-block:: dylan

    define suite http-test-suite (setup-function: start-sockets)
      suite http-server-test-suite;
      suite http-client-test-suite;
    end suite koala-test-suite;

Similar to tests, suites may also be run with :func:`run-tests`.
Normally, however, :func:`run-test-application` is used.  It may be
called as the main function in an executable and it will parse
command-line args, generate reports, and more.  See the next section
for details.


Organzing Your Test Suites
==========================

Tests are used to combine related assertions into a unit and suites
further organize related tests.  Suites may also contain other suites.

It is common for the test suite for library xxx to export a single
test suite named xxx-test-suite, which is further subdivided into
sub-suites and tests as appropriate for that library.  The test suite
is exported so that it can be included as a component suite in
combined test suites that cover multiple related libraries.

The overall structure of a test library may look something like this:

.. code-block:: dylan

    // --- library.dylan ---
    define library xxx-tests
      use common-dylan;
      use testworks;
      use xxx;                 // the library you are testing
      export xxx-tests;        // so other test libs can include it
    end;

    define module xxx-tests
      use common-dylan;
      use testworks;
      use xxx;                 // the module you are testing
      export xxx-test-suite;   // so other suites can include it
    end;

    // --- main.dylan ---
    define suite xxx-test-suite ()
      test my-awesome-test;
      suite my-awesome-other-suite;
      ...
    end;

    define test my-awesome-test ()
      assert-true(...);
      assert-equal(...);
      ...
    end;

    run-test-application(my-test-suite);


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
into an executable with ``dylan-compiler -build xxx-test-suite-app.lid``.



Reports
=======

Testworks provides the user with multiple report functions:

Summary (the default)
  Prints out only a summary of how many assertions, tests and suites
  were executed, passed, failed or crashed.
Failures
  Prints out only the list of failures and a summary.
XML
  Outputs XML that directly matches the suite/test/assertion tree
  structure, with full detail.
Surefire
  Outputs XML is Surefire format.  This elides information about
  specific assertions.  This format is supported by various tools
  such as Jenkins.
None
  Prints nothing at all.

Use the ``--report-file`` option to redirect the report to a file.


Comparing Test Results
======================

*** To be filled in ***


Test Specifications
===================

*** To be filled in ***


Generating Test Specifications
==============================

*** To be filled in ***

