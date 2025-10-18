#!/bin/bash
shopt -s globstar

echo "===> Running all Serverspec tests..."
if rspec /srv/salt/formula/**/test/*_spec.rb; then
  echo "===> All tests passed."
else
  echo "===> Some tests failed."
  exit 1
fi

