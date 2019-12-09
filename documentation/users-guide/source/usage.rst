Testworks Usage
***************

.. current-library:: testworks
.. current-module:: testworks

.. contents::  Contents
   :local:

Testworks is a Dylan unit testing library.

See also: :doc:`reference`

Quick Start
===========

For the impatient, this section summarizes most of what you need to know to use
Testworks.

Add ``use testworks;`` to both your test library and test module.

Tests contain arbitrary code and at least one assertion:

.. code-block:: dylan

   define test test-fn1 ()
     let v = do-something();
     assert-equal(fn1(v), "expected-value");
     assert-equal(fn1(v, key: 7), "seven", "regression test for bug/12345");
   end;

If there are no assertions in a test it is considered "not implemented", which
is displayed in the output (as a reminder to implement it) but is not
considered a failure.

See also: :func:`assert-true`, :func:`assert-false`, :func:`assert-signals`,
and :func:`assert-no-errors`.  Each of these takes an optional *description*
argument, which can be used to indicate the intent of the assertion if it isn't
clear.

Benchmarks do not require any assertions and are automatically given the
"benchmark" tag:

.. code-block:: dylan

   // Benchmark fn1
   define benchmark fn1-benchmark ()
     fn1()
   end;

See also, :func:`benchmark-repeat`.

If you have a large or complex test library, "suites" may be used to organize
tests into groups (for example one suite per module) and may be nested
arbitrarily.

.. code-block:: dylan

   define benchmark benchmark-fn1 ()
     fn1()
   end;

**Note:** Suites must be defined textually after* the other suites and tests
they contain.

To run your tests of course you need an executable and there are two ways to
accomplish this:

1.  Compile your test library as an executable and call
    :func:`run-test-application` (with no arguments) to parse the Testworks
    command-line options and run all tests. For example, for the `foo-test`
    library::

      _build/bin/foo-test

1.  Compile your test library as a shared library and run it with the
    `testworks-run` application. For example, for the `foo-test` library::

      _build/bin/testworks-run --load libfoo-test.so

In both cases :func:`run-test-application` parses the command line so the
options are the same. Use `--help` to see all options.

See `Suites`_ for a way to organize large test suites.

Defining Tests
==============

Assertions
----------

An assertion accepts an expression to evaluate and report back on,
saying if the expression passed, failed, or signaled an
error.  As an example, in

.. code-block:: dylan

    assert-true(foo > bar)

the expression ``foo > bar`` is compared to ``#f``, and the result is recorded
by the test harness.  Failing (or crashing) assertions do not cause the test to
terminate; all assertions are run unless the test itself signals an
error. (**NOTE:** See https://github.com/dylan-lang/testworks/issues/86 for
plans to change this behavior.)

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
passed to the assertion macro. For example, ``assert-true(2 > 3)``
produces this failure message::

  (2 > 3) is true failed [expression "(2 > 3)" evaluates to #f]

In general, Testworks should be pretty good at reporting the actual
values that caused the failure so it shouldn't be necessary to include
them in the description all the time.

In the future, there will be support for failures to include the
source file line number for the assertion.

  *Note: You may also find check-\* macros in Testworks test suites.
  These are a deprecated form of assertion.  The only real difference
  between them and the assert-\* macros is that they require a
  description of the assertion as the first argument.*


Tests
-----

Tests contain assertions and arbitrary code needed to support those
assertions. Each test may be part of a suite.  Use the
:macro:`test-definer` macro to define a test:

.. code-block:: dylan

    define test NAME (#key EXPECTED-FAILURE?, TAGS)
      BODY
    end;

For example:

.. code-block:: dylan

    define test my-test ()
      assert-equal(2, 3);
      assert-equal(#f, #f);
      assert-true(identity(#t), "Check identity function");
    end;

*Note: if a test doesn't execute any assertions then it is marked as
"not implemented" in the test results.*

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
this skips both of the above tests::

    $ _build/bin/my-test-suite-app --tag=-huge --tag=-verbose

Negative tags take precedence, so ``--tag=huge --tag=-verbose`` runs
``my-test-2`` and skips ``my-test-3``.

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

A test that is expected to fail and then fails is considered to be a
passing test. If the test succeeds unexpectedly, it is considered a
failing test.

Test setup and teardown is accomplished with normal Dylan code using
``block () ... cleanup ... end;``...

.. code-block:: dylan

   define test foo ()
     block ()
       do-setup-stuff();
       assert-equal(...);
       assert-equal(...);
     cleanup
       do-teardown-stuff()
     end
   end;

Benchmarks
----------

Benchmarks are like tests except for:

* They do not require any assertions. (They pass unless they signal an error.)
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
If you are using suites anyway, you may wish to put benchmarks into a
suite of their own.  Example:

.. code-block:: dylan

   define suite strings-tests () ...only tests... end;
   define suite strings-benchmarks () ...only benchmarks... end;
   define suite strings-test-suite ()
     suite strings-tests;
     suite strings-benchmarks;
   end;

**TODO**: link to ``benchmark-repeat`` reference doc when written

Suites
------

Suites are an optional feature that may be used to organize your tests
into a hierarchy.  Suites contain tests, benchmarks, and other
suites. A suite is defined with the :macro:`suite-definer` macro.  The
format is:

.. code-block:: dylan

    define suite NAME (#key setup-function, cleanup-function)
        test TEST-NAME;
        benchmark BENCHMARK-NAME;
        suite SUITE-NAME;
    end;

For example:

.. code-block:: dylan

    define suite first-suite ()
      test my-test;
      test example-test;
      test my-test-2;
      benchmark my-benchmark;
    end;

    define suite second-suite ()
      suite first-suite;
      test my-test;
    end;

Suites can specify setup and cleanup functions via the keyword
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


Interface Specification Suites
------------------------------

The :macro:`interface-specification-suite-definer` macro creates a normal test
suite, much like ``define suite`` does, but based on an interface
specification. For example,

.. code-block:: dylan

   define interface-specification-suite time-specification-suite ()
     sealed instantiable class <time> (<object>);
     constant $utc :: <zone>;
     variable *zone* :: <zone>;
     sealed generic function in-zone (<time>, <zone>) => (<time>);
     function now (#"key", #"zone") => (<time>);
     ...
   end;

The specification usually has one clause, or "spec", for each name exported
from your public interface module. Each spec creates a test named
``test-{name}-specification`` to verify that the implementation matches the
spec for ``{name}``. For example, by checking that the names are bound, that
their bindings have the correct types, that functions accept the right number
and types of arguments, etc.

Specification suites are otherwise just normal suites. They may include other
arbitrary tests and child suites if desired:

.. code-block:: dylan

   define interface-specification-suite time-suite ()
     ...
     test test-time-still-moving-forward;
     suite time-travel-test-suite;
   end;

This also means that if your interface is large you may use multiple
:macro:`interface-specification-suite-definer` forms and then group them
together.

See :macro:`interface-specification-suite-definer` for more details on the
various kinds of specs.


Organizing Tests for One Library
================================

If you don't use suites, the only organization you need is to name
your tests and benchmarks uniquely, and you can safely skip the rest
of this section.  If you do use suites, read on....

Tests are used to combine related assertions into a unit, and suites
further organize related tests and benchmarks.  Suites may also
contain other suites.

It is common for the test suite for library xxx to export a single
test suite named xxx-test-suite, which is further subdivided into
sub-suites, tests, and benchmarks as appropriate for that library.
Some suites may be exported so that they can be included as a
component suite in combined test suites that cover multiple related
libraries. (The alternative to this approach is running each library's
tests as a separate executable.)

**Note:** It is an error for a test to be included in a suite multiple times,
even transitively. Doing so would result in a misleading pass/fail ratio, and
it is more likely to be a mistake than to be intentional.

The overall structure of a test library that is intended to be
included in a combined test library may look something like this:

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

    define test my-awesome-test ()
      assert-true(...);
      assert-equal(...);
      ...
    end;

    define benchmark my-awesome-benchmark ()
      awesomely-slow-function();
    end;

    define suite xxx-test-suite ()
      test my-awesome-test;
      benchmark my-awesome-benchmark;
      suite my-awesome-other-suite;
      ...
    end;

Running Your Tests As A Stand-alone Application
===============================================

If you don't need to export any suites so they can be included in a
higher-level combined test suite library (i.e., if you're happy
running your test suite library as an executable) then you can simply
call ``run-test-application`` to parse the standard testworks
command-line options and run the specified tests::

  run-test-application();          // if not using suites
  run-test-application(my-suite);  // if using suites

and you can skip the rest of this section.

If you need to export a suite for use by another library, then you
must also define a separate executable library, traditionally named
"xxx-test-suite-app", which calls
``run-test-application(xxx-test-suite)``.

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
    Files: library.dylan
           xxx-test-suite-app.dylan

Once a library has been defined in this fashion it can be compiled
into an executable with ``dylan-compiler -build
xxx-test-suite-app.lid`` and run with ``xxx-test-suite-app --help``.


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

Quick version:

*  (master branch)$ my-test-suite --report json --report-file out1.json
*  (your branch)$ my-test-suite --report json --report-file out2.json
*  $ testworks-report out1.json out2.json
