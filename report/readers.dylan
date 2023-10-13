Module:       testworks-report-lib
Synopsis:     A tool to generate reports from test run logs
Author:       Shri Amit, Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

// It looks like this and testworks:status-name are meant to be
// inverses.  (This would be a good use for an <enum> class.)
define method parse-status
    (status-string :: <string>, reason)
  select (status-string by \=)
    "passed" => $passed;
    "failed" => $failed;
    "crashed" => $crashed;
    "skipped" => $skipped;
    "failed as expected" => $expected-failure;
    "unexpectedly succeeded" => $unexpected-success;
    "not implemented" => $not-implemented;
    otherwise =>
      application-error("Unexpected status '%s' in report", status-string);
  end
end method parse-status;

define function read-report
    (path :: <string>, #key ignored-tests = #[], ignored-suites = #[])
 => (result :: <result>)
  let extension = locator-extension(as(<file-locator>, path));
  let reader
    = select (extension by \=)
        // TODO(cgay): read surefire xml format
        "xml" => read-xml-report;
        "json" => read-json-report;
        otherwise
          => application-error("can't determine report type; unrecognized filename "
                                 "extension: %=", extension);
      end;
  with-open-file (stream = path)
    reader(stream, path, ignored-tests: ignored-tests, ignored-suites: ignored-suites)
  end
end function;

define function read-json-report
    (stream :: <stream>, path :: <string>, #key ignored-tests = #[], ignored-suites = #[])
 => (result :: <result>)
  // The json report is one top-level json "object" (i.e., <string-table>)
  // representing a suite.
  local method table-to-result (t) // See result-to-table:%testworks:testworks
          let type = t["type"];
          let name = t["name"];
          let reason = t["reason"];
          let status = parse-status(t["status"], reason);
          if (string-equal-ic?(type, "check"))
            make(<check-result>, name: name, status: status, reason: reason)
          else
            let result-class
              = select (type by string-equal-ic?)
                  "suite" => <suite-result>;
                  "test" => <test-result>;
                  "benchmark" => <benchmark-result>;
                  "iteration" => <benchmark-iteration-result>;
                  otherwise =>
                    application-error("unexpected test result type in report: %= "
                                        "(pathname = %s)", type, path);
                end;
            make(result-class,
                 name: name,
                 status: status,
                 reason: reason,
                 seconds: t["seconds"],
                 microseconds: t["microseconds"],
                 bytes: t["bytes"],
                 // Note that for <benchmark-iteration-result> we depend on the
                 // fact that extra keyword args passed to `make` are ignored.
                 subresults: map(table-to-result, element(t, "children", default: #[])))
          end if
        end method;
  table-to-result(parse-json(stream))
end function;

define function read-xml-report
    (stream :: <stream>, path :: <string>, #key ignored-tests = #[], ignored-suites = #[])
 => (result :: <result>)
  let text = read-to-end(stream);
  let xml :: false-or(xml/<document>) = xml/parse-document(text);
  if (xml)
    let root-suite = child-named(xml/root(xml), #"suite");
    convert-xml-node(root-suite, ignored-tests, ignored-suites)
  else
    application-error("XML document %s didn't parse correctly.", path);
  end
end function;

define method convert-xml-node
    (node :: xml/<element>, ignored-tests :: <sequence>, ignored-suites :: <sequence>)
 => (result :: false-or(<result>))
  let node-type = xml/name(node);
  let name = child-named(node, #"name");
  let name = name & xml/text(name);
  if (~name)
    #f  // we're in a <name>, <status>, <reason>, etc. element
  elseif (member?(as-lowercase(name), ignored-tests)
            | member?(as-lowercase(name), ignored-suites))
    #f
  else
    let reason = child-named(node, #"reason");
    reason := reason & xml/text(reason);
    let status = parse-status(xml/text(child-named(node, #"status")), reason);
    local
      method get-subresults ()
        choose(identity,  // remove #f
               map(rcurry(convert-xml-node, ignored-tests, ignored-suites),
                   xml/node-children(node)))
      end method,
      method make-component-result (class :: <class>)
        let seconds = child-named(node, #"seconds");
        let seconds = seconds & string-to-integer(xml/text(seconds));
        let microseconds = child-named(node, #"microseconds");
        let microseconds = microseconds & string-to-integer(xml/text(microseconds));
        let bytes = child-named(node, #"allocation");
        let bytes = bytes & string-to-integer(xml/text(bytes));
        make(class,
             name: name,
             status: status,
             reason: reason,
             seconds: seconds,
             microseconds: microseconds,
             bytes: bytes,
             // Note that for <benchmark-iteration-result> we depend on the
             // fact that extra keyword args passed to `make` are ignored.
             subresults: get-subresults())
      end method;
    select (node-type)
      #"suite"     => make-component-result(<suite-result>);
      #"test"      => make-component-result(<test-result>);
      #"benchmark" => make-component-result(<benchmark-result>);
      #"iteration" => make-component-result(<benchmark-iteration-result>);
      #"check"
        => make(<check-result>, name: name, status: status, reason: reason);
      otherwise =>
        application-error("Unexpected XML node type: %s", node-type);
    end
  end if
end method convert-xml-node;

define method child-named
    (node :: xml/<node-mixin>, name :: <symbol>)
  find(xml/node-children(node),
       method (x)
         xml/name(x) = name
       end)
end method child-named;

// Am I missing something in the dylan or common-dylan library?
// Couldn't find this.  I guess I could use "choose", but that
// shouldn't be necessary.  --cgay Feb 2009
define method find
    (collection :: <collection>, predicate :: <function>,
     #key skip :: <integer> = 0, failure)
  block (return)
    for (item in collection)
      if (predicate(item) & ((skip := skip - 1) < 0))
        return(item)
      end;
    end;
  end
end method find;
