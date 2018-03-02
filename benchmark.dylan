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

define method result-type-name
    (result :: <benchmark-result>) => (name :: <string>)
  "Benchmark"
end;
