Module:       testworks-specs
Synopsis:     A library for building specification test suites
Author:       Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define class <protocol-spec> (<spec>)
end class <protocol-spec>;


/// A useful macro to define protocol specs

define macro protocol-spec-definer
  { define protocol-spec ?protocol-name:name (?options:*)
      ?specs:*
    end}
    => { define protocol-spec-constant ?protocol-name (?options)
         end;
         define protocol-spec-bindings "$" ## ?protocol-name ## "-protocol-spec" (?options)
           ?specs
         end; }
end macro protocol-spec-definer;

define macro protocol-spec-constant-definer
  { define protocol-spec-constant ?protocol-name:name (?options:*) end}
    => { define constant "$" ## ?protocol-name ## "-protocol-spec"
           = make(<protocol-spec>,
                  name: ?#"protocol-name",
                  ?options) }
end macro protocol-spec-constant-definer;

define macro protocol-spec-bindings-definer
  { define protocol-spec-bindings ?protocol-constant:name (?options:*)
    end }
    => { }
  { define protocol-spec-bindings ?protocol-constant:name (?options:*)
      ?modifiers:* class ?class-name:name (?superclasses:*);
      ?more-specs:*
    end }
    => { define test "check-class-specification-" ## ?class-name ()
           let class-spec = make(<class-spec>,
                                 name: ?#"class-name",
                                 class: ?class-name,
                                 superclasses: vector(?superclasses),
                                 modifiers: vector(?modifiers));
           check-class-specification(class-spec);
         end;
         define protocol-spec-bindings ?protocol-constant (?options)
           ?more-specs
         end; }
  { define protocol-spec-bindings ?protocol-constant:name (?options:*)
      ?modifiers:* function ?function-name:name (?parameters:*) => (?results:*);
      ?more-specs:*
    end }
    => { define test "check-function-specification-" ## ?function-name ()
           let function-spec
             = make(<function-spec>,
                    name: ?#"function-name",
                    function: ?function-name,
                    parameters: vector(?parameters),
                    results:    vector(?results),
                    modifiers: vector(?modifiers));
           check-function-specification(function-spec);
         end;
         define protocol-spec-bindings ?protocol-constant (?options)
           ?more-specs
         end; }
  { define protocol-spec-bindings ?protocol-constant:name (?options:*)
      ?modifiers:* generic-function ?function-name:name (?parameters:*) => (?results:*);
      ?more-specs:*
    end }
    => { define test "check-function-specification-" ## ?function-name ()
           let function-spec
             = make(<function-spec>,
                    name: ?#"function-name",
                    function: ?function-name,
                    parameters: vector(?parameters),
                    results:    vector(?results),
                    modifiers: vector(#"generic", ?modifiers));
           check-function-specification(function-spec);
         end;
         define protocol-spec-bindings ?protocol-constant (?options)
           ?more-specs
         end; }
  { define protocol-spec-bindings ?protocol-constant:name (?options:*)
      ?modifiers:* variable ?variable-name:name :: ?type:expression;
      ?more-specs:*
    end }
    => { define test "check-variable-specification-" ## ?variable-name ()
           let variable-spec
             = make(<variable-spec>,
                    name: ?#"variable-name",
                    type: ?type,
                    getter: method () => (value :: ?type)
                              ?variable-name
                            end,
                    setter: method (value :: ?type) => (value :: ?type)
                              ?variable-name := value
                            end);
           check-variable-specification(variable-spec);
         end;
         define protocol-spec-bindings ?protocol-constant (?options)
           ?more-specs
         end; }
  { define protocol-spec-bindings ?protocol-constant:name (?options:*)
      ?modifiers:* constant ?constant-name:name :: ?type:expression;
      ?more-specs:*
    end }
    => { define test "check-constant-specification-" ## ?constant-name ()
           let constant-spec
             = make(<constant-spec>,
                    name: ?#"constant-name",
                    type: ?type,
                    getter: method () ?constant-name end);
           check-constant-specification(constant-spec);
         end;
         define protocol-spec-bindings ?protocol-constant (?options)
           ?more-specs
         end; }
  { define protocol-spec-bindings ?protocol-constant:name (?options:*)
      ?modifiers:* macro-test ?macro-name:name;
      ?more-specs:*
    end }
    => { define protocol-spec-bindings ?protocol-constant (?options)
           ?more-specs
         end; }
 modifiers:
  { }
    => { }
  { ?modifier:name ... }
    => { ?#"modifier", ... }
end macro protocol-spec-bindings-definer;


/// A useful macro to define a definition's test function

define macro definition-test-definer
  { define ?protocol-name:name definition-test ?definition-name:name ()
      ?body:body
    end }
    => { define test "test-" ## ?definition-name ## "-specification" ()
           ?body
         end }
end macro definition-test-definer;
