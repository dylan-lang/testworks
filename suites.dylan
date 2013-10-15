Module:       testworks
Summary:      Testworks harness
Author:       James Krisch, Shri Amit, Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// Suites

define class <suite> (<component>)
  constant slot %components :: false-or(type-union(<sequence>, <function>)) = #f,
    init-keyword: components:;
  constant slot suite-setup-function :: <function> = method () end,
    init-keyword: setup-function:;
  constant slot suite-cleanup-function :: <function> = method () end,
    init-keyword: cleanup-function:;
end class <suite>;

define method component-type-name
    (suite :: <suite>) => (type-name :: <string>)
  "suite"
end;

define variable *all-suites*
  = make(<suite>,
         name: "All Defined Suites",
         components: make(<stretchy-vector>));

define method root-suite () => (suite :: <suite>)
  *all-suites*
end method root-suite;

define method ensure-suite-components
    (components :: <sequence>, suite :: <suite>)
 => (components :: <sequence>)
  map(method (component)
        select (component by instance?)
          <component> =>
            component;
          <function>  =>
            find-test-object(component)
              | error("Non-test function %= in suite %s",
                      component, component-name(suite));
          otherwise   =>
            error("Invalid object %= in suite %s", component, component-name(suite))
        end
      end,
      components)
end method ensure-suite-components;

define method suite-components
    (suite :: <suite>) => (components :: <sequence>)
  let components = suite.%components;
  select (components by instance?)
    <sequence> => components;
    <function> => ensure-suite-components(components(), suite)
  end
end method suite-components;

define method make-suite
    (name :: <string>, components, #rest keyword-args)
 => (suite :: <suite>)
  let suite
    = apply(make, <suite>,
            name: name,
            components: components,
            keyword-args);
  let all-suites = root-suite().suite-components;
  let position
     = find-key(all-suites,
                method (suite)
                  suite.component-name = name
                end);
  if (position)
    all-suites[position] := suite
  else
    add!(all-suites, suite)
  end;
  suite
end method make-suite;

define macro suite-definer
  { define suite ?suite-name:name (?keyword-args:*) ?components end } =>
    {define variable ?suite-name
       = make-suite(?"suite-name",
                    method ()
                      list(?components)
                    end,
                    ?keyword-args) }

  components:
    { } => { }
    { test ?:name; ... }
      => { ?name, ... }
    { suite ?:name; ... }
      => { ?name, ... }
end macro suite-definer;

define method find-suite
    (name :: <string>, #key search-suite = root-suite())
 => (suite :: false-or(<suite>))
  let lowercase-name = as-lowercase(name);
  local method do-find-suite (suite :: <suite>)
          if (as-lowercase(component-name(suite)) = lowercase-name)
            suite
          else
            block (return)
              for (object in suite-components(suite))
                if (instance?(object, <suite>))
                  let subsuite = do-find-suite(object);
                  if (subsuite) return(subsuite) end;
                end
              end
            end
          end
        end;
  do-find-suite(search-suite);
end method find-suite;

define method find-test
    (name :: <string>, #key search-suite = root-suite())
 => (test :: false-or(<test>))
  let lowercase-name = as-lowercase(name);
  local method do-find-test (suite :: <suite>)
          block (return)
            for (object in suite-components(suite))
              select (object by instance?)
                <test> =>
                  if (as-lowercase(component-name(object)) = lowercase-name)
                    return(object)
                  end if;
                <suite> =>
                  let test = do-find-test(object);
                  if (test) return(test) end;
              end
            end
          end
        end;
  do-find-test(search-suite);
end method find-test;

define method perform-suite
    (suite :: <suite>,
     #key tags                     = $all-tags,
          announce-function        = #f,
          announce-checks?         = *announce-checks?*,
          report-format-function   = *format-function*,
          progress-format-function = *format-function*,
          report-function          = *default-report-function*,
          progress-function        = *default-progress-function*,
          debug?                   = *debug?*)
 => (result :: <component-result>)
  perform-component
    (suite,
     make(<perform-options>,
          tags:                     tags,
          announce-function:        announce-function,
          announce-checks?:         announce-checks?,
          progress-format-function: progress-format-function,
          progress-function:        progress-function | null-progress-function,
          debug?:                   debug?),
     report-function:        report-function | null-report-function,
     report-format-function: report-format-function)
end method perform-suite;

define method list-component
    (suite :: <suite>, options :: <perform-options>)
 => (list :: <sequence>)
  let sublist :: <stretchy-vector> = make(<stretchy-vector>);
  if (execute-component?(suite, options))
    add!(sublist, suite);
    for (component in suite.suite-components)
      sublist := concatenate!(sublist, list-component(component, options));
    end for;
  end if;
  sublist
end method list-component;
    
define method execute-component
    (suite :: <suite>, options :: <perform-options>)
 => (subresults :: <sequence>, status :: <result-status>, reason :: false-or(<string>),
     seconds :: <integer>, microseconds :: <integer>, bytes :: <integer>)
  let subresults :: <stretchy-vector> = make(<stretchy-vector>);
  let seconds :: <integer> = 0;
  let microseconds :: <integer> = 0;
  let bytes :: <integer> = 0;
  let (status, reason)
    = block ()
        suite.suite-setup-function();
        for (component in suite.suite-components)
          let subresult = maybe-execute-component(component, options);
          add!(subresults, subresult);
          if (instance?(subresult, <component-result>)
              & subresult.result-seconds
              & subresult.result-microseconds)
            let (sec, usec) = add-times(seconds, microseconds,
                                        subresult.result-seconds,
                                        subresult.result-microseconds);
            seconds := sec;
            microseconds := usec;
            bytes := bytes + subresult.result-bytes;
          else
            test-output("subresult has no profiling info: %s\n",
                        subresult.result-name);
          end;
        end for;
        case
          empty?(subresults) =>
            $not-implemented;
          every?(method (subresult)
                   let status = subresult.result-status;
                   status = $passed | status = $skipped
                 end,
                 subresults) =>
            $passed;
          otherwise =>
            $failed
        end case
      cleanup
        suite.suite-cleanup-function();
      end block;
  values(subresults, status, reason, seconds, microseconds, bytes)
end method execute-component;

define function add-times
    (sec1, usec1, sec2, usec2) => (sec, usec)
  let sec = sec1 + sec2;
  let usec = usec1 + usec2;
  if (usec >= 1000000)
    usec := usec - 1000000;
    sec1 := sec1 + 1;
  end if;
  values(sec, usec)
end function add-times;
