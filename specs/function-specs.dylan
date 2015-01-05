Module:       testworks-specs
Synopsis:     A library for building specification test suites
Author:       Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// Function specs

define class <function-spec> (<definition-spec>)
  constant slot function-spec-function :: <function>,
    required-init-keyword: function:;
  constant slot function-spec-modifiers :: <sequence> = #[],
    init-keyword: modifiers:;
  constant slot %function-spec-parameters :: <sequence> = #[],
    init-keyword: parameters:;
  constant slot %function-spec-results :: <sequence> = #[],
    init-keyword: results:;
end class <function-spec>;


/// A useful macro to define the function specs

define macro function-test-definer
  { define ?protocol-name:name function-test ?function-name:name ()
      ?body:body
    end }
    => { define ?protocol-name definition-test ?function-name () ?body end }
end macro function-test-definer;


/// Function spec modeling

define method function-spec-parameters
    (function-spec :: <function-spec>)
 => (required :: <sequence>, rest? :: <boolean>,
     keys :: <sequence>, all-keys? :: <boolean>);
  let spec-parameters = %function-spec-parameters(function-spec);
  local
    method identify-required
        (index :: <integer>)
     => (required :: <sequence>, rest? :: <boolean>,
         keys :: <sequence>, all-keys? :: <boolean>);
      if (index < spec-parameters.size)
        let item = spec-parameters[index];
        if (instance?(item, <type>))
          identify-required(index + 1)
        else
          let required = copy-sequence(spec-parameters, end: index);
          if (item == #"rest")
            identify-key(required, #t, index + 1)
          else
            identify-key(required, #f, index)
          end if
        end if
      else
        values(spec-parameters, #f, #[], #f)
      end if
    end method,
    method identify-key
        (required :: <sequence>, rest? :: <boolean>, index :: <integer>)
     => (required :: <sequence>, rest? :: <boolean>,
         keys :: <sequence>, all-keys? :: <boolean>);
      if (index < spec-parameters.size)
        let item = spec-parameters[index];
        if (item == #"key")
          identify-keys(required, rest?, index + 1, index + 1)
        else
          error("Unrecognized parameter %= in %s", item,
                spec-name(function-spec));
        end if
      else
        values(required, rest?, #[], #f)
      end if
    end method,
    method identify-keys
        (required :: <sequence>, rest? :: <boolean>,
         first-key-index :: <integer>, index :: <integer>)
     => (required :: <sequence>, rest? :: <boolean>,
         keys :: <sequence>, all-keys? :: <boolean>);
      if (index < spec-parameters.size)
        let item = spec-parameters[index];
        if (item == #"all-keys")
          if (index + 1 ~= spec-parameters.size)
            error("#\"all-keys\" must appear as the last parameter item");
          end if;
          let keys
            = copy-sequence(spec-parameters,
                            start: first-key-index, end: index);
          values(required, rest?, keys, #t)
        elseif (instance?(item, <symbol>))
          identify-keys(required, rest?, first-key-index, index + 1)
        else
          error("Unrecognized parameter %= in %s", item,
                spec-name(function-spec));
        end if
      else
        let keys
          = copy-sequence(spec-parameters, start: first-key-index, end: index);
        values(required, rest?, keys, #f)
      end if
    end method;
  identify-required(0)
end method function-spec-parameters;

define method function-spec-results
    (function-spec :: <function-spec>)
 => (required :: <sequence>, rest? :: <boolean>);
  let spec-results = %function-spec-results(function-spec);
  local
    method identify-required
        (index :: <integer>)
     => (required :: <sequence>, rest? :: <boolean>);
      if (index < spec-results.size)
        let item = spec-results[index];
        if (instance?(item, <type>))
          identify-required(index + 1)
        elseif (item == #"rest")
          if (index + 1 ~= spec-results.size)
            error("#\"rest\" must appear as the last parameter item");
          end if;
          values(copy-sequence(spec-results, end: index), #t)
        else
          error("Unrecognized result %= in %s", item,
                spec-name(function-spec));
        end if
      else
        values(spec-results, #f)
      end if
    end method;
  identify-required(0)
end method function-spec-results;

define method function-spec-generic?
    (function-spec :: <function-spec>)
 => (generic? :: <boolean>)
  member?(#"generic", function-spec-modifiers(function-spec))
end method function-spec-generic?;

define function function-spec-type
    (function-spec :: <function-spec>)
 => (type :: <type>, type-name :: <string>)
  if (function-spec-generic?(function-spec))
    values(<generic-function>, "generic-function")
  else
    values(<function>, "function")
  end
end function function-spec-type;

define function function-spec-check-name
    (function-name :: <string>, type-name :: <string>)
 => (check-name :: <string>)
  format-to-string("Variable %s is a %s and all of its specializer types"
                     " are bound", function-name, type-name)
end function function-spec-check-name;

define function check-function-specification-parameters
    (title :: <string>, function-spec :: <function-spec>)
 => ();
  let function = function-spec-function(function-spec);
  let (required :: <sequence>, rest? :: <boolean>,
       keys :: <sequence>, all-keys? :: <boolean>)
    = function-spec-parameters(function-spec);
  let actual-specializers
    = function-specializers(function);
  let (actual-required-number, actual-rest?, actual-keys)
    = function-arguments(function);

  check-true(format-to-string("function %s can handle the maximum number"
                                " of specified arguments", title),
             actual-rest?
               | (~rest? & required.size <= actual-required-number));
  check-true(format-to-string("function %s can handle the minimum number"
                                " of specified arguments", title),
             required.size >= actual-required-number);

  // TODO(cgay): This fails for cases where a library adds a method to
  // an existing generic function. For example,
  //     open generic-function \< (<date>, <date>) => (<boolean>);
  // The generic is defined on (<object>, <object>) so the below test fails.
  // We should be able to iterate over the gf methods and see if there's
  // one exactly matching the spec's types.  (On the other hand, having
  // that in the spec doesn't seem nearly as useful as writing a test that
  // calls <date> < <date> and gets the right result.)

  for (spec in required,
       actual in actual-specializers,
       index from 0)
    check-true(format-to-string("function %s argument %d type %s"
                                  " is a subtype of the specified type %s",
                                title, index, actual, spec),
               subtype?(actual, spec));
  end for;

  for (key in keys)
    check-true(format-to-string("function %s can handle keyword"
                                  " argument %=", title, key),
               actual-rest?
                 | actual-keys == #"all"
                 | (instance?(actual-keys, <sequence>)
                      & member?(key, actual-keys)));
  end for;
  if (all-keys?)
    check-true(format-to-string("function %s can handle all keywords", title),
               actual-rest? | actual-keys == #"all");
  end if;
end function;

define function check-function-specification-results
    (title :: <string>, function-spec :: <function-spec>)
 => ();
  let function = function-spec-function(function-spec);
  let (required :: <sequence>, rest? :: <boolean>)
    = function-spec-results(function-spec);
  let (actual-return-types, actual-rest?) = function-return-values(function);
  check-true(format-to-string("function %s can return the minimum number"
                                " of specified return values", title),
             actual-return-types.size >= required.size
               | actual-rest?);
  check-true(format-to-string("function %s can not exceed the maximum number"
                                " of specified return values", title),
             actual-return-types.size <= required.size
               | rest?);
  for (spec in required, return-type in actual-return-types, index from 0)
    check-true(format-to-string("function %s return value %d type %s"
                                  " is a subtype of the specified type %s",
                                title, index, return-type, spec),
               subtype?(return-type, spec));
  end for;
end function;

define function check-function-specification
    (function-spec :: <function-spec>)
 => ()
  let title = spec-title(function-spec);
  let function = function-spec-function(function-spec);
  let (type, type-name) = function-spec-type(function-spec);
  check-instance?(function-spec-check-name(title, type-name),
                  type, function);
  check-function-specification-parameters(title, function-spec);
  check-function-specification-results(title, function-spec);
end function check-function-specification;
