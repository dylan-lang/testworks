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
expression passed, failed, or crashed. Checks are of the format:

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

    check-equal (name :: <string>, expression-1, expression-2);

The objective of this check is to see if ``expression-1`` and ``expression-2``.
evaluate to the same object. Some examples of this are::

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

    check-instance(name :: <string>, type, expression);

The objective of this check is to see if ``expression`` results in an
instance of ``type``.

:func:`check-condition` is the final variety of checks. Its basic format
is of the form:

.. code-block:: dylan

    check-condition(name :: <string>, the-condition :: <condition>, expression);

The objective of this check is to determine if the evaluation of expression
results in the same condition as ``the-condition``. Some simple examples of
the same would be::

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

    define test _name_ (#key all of the above mentioned arguments)
      body
    end test _name_;

An example of a simple test could be:

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

Thus, the format of a suite would be:

.. code-block:: dylan

    define suite _name_ (#key any of the arguments described above)
        test _name_;
        suite _name_;
    end suite;

Note: Suites must be defined after any included tests (and suites) are
defined.

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
observe control over checks. Normally a test-suite will be in its own
Dylan library. The test-suite library may look something like:

.. code-block:: dylan

    define library my-test-suite
      use dylan;
      use testworks;
      use xxx;       // <- the library you are testing
    end library;

It is recommended that tests contain no more than 10-15 checks. It
is much easier to track failures and errors in smaller tests . Putting
names on checks and descriptions on tests and suites is something that is
often ignored by many user's. It might seem like too much work at first
but introducing names and descriptions allow better error tracking and
save significant amounts of time by providing information at a glance,
saving a lot of time later. Tests can be used to combine similar checks
into a unit and suites can further organize similar or related tests into
units. Once all tests and suites have been created and organized into the
desired hierarchy, it is probably best to define a wrapper suite and
define all your tests and suites in that mother suite.


Running Your Tests As A Stand-alone Application
===============================================

Testworks has been designed and implemented with the  intention of
providing users the ability to create test applications that run as
executables. The function :func:`run-test-application` can be thought
of as a startup function for a defined test library. But as everything
in dylan must be defined in a module and library, this startup function
needs to be defined in a library of its own which by convention is the
``test-suite-`` name followed by ``-app``. For example, say we have defined
a test-suite called ``test-foo`` which  contains the definitions of all
its constituent suites and tests. Then the corresponding application
library would contain a minimum of three files which could be as
follows:

1. The file ``library.dylan`` which must use at least the library
being tested and ``testworks``:

.. code-block:: dylan

    Module:    dylan-user
    Synopsis:  An application library for test-foo

    define library test-foo-app
      use test-foo;
      use testworks-plus;
    end;

    define module test-foo-app
      use test-foo;
      use testworks-plus;
    end;

2. The file ``test-foo.dylan`` which simply contains a call to the method
:func:`run-test-application` with the suite-name as an argument:

.. code-block:: dylan

    Module:    test-foo-app
    Synopsis:  An application library for test-suite test-foo

    run-test-application(test-foo-suite);

3. The file ``test-foo.lid`` which specifies the names of the source files:

.. code-block:: dylan

    Library:   test-foo-app
    Synopsis:  An application library for test-suite test-foo
    Files: library
           test-foo-app

Once a library has been defined in this fashion it can be compiled
into an executable using a compiler like Open Dylan's ``dylan-compiler``


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

