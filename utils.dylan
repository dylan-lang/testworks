Module: %testworks
Synopsis: Utilities and code that needs to be loaded early.
Copyright: Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
           All rights reserved.
License: See License.txt in this distribution for details.
Warranty: Distributed WITHOUT WARRANTY OF ANY KIND


// The active test run object.
define thread variable *runner* :: false-or(<test-runner>) = #f;


define function add-times
    (sec1 :: <integer>, usec1 :: <integer>, sec2 :: <integer>, usec2 :: <integer>)
 => (sec :: <integer>, usec :: <integer>)
  let sec = sec1 + sec2;
  let usec = usec1 + usec2;
  if (usec >= 1000000)
    usec := usec - 1000000;
    sec1 := sec1 + 1;
  end if;
  values(sec, usec)
end function add-times;


define method plural
    (n :: <integer>) => (ending :: <string>)
  if (n == 1) "" else "s" end if
end;


//// Tags

define class <tag> (<object>)
  constant slot tag-name :: <string>, init-keyword: name:;
  constant slot tag-negated? :: <boolean>, init-keyword: negated?:;
end;

define method make-tag
    (tag :: <tag>) => (tag :: <tag>)
  tag
end;

define method make-tag
    (spec :: <string>) => (tag :: <tag>)
  let negated? = starts-with?(spec, "-");
  let name = copy-sequence(spec, start: negated? & 1 | 0);
  if (empty?(name))
    error("Invalid tag: %=", spec);
  end;
  make(<tag>, name: name, negated?: negated?)
end method make-tag;

define method print-object
    (tag :: <tag>, stream :: <stream>) => ()
  format(stream, "#<tag %s%s>", tag.tag-negated? & "-" | "", tag.tag-name);
end;

define function parse-tags
    (specs :: <sequence> /* of <string> */)
 => (tags :: <sequence> /* of <tag> */)
  map(make-tag, specs)
end;

// If tags match, run the test.
define generic tags-match?
    (requested-tags :: <sequence>, component :: <component>)
 => (bool :: <boolean>);

define method tags-match?
    (requested-tags :: <sequence>, component :: <component>)
 => (bool :: <boolean>)
  #t
end;

define method tags-match?
    (requested-tags :: <sequence>, test :: <test>)
 => (bool :: <boolean>)
  local method match (negated?)
          block (return)
            for (rtag in requested-tags)
              if (rtag.tag-negated? = negated?)
                for (ctag in test.test-tags)
                  if (ctag.tag-name = rtag.tag-name)
                    return(#t)
                  end;
                end;
              end;
            end;
          end block
        end method match;
  let negative-rtags? = any?(tag-negated?, requested-tags);
  let positive-rtags? = any?(complement(tag-negated?), requested-tags);
  block (return)
    // Order matters here.  Negative tags take precedence.
    negative-rtags? & match(#t) & return(#f);
    positive-rtags? & return(match(#f));
    #t
  end block
end method tags-match?;
