#!/bin/bash
echo "===> Running all Serverspec tests..."
rspec /srv/salt/formula/**/*_spec.rb
echo "===> All tests completed."
