Testworks Reference
*******************

.. current-library:: testworks
.. current-module:: testworks

.. contents::  Contents
   :local:

.. 1  The Testworks Module
     1.1  Suites, Tests, and Benchmarks
     1.2  Assertions
     1.3  Checks
     1.4  Test Execution

See also: :doc:`usage`


The Testworks Module
====================

Suites, Tests, and Benchmarks
-----------------------------

.. macro:: test-definer

   Define a new test.

   :signature: define test *test-name* (#key *description, expected-failure?, tags*) *body* end
   :parameter test-name: Name of the test; a Dylan variable name.
   :parameter #key description: A string describing the purpose of the test.
   :parameter #key expected-failure?: An instance of either :drm:`<boolean>` or
      :drm:`<function>`. This indicates whether or not the test is expected to
      fail.
   :parameter #key tags: A list of strings to tag this test.

   Tests may contain arbitrary code, plus any number of assertions.
   If any assertion fails the test will fail, but any remaining
   assertions in the test will still be executed.  If code outside of
   an assertion signals an error, the test is marked as "crashed" and
   remaining assertions are skipped.

   If *expected-failure?* is set to ``#t`` or a function that when executed
   returns a true value, then the test will be expected to fail. Such a failure
   will be treated as a successful test run. If the test passes rather than
   failing, then that will be considered a test failure. This option has
   no effect on tests which are *not implemented* or which have *crashed*.

   *tags* provide a way to select or filter out specific tests during
   a test run.  The Testworks command-line (provided by
   :func:`run-test-application`) provides a ``--tag`` option for this
   purpose.

.. macro:: benchmark-definer

   Define a new benchmark.

   :signature: define benchmark *name* (#key *description, expected-failure?, tags*) *body* end
   :parameter name: Name of the benchmark; a Dylan variable name.
   :parameter #key description: A string describing the purpose of the benchmark.
   :parameter #key expected-failure?: An instance of either :drm:`<boolean>` or
      :drm:`<function>`. This indicates whether or not the test is expected to
      fail.
   :parameter #key tags: A list of strings to tag this benchmark.

   Benchmarks may contain arbitrary code and do not require any
   assertions.  If the benchmark signals an error it is marked as
   "crashed". Other than this, and some differences in how the results
   are displayed, benchmarks are the same as tests.

.. macro:: suite-definer

   Define a new test suite.

   :signature: define suite *suite-name* (#key *setup-function cleanup-function description*) *body* end
   :parameter suite-name: Name of the suite; a Dylan variable name.
   :parameter #key setup-function: A function to perform setup before the suite starts.
   :parameter #key cleanup-function: A function to perform teardown after the suite finishes.
   :parameter #key description: A string describing the purpose of the suite.

   Suites provide a way to group tests and other suites into a single
   executable unit.  Suites may be nested arbitrarily.

   *setup-function* is executed before any tests or sub-suites are
   run.  If *setup-function* signals an error the entire suite is
   skipped and marked as "crashed".

   *cleanup-function* is executed after all sub-suites and tests have
   completed, regardless of whether an error is signaled.

Assertions
----------

Assertions are the smallest unit of verification in Testworks.  They
must appear within the body of a test.

Assertion macros that accept an argument that is the expected value
as well as the expression that is to be tested typically expect the
value first and the expression second. The macros don't always require
that this be the case:

.. code-block:: dylan

    assert-not-equal(5, 2 + 2);
    assert-instance?(<integer>, 2 + 2);

All assertion macros accept a description of what is being tested as
an *optional* final argument.  The description should be stated in the
positive sense.  For example:

.. code-block:: dylan

    assert-equal(2, 2 + 2, "2 + 2 equals 2")

These are the available assertion macros:

  * :macro:`assert-true`
  * :macro:`assert-false`
  * :macro:`assert-equal`
  * :macro:`assert-not-equal`
  * :macro:`assert-signals`
  * :macro:`assert-no-errors`
  * :macro:`assert-instance?`
  * :macro:`assert-not-instance?`

.. macro:: assert-true

   Assert that an expression evaluates to a true value.  Importantly,
   this does not mean the expression is exactly ``#t``, but rather
   that it is *not* ``#f``.  If you want to explicitly test for
   equality to ``#t`` use ``assert-equal(#t, ...)`` or
   ``assert-true(#t = ...)``.

   :signature: assert-true *expression* [ *description* ]

   :parameter expression: any expression
   :parameter description: A description of what the assertion tests.
      This should be stated in positive form, such as "two is less
      than three".  If no description is supplied one will be
      automatically generated based on the text of the expression.

   :example:

      .. code-block:: dylan

         assert-true(has-fleas?(my-dog))
         assert-true(has-fleas?(my-dog), "my dog has fleas")

.. macro:: assert-false

   Assert that an expression evaluates to ``#f``.

   :signature: assert-false *expression* [ *description* ]

   :parameter expression: any expression
   :parameter description: A description of what the assertion tests.
      This should be stated in positive form, such as "three is less
      than two".  If no description is supplied one will be
      automatically generated based on the text of the expression.

   :example:

      .. code-block:: dylan

         assert-false(3 < 2)
         assert-false(6 = 7, "six equals seven")

.. macro:: assert-equal

   Assert that two values are equal using ``=`` as the comparison
   function.  Using this macro is preferable to using ``assert-true(a
   = b)`` because the failure messages are much better when comparing
   certain types of objects, such as collections.

   :signature: assert-equal *expression1* *expression2* [ *description* ]

   :parameter expression1: any expression
   :parameter expression2: any expression
   :parameter description: A description of what the assertion tests.
      This should be stated in positive form, such as "two equals
      two".  If no description is supplied one will be automatically
      generated based on the text of the two expressions.

   :example:

      .. code-block:: dylan

         assert-equal(2, my-complicated-method())
         assert-equal(this, that, "this and that are the same")

.. macro:: assert-not-equal

   Assert that two values are not equal using ``~=`` as the comparison
   function.  Using this macro is preferable to using ``assert-true(a
   ~= b)`` or ``assert-false(a = b)`` because the generated failure
   messages can be better.

   :signature: assert-not-equal *expression1* *expression2* [ *description* ]

   :parameter expression1: any expression
   :parameter expression2: any expression
   :parameter description: A description of what the assertion tests.
      This should be stated so as to express what the correct result
      would be, for example "two does not equal three".  If no
      description is supplied one will be automatically generated
      based on the text of the two expressions.

   :example:

      .. code-block:: dylan

         assert-not-equal(2, my-complicated-method())
         assert-not-equal(this, that, "this does not equal that")

.. macro:: assert-signals

   Assert that an expression signals a given condition class.

   :signature: assert-signals *condition*, *expression* [ *description* ]

   :parameter condition: an expression that yields a condition class
   :parameter expression: any expression
   :parameter description: A description of what the assertion tests.
      This should be stated in positive form, such as "two is less
      than three".  If no description is supplied one will be
      automatically generated based on the text of the expression.

   The assertion succeeds if the expected *condition* is signaled by
   the evaluation of *expression*.

   :example:

      .. code-block:: dylan

         assert-signals(<division-by-zero-error>, 3 / 0)
         assert-signals(<division-by-zero-error>, 3 / 0,
                        "my super special description")

.. macro:: assert-no-errors

   Assert that an expression does not signal any errors.

   :signature: assert-no-errors *expression* [ *description* ]

   :parameter expression: any expression 
   :parameter description: A description of what the assertion tests.
      This should be stated in positive form, such as "two is less
      than three".  If no description is supplied one will be
      automatically generated based on the text of the expression.

   The assertion succeeds if no error is signaled by the evaluation of
   *expression*.

   Use of this macro is preferable to simply executing *expression* as
   part of the test body for two reasons.  First, it can clarify the
   purpose of the test, by telling the reader "here's an expression
   that is explicitly being tested, and not just part of the test
   setup."  Second, if the assertion signals an error the test will
   record that fact and continue, as opposed to taking a non-local
   exit.  Third, it will show up in generated reports.

   :example:

      .. code-block:: dylan

         assert-no-errors(my-hairy-logic())
         assert-no-errors(my-hairy-logic(),
                          "hairy logic completes without error")


.. macro:: assert-instance?

   Assert that the result of an expression is an instance of a given type.

   :signature: assert-instance? *type* *expression* [ *description* ]

   :parameter type: The expected type.
   :parameter expression: An expression.
   :parameter description: A description of what the assertion tests.
      This should be stated in positive form, such as "two is less
      than three".  If no description is supplied one will be
      automatically generated based on the text of the expression.

   :description:

      .. warning:: The arguments to this assertion follow the typical
         argument ordering of Testworks assertions with the desired
         value before the expression that represents the test. As such,
         the desired *type* is the first parameter to this assertion
         while it is the second parameter for :drm:`instance?`.

   :example:

     .. code-block:: dylan

       assert-instance?(<type>, subclass(<string>));

       assert-instance?(<type>, subclass(<string>),
                        "subclass returns type");


.. macro:: assert-not-instance?

   Assert that the result of an expression is **not** an instance of a given class.

   :signature: assert-not-instance? *type* *expression* [ *description* ]

   :parameter type: The type.
   :parameter expression: An expression.
   :parameter description: A description of what the assertion tests.
      This should be stated in positive form, such as "two is less
      than three".  If no description is supplied one will be
      automatically generated based on the text of the expression.

   :description:

      .. warning:: The arguments to this assertion follow the typical
         argument ordering of Testworks assertions with the desired
         value before the expression that represents the test. As such,
         the desired *type* is the first parameter to this assertion
         while it is the second parameter for :drm:`instance?`.

   :example:

     .. code-block:: dylan

       assert-not-instance?(limited(<integer>, min: 0), -1);

       assert-not-instance?(limited(<integer>, min: 0), -1,
                            "values below lower bound are not instances");


Checks
------

Checks are deprecated; use `Assertions`_ instead.  The main difference
between checks and assertions is that the check macros require a
description as their first argument, whereas assertions do not.

These are the available checks:

  * :macro:`check`
  * :macro:`check-true`
  * :macro:`check-false`
  * :macro:`check-equal`
  * :macro:`check-instance?`
  * :macro:`check-condition`


.. macro:: check

   Perform a check within a test.

   :signature: check *name* *function* #rest *arguments*

   :parameter name: An instance of ``<string>``.
   :parameter function: The function to check.
   :parameter #rest arguments: The arguments for ``function``.

   :example:

     .. code-block:: dylan

       check("Test less than operator", \<, 2, 3)


.. macro:: check-condition

   Check that a given condition is signalled.

   :signature: check-condition *name* *expected* *expression*

   :parameter name: An instance of ``<string>``.
   :parameter expected: The expected condition class.
   :parameter expression: An expression.

   :example:

     .. code-block:: dylan

       check-condition("format-to-string crashes when missing an argument",
                       <error>, format-to-string("Hello %s"));


.. macro:: check-equal

   Check that 2 expressions are equal.

   :signature: check-equal *name* *expected* *expression*

   :parameter name: An instance of ``<string>``.
   :parameter expected: The expected value of ``expression``.
   :parameter expression: An expression.

   :example:

     .. code-block:: dylan

       check-equal("condition-to-string of an error produces correct string",
                   "Hello",
                   condition-to-string(make(<simple-error>, format-string: "Hello")));


.. macro:: check-false

   Check that an expression has a result of ``#f``.

   :signature: check-false *name* *expression*

   :parameter name: An instance of ``<string>``.
   :parameter expression: An expression.

   :example:

     .. code-block:: dylan

       check-false("unsupplied?(#f) == #f", unsupplied?(#f));


.. macro:: check-instance?

   Check that the result of an expression is an instance of a given type.

   :signature: check-instance? *name* *type* *expression*

   :parameter name: An instance of ``<string>``.
   :parameter type: The expected type.
   :parameter expression: An expression.

   :example:

     .. code-block:: dylan

       check-instance?("subclass returns type",
                       <type>, subclass(<string>));


.. macro:: check-true

   Check that the result of an expression is not ``#f``.

   :signature: check-true *name* *expression*

   :parameter name: An instance of ``<string>``.
   :parameter expression: An expression.

   :description:

     Note that if you want to explicitly check if an expression
     evaluates to ``#t``, you should use :func:`check-equal`.

   :example:

     .. code-block:: dylan

       check-true("unsupplied?($unsupplied)", unsupplied?($unsupplied));


Test Execution
--------------

.. function:: run-test-application

   Run a test suite or test as part of a stand-alone test executable.

   :signature: run-test-application #rest *suite-or-test* => ()
   :parameter suite-or-test: (optional) An instance of
      :class:`<suite>` or :class:`<runnable>`. If not supplied
      then all tests and benchmarks are run.

   This is the main entry point to run a set of tests in Testworks.
   It parses the command-line and based on the specified options
   selects the set of suites or tests to run, runs them, and generates
   a final report of the results.

   Internally, :func:`run-test-application` creates a
   :class:`<test-runner>` based on the command-line options and then
   calls :func:`run-tests` with the runner and *suite-or-test*.

.. function:: test-option

   Return an option value passed on the test-application command line.

   :signature: test-option *name* #key *default* => *value*
   :parameter name: An instance of type :drm:`<string>`.
   :parameter #key default: An instance of type :drm:`<string>`.
   :value value: An instance of type :drm:`<string>`.

   :description:

   Returns an option value passed to the test on the test application
   command line, in the form ``*name*=*value*``. If no option value
   was given, the *default* value is returned if one was supplied,
   otherwise an error is signalled.

   This feature allows information about external resources, such as
   path names of reference data files, or the hostname of a test
   database server, to be supplied on the command line of the test
   application and retrieved by the test.

.. TODO(cgay): document the remaining exported names.
