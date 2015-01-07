Testworks Usage
***************

.. current-library:: testworks
.. current-module:: testworks

.. contents::  Contents
   :local:

.. 1  Quick Start
   2  Defining Tests
     2.1  Assertions
     2.2  Tests
     2.3  Suites
   3  Organizing Your Test Suites
   4  Running Your Tests As A Stand-alone Application
   5  Reports
   6  Comparing Test Results
   7  Test Specifications
   8  Generating Test Specifications

Testworks is the Dylan unit testing harness.

See also: :doc:`reference`

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
     benchmark fn1-benchmark;
   end;

Tests contain arbitrary code plus assertions:

.. code-block:: dylan

   // Test fn1
   define test fn1-test ()
     let v = do-something();
     assert-equal(fn1(v), "expected-value");
     assert-equal(fn1(v, key: 7), "seven", "regression test for bug/12345");
   end;

Benchmarks do not require any assertions and are automatically given
the "benchmark" tag:

.. code-block:: dylan

   // Benchmark fn1
   define benchmark fn1-benchmark ()
     fn1()
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
  * :func:`assert-instance?`
  * :func:`assert-not-instance?`

Each of these takes an optional description string, after the required
arguments, which will be displayed if the assertion fails.  If the
description isn't provided, Testworks makes one from the expressions
passed to the assertion macro.

In general, Testworks should be pretty good at reporting the actual
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

    define test NAME (#key DESCRIPTION, EXPECTED-FAILURE?, TAGS)
      BODY
    end;

For example:

.. code-block:: dylan

    define test my-test (description: "A sample test")
      assert-equal(2, 3);
      assert-equal(#f, #f);
      assert-true(identity(#t), "Check identity function");
    end test my-test;

*Note: if a test doesn't execute any assertions then it will be
marked as "not implemented" in the test results.*

The result looks like this::

    $ _build/bin/my-test 
    Running test my-test:
      2 = 3: [2 (from expression "2") and 3 (from expression "3") are not =.]
       FAILED in 0.000256s

    my-test FAILED in 0.000256 seconds:
      Ran 0 suites: 0 passed (100.00000%), 0 failed, 0 skipped, 0 not implemented, 0 crashed
      Ran 1 test: 0 passed (0.0%), 1 failed, 0 skipped, 0 not implemented, 0 crashed
      Ran 0 benchmarks: 0 passed (0.0%), 0 failed, 0 skipped, 0 not implemented, 0 crashed
      Ran 3 checks: 2 passed (66.666672%), 1 failed, 0 skipped, 0 not implemented, 0 crashed

Tests may be tagged with arbitrary strings, providing a way to select
or filter out tests to run:

.. code-block:: dylan

    define test my-test-2 (tags: #["huge"])
      ...huge test that takes a long time...
    end test;

    define test my-test-3 (tags: #["huge", "verbose"])
      ...test with lots of output...
    end test;

Tags can then be passed on the Testworks command-line.  For example,
this will skip both of the above tests::

    $ _build/bin/my-test-suite-app --tag=-huge --tag=-verbose

Negative tags take precedence, so ``--tag=huge --tag=-verbose`` will
run ``my-test-2`` and skip ``my-test-3``.

If the test is expected to fail, or fails under some conditions, Testworks
can be made aware of this:

.. code-block:: dylan

    define test failing-test (expected-failure?: #t)
      assert-true(#f);
    end test;

    define test fails-on-windows
        (expected-failure?: method () $os-name = #"win32" end)
      if ($os-name = #"win32")
        assert-false(#t);
      else
        assert-true(#t);
      end if;
    end test;

A test that is expected to fail and then fails will be considered to
be a passing test. If the test succeeds unexpectedly, it will be considered
a failing test.

Benchmarks
----------

Benchmarks are like tests except for:

* They do not require any assertions
* They are automatically assigned the "benchmark" tag.

The :macro:`benchmark-definer` macro is like :macro:`test-definer`:

.. code-block:: dylan

   define benchmark my-benchmark ()
     ...body...
   end;

Benchmarks may be added to suites:

.. code-block:: dylan

   define suite my-benchmarks-suite ()
     benchmark my-benchmark;
   end;

Benchmarks and tests may be combined in the same suite.  If you do
that, tags may be used to run only the benchmarks (with
``--tag=benchmark``) or only the tests (with ``--tag=-benchmark``).
This may be sufficient for small projects with a single test suite
application.  A better option for large projects (e.g., those that
combine test suites from various libraries) is to have separate suites
for benchmarks and tests.  Example:

.. code-block:: dylan

   define suite strings-tests () ...only tests... end;
   define suite strings-benchmarks () ...only benchmarks... end;
   define suite strings-test-suite ()
     suite strings-tests;
     suite strings-benchmarks;
   end;


Suites
------

Suites contain tests, benchmarks, and other suites. A suite may be
defined with the :macro:`suite-definer` macro.  The format is:

.. code-block:: dylan

    define suite NAME (#key description, setup-function, cleanup-function)
        test TEST-NAME;
        benchmark BENCHMARK-NAME;
        suite SUITE-NAME;
    end;

For example:

.. code-block:: dylan

    define suite first-suite (description: "my first suite")
      test my-test;
      test example-test;
      test my-test-2;
      benchmark my-benchmark;
    end;
    define suite second-suite ()
      suite first-suite;
      test my-test;
    end;

Suites can specify setup and cleanup functions using the keyword
arguments ``setup-function`` and ``cleanup-function``. These can be
used for things like establishing database connections, initializing
sockets and so on.

A simple example of doing this can be seen in the http-server test
suite:

.. code-block:: dylan

    define suite http-test-suite (setup-function: start-sockets)
      suite http-server-test-suite;
      suite http-client-test-suite;
    end;

Suites can be run via :func:`run-test-application`.  It should be
called as the main function in an executable and will parse
command-line args, execute tests and benchmarks, and generate reports.
See the next section for details.


Organizing Your Test Suites
===========================

Tests are used to combine related assertions into a unit, and suites
further organize related tests.  Suites may also contain other suites.

It is common for the test suite for library xxx to export a single
test suite named xxx-test-suite, which is further subdivided into
sub-suites, tests, and benchmarks as appropriate for that library.
The main test suite is exported so that it can be included as a
component suite in combined test suites that cover multiple related
libraries.

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
      benchmark my-awesome-benchmark;
      suite my-awesome-other-suite;
      ...
    end;

    define test my-awesome-test ()
      assert-true(...);
      assert-equal(...);
      ...
    end;

    define benchmark my-awesome-benchmark ()
      awesomely-slow-function();
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

Test specifications are written using the ``testworks-specs`` library
along side the usual ``testworks`` library.

While tests are normally structured as a hierarchy of test suites
containing tests, specifications follow a structure more like Dylan
code:

* Library specifications.
* Module specifications.
* Class, function, constant, variable and macro specifications.

Library and module specifications are typically placed in a file
named ``specification.dylan`` which is listed last in the associated
LID file.

These specifications consist of two sorts of checks:

* An automated validation that the interface in the specification
  matches what the library actually provides.
* The usual tests, provided by the programmer.

Library Specifications
----------------------

A library specification lists the modules that the library contains
as well as additional tests and suites which should be run when the
library specification is checked.

.. code-block:: dylan

   define library-spec io ()
     module streams;
     modules pprint;

     suite format-test-suite;
   end library-spec io;

Due to implementation issues, the *library-spec* must be parsed by the
Dylan compiler **after** the module specifications that are listed as
well as after any of the additional suites or tests.

Module Specifications
---------------------

A module specification lists the bindings that are exported by the
module. These bindings are expressed in a format similar to the usual
definitions.

A simple module specification might look like:

.. code-block:: dylan

   define module-spec pprint ()
     variable *print-miser-width*   :: false-or(<integer>);
     variable *default-line-length* :: <integer>;

     sealed instantiable class <pretty-stream> (<stream>);

     function pprint-logical-block (<stream>) => ();
     function pprint-newline (one-of(#"linear", #"fill", #"miser", #"mandatory"), <stream>) => ();
     function pprint-indent (one-of(#"block", #"current"), <integer>, <stream>) => ();
     function pprint-tab (one-of(#"line", #"line-relative", #"section", #"section-relative"), <integer>, <integer>, <stream>) => ();

     macro-test printing-logical-block-test;
   end module-spec pprint;

   define module-spec print ()
     ...
     open generic-function print-object (<object>, <stream>) => ();
     ...
   end module-spec print;

There are a couple of things to note here:

* Macros are mentioned as ``macro-test`` and their test names have ``-test``
  appended to the macro name already.
* Generic functions are listed as ``generic-function``.
* Generic functions, regular functions and classes can have adjectives listed.

Actual Tests
------------

Once your library and module specifications have been written, you can provide
actual test implementations for each of your specified bindings. In fact, you
must provide at least an empty test for each binding listed in your module
specifications.

These are done using the ``class-test``, ``function-test``, ``variable-test``,
``constant-test`` and ``macro-test`` definer macros.

These all follow the same pattern, demonstrated here for a function test:

.. code-block:: dylan

   define pprint function-test pprint-newline ()
     //---*** Fill this in...
   end function-test pprint-newline;

You can see that the *module name* is given as an adjective between ``define``
and ``function-test``.

Within the test implementation, you can use all of the usual ``testworks``
checks and assertions. Unlike tests defined via ``define test``, tests
defined using ``testworks-specs`` default to not failing when they are
not yet implemented.

Testing Classes
---------------

When testing classes, there are a couple of additional things to be aware
of. If your class is ``instantiable``, as indicated by using the adjective
``instantiable`` on your class binding in the module specification, then
``testworks-specs`` will attempt to instantiate your class to be sure that
it can do so without errors. If your class requires parameters or anything
special, then you will need to provide a specialization of the generic function
``make-test-instance``:

.. code-block:: dylan

   define sideways method make-test-instance
       (class == <machine-word>)
    => (instance :: <machine-word>);
     make(<machine-word>, value: 1729)
   end method make-test-instance;

Additionally, you may optionally provide a specialization of the generic
function ``class-test-function`` which will be automatically run by
``testworks-specs`` and should return a function which will then be run
by ``testworks-specs`` to perform additional tests for the class. An example
of this can be found in ``sources/dylan/tests/numbers.dylan``.

Multiple Tests
--------------

In many situations, multiple tests for a single binding are required. The way
that this should be done using ``testworks-specs`` is currently evolving.

*** To be filled in ***

Examples
--------

There are many examples of tests using ``testworks-specs`` in the Open Dylan
code base:

* ``sources/common-dylan/tests/``
* ``sources/duim/tests/``
* ``sources/dylan/tests/``
* ``sources/io/tests/``
* ``sources/lib/jam/tests/``
* ``sources/lib/llvm/tests/``
* ``sources/system/tests/``

Generating Test Specifications
==============================

*** To be filled in ***

