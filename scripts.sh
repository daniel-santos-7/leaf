ghdl -i --workdir=work ./rtl/*.vhdl 

ghdl -i --workdir=work ./tbs/*.vhdl

for tb in $(basename -s .vhdl ./tbs/*.vhdl); do
    
    ghdl -m --workdir=work $tb;
    ghdl -r --workdir=work $tb --wave=./waves/$tb.ghw;

done

ghdl --remove --workdir=work