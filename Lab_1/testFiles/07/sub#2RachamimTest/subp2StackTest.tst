// This file is part of the materials accompanying the book 
// "The Elements of Computing Systems" by Nisan and Schocken, 
// MIT Press. Book site: www.idc.ac.il/tecs

// New File name: subp2StackTest.tst 
// it includes a rewritten tst script for running a rewritten asm file 

// File name: projects/07/StackArithmetic/StackTest/StackTest.tst

load subp2StackTest.asm, 
output-file subp2StackTest.out, 
compare-to subp2StackTest.cmp, 
output-list RAM[0]%D2.6.2 RAM[256]%D2.6.2 RAM[257]%D2.6.2 
            RAM[258]%D2.6.2 RAM[259]%D2.6.2;

set RAM[0] 256,

repeat 400 {
  ticktock;
}

output;
