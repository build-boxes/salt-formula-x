#!/bin/bash
# shopt -s globstar

# echo "===> Running all Serverspec tests..."
# if rspec /srv/salt/formula/**/test/*_spec.rb; then
#   echo "===> All tests passed."
# else
#   echo "===> Some tests failed."
#   exit 1
# fi

echo "===> Running all Serverspec tests..."

# Find all *_spec.rb files under formula/**/test and run them individually
find /srv/salt/formula -type f -path '*/test/*_spec.rb' | while read -r specfile; do
  echo "Running: $specfile"
  rspec "$specfile"
done

echo "===> All tests completed."