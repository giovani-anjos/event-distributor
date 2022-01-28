#!/bin/bash

if python3 -m unittest source/test_functions.py
then
  aws s3 cp source/parser.py s3://pismo-glue-scripts/parser/
  aws s3 cp source/distributor.py s3://pismo-glue-scripts/distributor/
else
  echo "Unit tests failed"
fi