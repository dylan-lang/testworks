Module:       testworks
Synopsis:     Testworks benchmarks
Author:       Carl Gay
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// Benchmarks

/// Note that <benchmark-result> is defined in tests.dylan

// TODO(cgay): rather than having a special benchmark mechanism, just
// record/report timing info for all tests (optionally).

define macro benchmark
  { benchmark (?benchmark-name:expression, ?expr:expression)
  } => {
    %benchmark(method () ?benchmark-name end,
               method () ?expr end)
  }
end macro benchmark;

define function %benchmark
    (get-name :: <function>, run-benchmark :: <function>)
 => ()
  let phase = "evaluating benchmark name";
  let name = #f;
  block (return)
    let handler <serious-condition>
        = method (condition, next-handler)
            if (*debug?*)
              next-handler()  // decline to handle it
            else
              record-benchmark(name | format-to-string("*** Invalid benchmark name ***"),
                               $crashed,
                               format-to-string("Error %s: %s", phase, condition),
                               #f, #f, #f);
              return();
            end;
          end method;
    name := get-name();
    phase := "running benchmark";
    profiling (cpu-time-seconds, cpu-time-microseconds, allocation)
      run-benchmark();
    results
      // Benchmarks pass if they don't crash.
      record-benchmark(name, $passed, #f,
                       cpu-time-seconds, cpu-time-microseconds, allocation);
    end profiling;
  end block;
end function %benchmark;

/// Benchmark recording

define method record-benchmark
    (name :: <string>,
     status :: <result-status>,
     reason :: false-or(<string>),
     seconds :: false-or(<integer>),
     microseconds :: false-or(<integer>),
     bytes-allocated :: false-or(<integer>))
 => (status :: <result-status>)
  let result = make(<benchmark-result>,
                    name: name, status: status, reason: reason,
                    seconds: seconds, microseconds: microseconds,
                    bytes: bytes-allocated);
  *check-recording-function*(result);
  status
end method record-benchmark;


/// A few utilities related to benchmarks

define function time-to-string
    (seconds :: false-or(<integer>), microseconds :: false-or(<integer>),
     #key pad-seconds-to :: false-or(<integer>))
 => (seconds :: <string>)
  if (seconds & microseconds)
    format-to-string("%s.%s",
                     integer-to-string(seconds,
                                       size: pad-seconds-to | 6,
                                       fill: ' '),
                     integer-to-string(microseconds, size: 6))
  else
    "N/A"
  end
end;


// Add two times that are encoded as seconds + microseconds.
// Assumes the first time is valid.  The second time may be #f.
//
define method addtimes
    (sec1, usec1, sec2, usec2)
 => (sec, usec)
  if (sec2 & usec2)
    let sec = sec1 + sec2;
    let usec = usec1 + usec2;
    if (usec >= 1000000)
      usec := usec - 1000000;
      sec1 := sec1 + 1;
    end if;
    values(sec, usec)
  else
    values(sec1, sec2)
  end if
end method addtimes;
