Require Import Bool String List.
Require Import Lib.CommonTactics Lib.ilist Lib.Word.
Require Import Lib.Struct Lib.FMap Lib.StringEq Lib.Indexer.
Require Import Kami.Syntax Kami.Semantics Kami.RefinementFacts Kami.Renaming Kami.Wf.
Require Import Kami.Renaming Kami.Inline Kami.InlineFacts.
Require Import Kami.Decomposition Kami.Notations Kami.Tactics.
Require Import Kami.PrimFifo.
Require Import Init.Nat.
Require Import Bsvtokami.

Set Implicit Arguments.
Definition Int := Bit.
Open Scope string.

Module module'mkTb.
  Section section'mkTb.
    Variable instancePrefix : string.
    Definition mkTb := (MODULE {
    Register "c" : (Bit 4) <- Default
    with 
    Rule (instancePrefix--"increment") := 
    (
        Read c_val : (Bit 4) <- "c" ;
        Assert(#c_val <= $15) ;
        Write "c" : Bit 4 <- #c_val + $1 ;
        Call unused : Void <- (MethodSig ("$display") ((Bit 4)) : Void) (#c_val) ;

    Retv
    )

    with 
    Rule (instancePrefix--"increment1") := 
    (
        Read c_val : (Bit 4) <- "c" ;
        Assert(#c_val == $15) ;
        Call unused : Void <- (MethodSig ("$display") ((Bit 4)) : Void) (#c_val) ;

    Retv
    )

    with 
    Rule (instancePrefix--"done") := 
    (
        Read c_val : (Bit 4) <- "c" ;
        Assert(#c_val >= $15) ;
        Call unused : Void <- (MethodSig ("$finish") () : Void)  () ;

    Retv
    )

    }).
  End section'mkTb.
End module'mkTb.

