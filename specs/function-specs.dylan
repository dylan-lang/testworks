Module:       testworks-specs
Synopsis:     A library for building specification test suites
Author:	      Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// Function specs

define class <function-spec> (<definition-spec>)
  constant slot function-spec-function :: <function>,
    required-init-keyword: function:;
  constant slot function-spec-modifiers :: <sequence> = #[],
    init-keyword: modifiers:;
  constant slot function-spec-parameters :: <sequence> = #[],
    init-keyword: parameters:;
  constant slot function-spec-results :: <sequence> = #[],
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

define method register-function
    (spec :: <protocol-spec>, name :: <symbol>, binding-function :: <function>)
 => ()
  register-binding(protocol-function-bindings(spec), name, binding-function)
end method register-function;

define method protocol-functions
    (spec :: <protocol-spec>) => (classes :: <table>)
  protocol-bindings(protocol-function-bindings(spec))
end method protocol-functions;

define method protocol-unbound-functions
    (spec :: <protocol-spec>) => (functions :: <sequence>)
  protocol-unbound-bindings(protocol-function-bindings(spec))
end method protocol-unbound-functions;

define method protocol-definition-spec
    (protocol-spec :: <protocol-spec>, function :: <function>)
 => (function-spec :: false-or(<function-spec>))
  element(protocol-functions(protocol-spec), function, default: #f)
end method protocol-definition-spec;

define method protocol-function-modifiers
    (spec :: <protocol-spec>, function :: <function>)
 => (modifiers :: <sequence>)
  let function-spec = protocol-definition-spec(spec, function);
  function-spec-modifiers(function-spec)
end method protocol-function-modifiers;

define method protocol-function-parameters
    (spec :: <protocol-spec>, function :: <function>)
 => (required :: <sequence>, rest? :: <boolean>,
     keys :: <sequence>, all-keys? :: <boolean>);
  let function-spec = protocol-definition-spec(spec, function);
  let spec-parameters = function-spec-parameters(function-spec);
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
          if(item == #"rest")
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
end method protocol-function-parameters;

define method protocol-function-results
    (spec :: <protocol-spec>, function :: <function>)
 => (required :: <sequence>, rest? :: <boolean>);
  let function-spec = protocol-definition-spec(spec, function);
  let spec-results = function-spec-results(function-spec);
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
end method protocol-function-results;

define method protocol-function-generic?
    (spec :: <protocol-spec>, function :: <function>)
 => (generic? :: <boolean>)
  member?(#"generic", protocol-function-modifiers(spec, function))
end method protocol-function-generic?;

define function protocol-function-type
    (protocol-spec :: <protocol-spec>, function :: <function>)
 => (type :: <type>, type-name :: <string>)
  if (protocol-function-generic?(protocol-spec, function))
    values(<generic-function>, "generic-function")
  else
    values(<function>, "function")
  end
end function protocol-function-type;

define function protocol-function-check-name
    (function-name :: <string>, type-name :: <string>)
 => (check-name :: <string>)
  format-to-string("Variable %s is a %s and all of its specializer types"
                     " are bound", function-name, type-name)
end function protocol-function-check-name;

define function check-protocol-function-parameters
    (spec :: <protocol-spec>, title :: <string>, function :: <function>)
 => ();
  let (required :: <sequence>, rest? :: <boolean>,
       keys :: <sequence>, all-keys? :: <boolean>)
    = protocol-function-parameters(spec, function);
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

  for (spec in required, specializer in actual-specializers, index from 0)
    check-true(format-to-string("function %s argument %d type %s"
                                  " is a supertype of the specified type %s",
                                title, index, specializer, spec),
               subtype?(spec, specializer));
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

define function check-protocol-function-results
    (spec :: <protocol-spec>, title :: <string>, function :: <function>)
 => ();
  let (required :: <sequence>, rest? :: <boolean>)
    = protocol-function-results(spec, function);
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

define function check-protocol-function
    (protocol-spec :: <protocol-spec>, function-spec :: <function-spec>)
 => ()
  let title = spec-title(function-spec);
  let function = function-spec-function(function-spec);
  with-test-unit (format-to-string("%s specification", title))
    let (type, type-name) = protocol-function-type(protocol-spec, function);
    check-instance?(protocol-function-check-name(title, type-name),
                    type, function);
    check-protocol-function-parameters(protocol-spec, title, function);
    check-protocol-function-results(protocol-spec, title, function);
  end;
  with-test-unit (format-to-string("function-test %s", title))
    test-protocol-definition
      (protocol-spec, spec-name(protocol-spec), spec-name(function-spec))
  end
end function check-protocol-function;

define function check-protocol-functions
    (protocol-spec :: <protocol-spec>) => ()
  do-protocol-definitions
    (curry(check-protocol-function, protocol-spec),
     protocol-spec, <function-spec>);
  do(method (function-name)
       // This function is unbound; its type can't be determined so
       // just say it's a "function".
       let name = protocol-function-check-name(function-name, "function");
       check-true(name, #f)
     end,
     protocol-unbound-functions(protocol-spec))
end function check-protocol-functions;
