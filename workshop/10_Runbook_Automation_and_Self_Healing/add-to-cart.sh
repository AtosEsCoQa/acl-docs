#!/bin/bash
echo "Press [CTRL+C] to stop.."

url=$1

i=0
while true
do
  echo ""
  echo "adding item to cart..."
  curl -X POST -H "Content-Type: application/json" -d "{\"id\":\"3395a43e-2d88-40de-b95f-e00e1502085b\"}" $url
  i=$((i+1))
done
