#!/bin/bash
echo "===> Running all Serverspec tests..."

echo "===> Find all *_spec.rb files under formula/**/test/*_spec.rb and run them individually."
echo "     The first line of all tests should be: require '/opt/serverspec/spec_helper'"
# Find all *_spec.rb files under formula/**/test and run them individually
find /srv/salt/formula -type f -path '*/test/*_spec.rb' | while read -r specfile; do
  echo "Running: $specfile"
  rspec "$specfile"
done

echo "===> All tests completed."