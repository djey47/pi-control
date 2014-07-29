#! /bin/sh
OUT_FILE=./tests_results.out
echo Testing pi-control web services...
find ./web-services/tests/ -name *_test.rb -exec echo ============================== \; -exec ruby {} \; > $OUT_FILE
echo Done! See results: less $OUT_FILE