#! /bin/sh
OUT_FILE=./tests_results.out
echo Testing pi-control web services...
find ./web-services/tests/ -name *_test.rb -exec echo ============================== \; -exec ruby {} \; | tee $OUT_FILE
echo ==============================
echo Done! Results written to $OUT_FILE