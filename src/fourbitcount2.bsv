
package Tb;
(*synthesize*)

module mkTb(Empty);

 Reg#(Bit#(4)) c <- mkReg(0);
 rule increment(c <= 15);
    c <= c+1;
  $display("counter = %b",c);
       
endrule

rule increment1(c==15);
   $display("counter = %b",c);
endrule

rule done (c >= 15);
   $finish(0);
endrule
endmodule:mkTb
endpackage:Tb
