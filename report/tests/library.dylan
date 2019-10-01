Module: dylan-user

define library testworks-report-test-suite
  use common-dylan;
  use testworks;
  use testworks-report-lib;
  use io,
    import: { streams };
end;

define module testworks-report-test-suite
  use common-dylan;
  use streams;
  use testworks;
  use %testworks;
  use testworks-report-lib;
end;
