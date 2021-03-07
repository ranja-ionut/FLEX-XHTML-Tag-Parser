#!/bin/bash
# Ranja Ionut
FILES=$(ls ./inputs)
IN=./inputs
OUT=./outputs

make clean
make

for f in $FILES
do
	./tema $IN/$f > $OUT/$f.out 	
done

if [ $# -eq 1 ]
then
	rm -rf $OUT/*
fi

make clean