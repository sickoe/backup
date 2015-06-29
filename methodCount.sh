dx --dex --output=temp.dex $1
cat temp.dex | head -c 92 | tail -c 4 | hexdump -e '1/4 "%d\n"'
rm temp.dex