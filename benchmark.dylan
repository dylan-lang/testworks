Module:       %testworks
Synopsis:     Benchmark support code
Author:       Shri Amit, Andrew Armstrong, Bruce Mitchener, Jr.
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND


define thread variable *benchmark* :: false-or(<benchmark-state>) = #f;

// Benchmarks don't require any assertions.
// Benchmarks have the keyword "benchmark".
define class <benchmark> (<runnable>)
  inherited slot test-requires-assertions? = #f;
end;

define method make
    (class :: subclass(<benchmark>), #rest args, #key tags)
 => (test :: <benchmark>)
  let new-tags = concatenate(#["benchmark"], tags | #[]);
  apply(next-method, class, tags: new-tags, args)
end;

define method component-type-name
    (bench :: <benchmark>) => (type-name :: <string>)
  "benchmark"
end;

define method component-result-type
    (component :: <benchmark>) => (result-type :: subclass(<result>))
  <benchmark-result>
end;

define class <benchmark-result> (<component-result>)
  constant slot benchmark-nanoseconds-per-op :: false-or(<double-float>) = #f,
    init-keyword: ns-per-op:;

  constant slot benchmark-bytes-processed-per-second :: false-or(<double-float>) = #f,
    init-keyword: bytes-per-second:;
  constant slot benchmark-items-processed-per-second :: false-or(<double-float>) = #f,
    init-keyword: items-per-second:;

  constant slot benchmark-label :: false-or(<string>) = #f,
    init-keyword: label:;
end;

define method result-type-name
    (result :: <benchmark-result>) => (name :: <string>)
  "Benchmark"
end;

define constant $profiling-keywords
  = #[#"cpu-time-seconds",
      #"cpu-time-microseconds",
      #"allocation"];

define sealed class <benchmark-state> (<object>)
  slot benchmark-started? :: <boolean> = #f;
  slot benchmark-max-iterations :: <integer> = 1;
  slot benchmark-current-iteration :: <integer> = 0;

  slot benchmark-profiling-state :: false-or(<profiling-state>) = #f;
  slot benchmark-cpu-time-seconds :: <integer> = 0;
  slot benchmark-cpu-time-microseconds :: <integer> = 0;
  slot benchmark-allocation :: <integer> = 0;

  slot benchmark-bytes-processed :: false-or(<integer>) = #f;
  slot benchmark-items-processed :: false-or(<integer>) = #f;

  slot benchmark-label :: false-or(<string>) = #f;
end class;

define inline-only function keep-running?
    (state :: <benchmark-state>)
 => (continue? :: <boolean>)
  if (~benchmark-started?(state))
    resume-timing(state);
    benchmark-started?(state) := #t;
  end if;
  let continue? = benchmark-current-iteration(state) = benchmark-max-iterations(state);
  if (continue?)
    benchmark-current-iteration(state) := benchmark-current-iteration(state) + 1;
  else
    pause-timing(state);
  end if;
  continue?
end function;

define function pause-timing
    (state :: <benchmark-state>)
 => ()
  let prof-state :: <profiling-state> = benchmark-profiling-state(state);
  stop-profiling(prof-state, $profiling-keywords);
  let cpu-time-seconds = profiling-type-result(prof-state, #"cpu-time-seconds");
  let cpu-time-microseconds = profiling-type-result(prof-state, #"cpu-time-microseconds");
  let allocation = profiling-type-result(prof-state, #"allocation");
  let (secs, microsecs) = add-times(benchmark-cpu-time-seconds(state),
                                    benchmark-cpu-time-microseconds(state),
                                    profiling-type-result(prof-state, #"cpu-time-seconds"),
                                    profiling-type-result(prof-state, #"cpu-time-microseconds"));
  benchmark-cpu-time-seconds(state) := secs;
  benchmark-cpu-time-microseconds(state) := microsecs;
  benchmark-allocation(state) := benchmark-allocation(state) + allocation;
end function;

define function resume-timing
    (state :: <benchmark-state>)
 => ()
  benchmark-profiling-state(state) := start-profiling($profiling-keywords);
end function;

define method execute-component
    (benchmark :: <benchmark>, runner :: <test-runner>)
 => (result :: <benchmark-result>)
  if (debug-runner?(runner))
    run-benchmark(benchmark);
  else
    block ()
      run-benchmark(benchmark);
    exception (cond :: <serious-condition>)
      make(<benchmark-result>,
           name: benchmark.component-name,
           status: $crashed,
           reason: format-to-string("%s", cond),
           seconds: 0,
           microseconds: 0,
           bytes: 0)
    end
  end if
end method;

define function run-benchmark
    (benchmark :: <benchmark>)
 => (result :: <benchmark-result>)
  let state = make(<benchmark-state>);
  dynamic-bind (*benchmark* = state)
    // In a loop ...
    // Calculate the # of iterations to try
    // Run the benchmark function for that ...
    // Then repeat until we've reached the minimum-duration
    benchmark.test-function(state);
    if (benchmark-started?(state))
      let cpu-time = as(<double-float>, benchmark-cpu-time-seconds(state)) +
                     as(<double-float>, benchmark-cpu-time-microseconds(state)) / 1d6;
      make(<benchmark-result>,
           name: benchmark.component-name,
           status: $passed,
           seconds: benchmark-cpu-time-seconds(state),
           microseconds: benchmark-cpu-time-microseconds(state),
           bytes: benchmark-allocation(state),
           ns-per-op: as(<double-float>, benchmark-max-iterations(state)) / cpu-time,
           items-per-sec: if (benchmark-items-processed(state))
                            as(<double-float>, benchmark-items-processed(state)) / cpu-time
                          else
                            #f
                          end if,
           bytes-per-sec: if (benchmark-bytes-processed(state))
                            as(<double-float>, benchmark-bytes-processed(state)) / cpu-time
                          else
                            #f
                          end if)
    else
      make(<benchmark-result>,
           name: benchmark.component-name,
           status: $not-implemented,
           seconds: 0,
           microseconds: 0,
           bytes: 0)
    end if
  end dynamic-bind
end function;
