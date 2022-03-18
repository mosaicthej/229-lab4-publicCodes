rm -f polling_test.s
cat polling.s > polling_test.s
cat GLIM.s >> polling_test.s
spim -f polling_test.s
rm -f test.s