#!/bin/bash
echo "===> Bootstrapping Salt master/minion..."
echo "===> Restarting Salt master/minion services..."
systemctl restart salt-master
systemctl restart salt-minion
echo "===> Waiting for 8 seconds..."
sleep 8
echo "===> Testing Salt minion connectivity to master..."
salt-call test.ping
echo "===> Testing Salt master connectivity to minion..."
salt "local-master" test.ping
echo "===> Check salt Master All Keys..."
salt-key -L
echo "===> Now You can apply Salt states..."
echo "For example:"
echo " - From the minion:"
echo "    - salt-call state.apply"
echo "    - salt-call state.apply <state_name>"
echo " - From the master:"
echo "    - salt 'local-master' state.apply"
echo "    - salt 'local-master' state.apply <state_name>"
echo "===> Salt master/minion bootstrap complete."
