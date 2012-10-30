Module:       testworks-report
Synopsis:     A tool to generate reports from test run logs
Author:       Shri Amit, Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// read-log-file

define constant $testworks-message
  = "Make sure the test report was generated using the \"-report log\"\n"
    "or \"-report xml\" option to testworks.";

define method parse-status
    (status-string :: <string>, reason)
  select (status-string by \=)
    "passed"          => #"passed";
    "failed"          => #"failed";
    "not executed"    => #"not-executed";
    "crashed"         => recreate-error(reason);
    "not implemented" => #"not-implemented";
    otherwise =>
      error("Unexpected status '%s' in report", status-string);
  end
end method parse-status;

define method make-result
    (type, name, status, reason, subresults, ignored-tests, ignored-suites,
     seconds, microseconds, allocation)
  select (as(<symbol>, type))
    #"check" =>
      make(<check-result>, 
           name: name, status: status, operation: reason, value: #f);
    #"test-unit" =>
      unless (member?(as-lowercase(name), ignored-tests, test: \=))
        make(<test-unit-result>,
             name: name, status: status, operation: reason, value: #f);
      end;
    #"benchmark" =>
      make(<benchmark-result>,
           name: name, status: status, operation: reason, value: #f,
           seconds: seconds, microseconds: microseconds,
           bytes: allocation);
    #"test" =>
      unless (member?(as-lowercase(name), ignored-tests, test: \=))
        make(<test-result>, 
             name: name, status: status, subresults: subresults)
      end;
    #"suite" =>
      if (~member?(as-lowercase(name), ignored-suites, test: \=))
        debug-message("Read %s", name);
        make(<suite-result>,
             name: name, status: status, subresults: subresults)
      else
        debug-message("Ignored %s", name)
      end;
    otherwise =>
      error("Unexpected component type '%s'", type);
  end
end method make-result;

define method read-log-file
    (test-stream :: <file-stream>, #key ignored-tests = #[], ignored-suites = #[])
 => (result :: false-or(<result>))
  block (return)
    let last-line = #f;
    // Read next non-blank line.  Error if EOF reached, since that means
    // the log file wasn't written correctly anyway.
    local method read-next-line (#key error?) => (line :: <string>)
	    let next-line = last-line;
	    if (next-line)
	      last-line := #f;
	      next-line
	    else
	      let line = read-line(test-stream);
	      while (line = "")
		line := read-line(test-stream);
	      end while;
	      line
	    end if
	  end method read-next-line;
    local method unread-line (line :: <string>) => ()
	    last-line := line
	  end method unread-line;
    local method line-starts-with (line :: <string>, s :: <string>) => (b :: <boolean>)
            block (return)
              let len = size(line);
              for (i from 0 below size(s))
                if (i >= len | line[i] ~= s[i])
                  return(#f);
                end if;
              end for;
              #t
            end block
          end method line-starts-with;
    local method maybe-read-keyword-line
	      (keyword :: <string>) => (value :: false-or(<string>))
	    let line = read-next-line();
            if (line-starts-with(line, keyword))
              as(<string>, copy-sequence(line, start: keyword.size))
            else
              unread-line(line);
              #f
            end
          end method maybe-read-keyword-line;
    local method read-keyword-line (keyword :: <string>) => (value :: <string>)
	    maybe-read-keyword-line(keyword)
              | application-error(#"token-not-found",
                                  "Error parsing report: The keyword \"%s\" was not found.\n%s\n",
                                  keyword, $testworks-message);
	  end method read-keyword-line;
    local method read-end-token () => ()
            unless (line-starts-with(read-next-line(), "end"))
              application-error(#"end-token-not-found",
                                "Error parsing report: 'end' token not found.\n%s\n",
                                $testworks-message);
            end;
          end method read-end-token;
    local method read-log-file-section () => (result :: false-or(<result>))
	    let type          = read-keyword-line("Object: ");
	    let name          = read-keyword-line("Name: ");
	    when (type = "Suite")
	      debug-message("Reading %s...", name)
	    end;
	    let status-string = read-keyword-line("Status: ");
	    let reason        = maybe-read-keyword-line("Reason: ");
            let seconds       = #f;
            let microseconds  = #f;
            let allocation    = #f;
	    let subresults
	      = if (type = "Check")
                  read-end-token();
                elseif (type = "Benchmark")
                  // If there is no "Reason:" line for a benchmark then there
                  // are "Seconds:" and "Allocation:".
                  if (~reason)
                    let time = read-keyword-line("Seconds: ");
                    let alloc = read-keyword-line("Allocation: ");
                    let (secs, index) = string-to-integer(time);
                    seconds := secs;
                    microseconds := string-to-integer(time, start: index + 1);
                    allocation := string-to-integer(alloc);
                  end if;
                  read-end-token();
		else  // type is "Test" or "Suite" or "Test unit"
		  let subresults = make(<stretchy-vector>);
		  let line = read-next-line();
		  until (line-starts-with(line, "end"))
		    unread-line(line);
		    let subresult = read-log-file-section();
		    subresult & add!(subresults, subresult);
		    line := read-next-line();
		  end;
		  subresults
		end;
            let status = parse-status(status-string, reason);
            make-result(type, name, status, reason, subresults,
                        ignored-tests, ignored-suites,
                        seconds, microseconds, allocation)
	  end;
    block ()
      read-log-file-section();
    exception (e :: <end-of-stream-error>)
      application-error(#"end-of-file",
                        "Error parsing report: End of file reached.\n%s\n",
                        $testworks-message);
    end block
  end block
end method read-log-file;

define method read-log-file
    (path :: <string>, #key ignored-tests = #[], ignored-suites = #[])
 => (result :: <result>)
  let xml? = with-open-file(stream = path)
               read-line(stream) = $xml-version-header
             end;
  if (xml?)
    read-xml-file(path, ignored-tests: ignored-tests, ignored-suites: ignored-suites);
  else
    with-open-file (stream = path)
      block (return)
        while (#t)
          let line = read-line(stream, on-end-of-stream: #f);
          select (line by \=)
    	#f =>
    	  application-error(#"start-token-not-found",
    			    "The log file '%s' doesn't contain any log information.\n%s\n",
                                path, $testworks-message);
    	$test-log-header =>
    	  return(#"plain");
    	otherwise =>
    	  #f;
          end
        end
      end;
      read-log-file(stream, ignored-tests: ignored-tests, ignored-suites: ignored-suites)
        | application-error(#"no-matching-results",
    			"There are no matching results in log file %s\n%s\n",
    			path, $testworks-message)
    end with-open-file
  end if
end method read-log-file;

define method read-xml-file
    (pathname :: <string>,
     #key ignored-tests = #[], ignored-suites = #[])
 => (result :: false-or(<result>))
  let text = with-open-file(stream = pathname)
               read-to-end(stream)
             end;
  let xml :: false-or(xml/<document>) = xml/parse-document(text);
  if (xml)
    // The basic format of the document is
    // <?xml header><test-report><suite>...</suite>...<summary>...</summary></test-report>
    let root-suite = child-named(xml/root(xml), #"suite");
    convert-xml-node(root-suite, ignored-tests, ignored-suites)
  else
    error("XML document %s didn't parse correctly.", pathname);
  end
end method read-xml-file;

define method convert-xml-node
    (node :: xml/<element>, ignored-tests :: <sequence>, ignored-suites :: <sequence>)
 => (result :: false-or(<result>))
  let node-type = xml/name(node);
  let name = child-named(node, #"name");
  let name = name & xml/text(name);
  debug-message("converting name = %s", name);
  if (~name)
    #f  // we're in a <name>, <status>, <reason>, etc. element
  elseif (member?(as-lowercase(name), ignored-tests)
            | member?(as-lowercase(name), ignored-suites))
    debug-message("Ignored %s", name);
  else
    let reason = child-named(node, #"reason");
    reason := reason & xml/text(reason);
    let status = parse-status(xml/text(child-named(node, #"status")),
                              reason);
    local method get-subresults ()
            choose(identity,  // remove #f
                   map(rcurry(convert-xml-node, ignored-tests, ignored-suites),
                       xml/node-children(node)))
          end;
    select (node-type)
      #"suite" =>
        make(<suite-result>,
             name: name,
             status: status,
             subresults: get-subresults());
      #"test" =>
        make(<test-result>,
             name: name,
             status: status,
             subresults: get-subresults());
      #"test-unit" =>
        make(<test-unit-result>,
             name: name, status: status, operation: reason, value: #f,
             subresults: get-subresults());
      #"check" =>
        make(<check-result>,
             name: name, status: status, operation: reason, value: #f);
      #"benchmark" =>
        let seconds = child-named(node, #"seconds");
        let seconds = seconds & string-to-integer(xml/text(seconds));
        let microseconds = child-named(node, #"microseconds");
        let microseconds = microseconds & string-to-integer(xml/text(microseconds));
        let allocation = child-named(node, #"allocation");
        let allocation = allocation & string-to-integer(xml/text(allocation));
        make(<benchmark-result>,
             name: name,
             status: status,
             operation: reason,
             value: #f,
             seconds: seconds,
             microseconds: microseconds,
             allocation: allocation);
      otherwise =>
        error("Unexpected node type: %s", node-type);
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


define class <recreated-error> (<error>)
end class <recreated-error>;

define method recreate-error
    (string :: <string>) => (error :: <recreated-error>)
  make(<recreated-error>,
       format-string: "%s",
       format-arguments: vector(string))
end method recreate-error;
