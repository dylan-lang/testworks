Module:       %testworks
Synopsis:     Components are suites and tests.
Author:       Shri Amit, Andrew Armstrong
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND


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
end;

define class <benchmark-iteration-result> (<unit-result>, <metered-result>)
end;

define method result-type-name
    (result :: <benchmark-result>) => (name :: <string>)
  "Benchmark"
end;

define method result-type-name
    (result :: <benchmark-iteration-result>) => (name :: <string>)
  "Iteration"
end;

define thread variable *benchmark-recording-function* = always(#f);

define macro benchmark-repeat
  { benchmark-repeat (#key ?iterations:expression = 1)
      ?:body
    end }
    => { local
           method benchmark-body ()
             ?body
           end;
         let name = full-component-name(*component*);
         for (iteration :: <integer> from 0 below ?iterations,
              iteration-values = #[]
                then begin
                       collect-garbage();
                       profiling (cpu-time-seconds,
                                  cpu-time-microseconds,
                                  allocation)
                         let (#rest iteration-values) = benchmark-body();
                         iteration-values
                       results
                         record-benchmark-iteration(name,
                                                    cpu-time-seconds,
                                                    cpu-time-microseconds,
                                                    allocation);
                       end profiling
                     end)
         finally
           apply(values, iteration-values)
         end for }
end;

define method record-benchmark-iteration
    (name, cpu-time-seconds :: <integer>, cpu-time-microseconds :: <integer>,
     allocation :: <integer>)
 => (status :: <result>)
  let result = make(<benchmark-iteration-result>,
                    name: name,
                    status: $passed,
                    seconds: cpu-time-seconds,
                    microseconds: cpu-time-microseconds,
                    bytes: allocation);
  *benchmark-recording-function*(result);
  result
end method record-benchmark-iteration;
