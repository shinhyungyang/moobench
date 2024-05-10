#!/bin/bash

function getSum {
  awk '{sum += $1; square += $1^2} END {print "Average: "sum/NR" Standard Deviation: "sqrt(square / NR - (sum/NR)^2)" Count: "NR}'
}

export size=10
result="["

for variant in $MOOBENCH_CONFIGURATIONS
do
   values=$(
   for file in $(ls raw-*-$size-$variant.csv)
   do
      cat $file | awk -F';' '{print $2}' | getSum | awk '{print $2}'
   done | getSum)
   value=$(echo $values | awk '{print $2}')
   standardDeviation=$(echo $values | awk '{print $5}')
   
   result="$result{\"name\": \"Configuration $variant\", \"unit\": \"ns\", \"value\": $value, \"range\": $standardDeviation},"
done
withoutLastKomma=${result::-1}

echo "$withoutLastKomma]"
