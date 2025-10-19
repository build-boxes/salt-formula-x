#!/bin/bash
echo "===> Bootstrapping Salt master/minion..."
systemctl start salt-master
systemctl start salt-minion
sleep 5
salt-call test.ping
salt-call state.apply
echo "===> Salt master/minion bootstrap complete."

