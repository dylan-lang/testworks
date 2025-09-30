Module: %testworks
Synopsis: Utilities and code that needs to be loaded early.
Copyright: Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
           All rights reserved.
License: See License.txt in this distribution for details.
Warranty: Distributed WITHOUT WARRANTY OF ANY KIND


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
  let negated? = (~empty?(spec) & spec[0] == '-');
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
    (requested-tags :: <sequence>, test :: <runnable>)
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


// Might want to put an extended version of this in the io:format module.
define function format-bytes
    (bytes :: <integer>) => (string :: <string>)
  let (divisor, units) = case
                           bytes <= 1024 =>
                             values(1, "B");
                           bytes <= ash(1, 20) =>
                             values(1024, "KiB");
                           otherwise =>
                             values(ash(1, 20), "MiB");
                           // Need more bits in our integers...
                         end;
  concatenate(integer-to-string(round/(bytes, divisor)), units)
end function format-bytes;

define function capitalize
    (string :: <string>) => (_ :: <string>)
  concatenate(as-uppercase(copy-sequence(string, end: 1)),
              copy-sequence(string, start: 1))
end function;

// For --progress and --report=full
define thread variable *indent* :: <string> = "";

define constant $indent-step :: <string> = "  ";

define function next-indent () => (indent :: <string>)
  concatenate(*indent*, $indent-step)
end function;

define function default-runner-temp-directory () => (dir :: <directory-locator>)
  let dylan = os/environment-variable("DYLAN");
  let base = if (dylan)
               as(<directory-locator>, dylan)
             else
               fs/working-directory()
             end;
  let dated-dir
    = concatenate(os/login-name() | "unknown",
                  "-",
                  date/format("%Y%m%d-%H%M%S", date/now()));
  // We could just include milliseconds (%F) in the date format below but currently
  // <date> milliseconds are always zero, at least on Unix.
  // https://github.com/dylan-lang/testworks/issues/199
  iterate loop (i = 1)
    let uniquifier = format-to-string("%s.%d", dated-dir, i);
    let dir = subdirectory-locator(base, "_test", uniquifier);
    if (block ()
          fs/file-exists?(dir)
        exception (ex :: fs/<file-system-error>)
          #f
        end)
      loop(i + 1)
    else
      dir
    end
  end
end function;

// Return a temporary directory unique to the current test or benchmark.
define function test-temp-directory () => (d :: false-or(<directory-locator>))
  if (instance?(*component*, <runnable>))
    let safe-name = map(method (c)
                          if (c == '\\' | c == '/') '_' else c end
                        end,
                        component-name(*component*));
    let test-directory
      = subdirectory-locator(runner-temp-directory(*runner*), safe-name);
    fs/ensure-directories-exist(test-directory);
    test-directory
  end
end function;

// Create a file in the current test's temp directory with the given contents.
// If the file already exists an error is signaled. `filename` is assumed to be
// a relative pathname; if it contains the path separator, subdirectories are
// created. File contents may be provided with the `contents` parameter,
// otherwise an empty file is created. Returns the full, absolute file path as
// a `<file-locator>`.
define function write-test-file
    (filename :: fs/<pathname>, #key contents :: <string> = "")
 => (full-pathname :: <file-locator>)
  let locator = merge-locators(as(<file-locator>, filename),
                               test-temp-directory());
  fs/ensure-directories-exist(locator);
  fs/with-open-file (stream = locator,
                     direction: #"output", if-exists: #"signal")
    write(stream, contents);
  end;
  locator
end function;

// For output to the main output stream for the test run.  That is, this output is never
// redirected to the _captured-stdout.txt file in a test's temp directory.
define method test-output
    (format-string :: <string>, #rest format-args) => ()
  let stream = if (*runner*)
                 runner-output-stream(*runner*)
               else
                 *standard-output*
               end;
  with-stream-locked (stream)
    apply(format, stream, format-string, format-args);
    force-output(stream);
  end;
end method;

define constant $captured-output-filename :: <string> = "_captured-stdout.txt";

define variable *output-captured?* :: <boolean> = #f;

define function write-captured-output (output :: <string>)
  block ()
    let file = file-locator(test-temp-directory(), $captured-output-filename);
    write-test-file(file, contents: output);
    *output-captured?* := #t;
  exception (err :: <error>)
    test-output("ERROR writing to test's output file: %s\n%s\n", err, output);
  end;
end function;
