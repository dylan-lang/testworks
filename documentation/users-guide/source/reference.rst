Reference
*********

.. current-library:: testworks
.. current-module:: testworks

The Testworks Module
====================

Core Classes and Functions
--------------------------

.. class:: <suite>


.. function:: perform-suite

   Runs a test suite.

   :signature: perform-suite *suite* #key debug?

   :parameter suite: An instance of :class:`<suite>`.

   See also:

   - :func:`perform-test`


.. class:: <test>


.. function:: perform-test

   Runs a test.

   See also:

   - :func:`perform-suite`


.. constant:: $all-tags

   :type: <sequence>

   :value: ``#[#"all"]``


Check Functions
---------------

.. function:: check

   Perform a check within a test.

   :signature: check *name* *function* #rest *arguments*

   :parameter name: An instance of ``<string>``.
   :parameter function: The function to check.
   :parameter #rest arguments: The arguments for ``function``.

   :example:

     .. code-block:: dylan

       check("Test less than operator", \<, 2, 3)


.. function:: check-condition

   Check that a given condition is signalled.

   :signature: check-condition *name* *expected* *expression*

   :parameter name: An instance of ``<string>``.
   :parameter expected: The expected condition class.
   :parameter expression: An expression.

   :example:

     .. code-block:: dylan

       check-condition("format-to-string crashes when missing an argument",
                       <error>, format-to-string("Hello %s"));


.. function:: check-equal

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


.. function:: check-false

   Check that an expression has a result of ``#f``.

   :signature: check-false *name* *expression*

   :parameter name: An instance of ``<string>``.
   :parameter expression: An expression.

   :example:

     .. code-block:: dylan

       check-false("unsupplied?(#f) == #f", unsupplied?(#f));


.. function:: check-instance?

   Check that the result of an expression is an instance of a given class.

   :signature: check-instance? *name* *type* *expression*

   :parameter name: An instance of ``<string>``.
   :parameter type: The expected class.
   :parameter expression: An expression.

   :example:

     .. code-block:: dylan

       check-instance?("subclass returns type",
                       <type>, subclass(<string>));


.. function:: check-true

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


Stand-alone Executable Functions
--------------------------------

.. function:: run-test-application

   Runs a test suite or test as part of a stand-alone test executable.

   :signature: run-test-application *parent* #key *command-name* *arguments* *report-format-function*

   :parameter parent: An instance of :class:`<suite>` or :class:`<test>`.
   :parameter #key command-name: Defaults to ``application-name()``.
   :parameter #key arguments: Defaults to ``application-arguments()``.
   :parameter #key report-format-function: Defaults to ``*format-function*``.


Report Functions
----------------

.. function:: summary-report-function

   Prints out only a summary of how many checks, tests and suites
   were executed, passed, failed or crashed.

   :signature: summary-report-function *result*

   :parameter result: An instance of :class:`<result>`.

   See also:

   - :func:`failures-report-function`
   - :func:`full-report-function`
   - :func:`null-report-function`


.. function:: failures-report-function

   Prints out only the list of failures and a summary.

   :signature: failures-report-function *result*

   :parameter result: An instance of :class:`<result>`.

   See also:

   - :func:`summary-report-function`
   - :func:`full-report-function`
   - :func:`null-report-function`


.. function:: full-report-function

   Prints the result of every single check - whether it passed, failed
   or crashed and then a summary at the end.

   :signature: full-report-function *result*

   :parameter result: An instance of :class:`<result>`.

   See also:

   - :func:`summary-report-function`
   - :func:`failures-report-function`
   - :func:`null-report-function`


.. function:: null-report-function

   Prints nothing at all.

   :signature: null-report-function *result*

   :parameter result: An instance of :class:`<result>`.

   See also:

   - :func:`summary-report-function`
   - :func:`failures-report-function`
   - :func:`full-report-function`


Progress Functions
------------------

.. function:: null-progress-function

   Prints nothing.

   See also:

   - :func:`full-progress-function`


.. function:: full-progress-function

   Prints a line for each check executed.

   See also:

   - :func:`null-progress-function`

