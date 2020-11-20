package coherence_types;

`include "coherence.defines"

typedef enum { 
  Load,
  Store,
  Evict,
  None
} Access deriving (Eq, Bits, FShow);


typedef enum { 
  GetS,
  GetS_Ack,
  GetM,
  GetM_Ack_D,
  GetM_Ack_AD,
  Inv_Ack,
  Upgrade,
  PutS,
  Put_Ack,
  WB,
  PutM,
  Inv,
  Fwd_GetS,
  Fwd_GetM
} MessageType deriving (Eq, Bits, FShow);


typedef enum { 
  I,
  M,
  S
} StableStates deriving (Eq, Bits, FShow);


typedef enum { 
  C1_I,
  C1_I_Load,
  C1_I_Load__Inv_I,
  C1_I_Store,
  C1_I_Store_GetM_Ack_AD,
  C1_I_Store_GetM_Ack_AD__Fwd_GetM_I,
  C1_I_Store_GetM_Ack_AD__Fwd_GetS_S,
  C1_I_Store_GetM_Ack_AD__Fwd_GetS_S__Inv_I,
  C1_I_Store__Fwd_GetM_I,
  C1_I_Store__Fwd_GetS_S,
  C1_I_Store__Fwd_GetS_S__Inv_I,
  C1_M,
  C1_M_Evict,
  C1_M_Evict_Fwd_GetM,
  C1_S,
  C1_S_Evict,
  C1_S_Store,
  C1_S_Store_GetM_Ack_AD,
  C1_S_Store_GetM_Ack_AD__Fwd_GetS_S,
  C1_S_Store__Fwd_GetS_S
} C1 deriving (Eq, Bits, FShow);


typedef enum { 
  Dict_I,
  Dict_M,
  Dict_M_GetS,
  Dict_S
} Dict deriving (Eq, Bits, FShow);

typedef Bit#(`linesize) ClValue;


typedef union tagged {
 
  Bit#(TLog#(TMul#(2,`NrCaches))) Caches;
  void Directory;
} Machines deriving(Eq, Bits, FShow);

typedef struct {
  Bit#(`paddr) address;
  MessageType msgtype;
  Machines src;
  Machines dst;
  Bit#(TLog#(`NrCaches)) acksExpected;
  ClValue cl;

} Message deriving(Eq, Bits, FShow);

typedef struct {
  C1 state;
  Access perm;
  ClValue cl;
  Bit#(TLog#(`NrCaches)) acksReceived;
  Bit#(TLog#(`NrCaches)) acksExpected;
  Machines id;

} ENTRY_C1 deriving(Eq, Bits, FShow);


typedef struct {
  Dict state;
  Access perm;
  ClValue cl;
  V_NrCaches_OBJSET_sv sv;
  Machines owner;
  Machines id;

} ENTRY_Dict deriving(Eq, Bits, FShow);

typedef Bit#(`NrCaches) V_NrCaches_OBJSET_sv;
typedef Bit#(TLog#(`NrCaches)) Cnt_V_NrCaches_OBJSET_sv;


function Message fn_Request(Bit#(`paddr) address, MessageType msgtype, Machines src, Machines dst);
  Message msg;
  msg.address = address;
  msg.msgtype = msgtype;
  msg.src = src;
  msg.dst = dst;
  msg.acksExpected = ?;
  msg.cl = ?;
  return msg;
endfunction

function Message fn_Ack(Bit#(`paddr) address, MessageType msgtype, Machines src, Machines dst);
  Message msg;
  msg.address = address;
  msg.msgtype = msgtype;
  msg.src = src;
  msg.dst = dst;
  msg.acksExpected = ?;
  msg.cl = ?;
  return msg;
endfunction

function Message fn_Resp(Bit#(`paddr) address, MessageType msgtype, Machines src, Machines dst, ClValue cl);
  Message msg;
  msg.address = address;
  msg.msgtype = msgtype;
  msg.src = src;
  msg.dst = dst;
  msg.acksExpected = ?;
  msg.cl = cl;
  return msg;
endfunction

function Message fn_RespAck(Bit#(`paddr) address, MessageType msgtype, Machines src, Machines dst, ClValue cl, Bit#(TLog#(`NrCaches)) acksExpected);
  Message msg;
  msg.address = address;
  msg.msgtype = msgtype;
  msg.src = src;
  msg.dst = dst;
  msg.acksExpected = acksExpected;
  msg.cl = cl;
  return msg;
endfunction



function V_NrCaches_OBJSET_sv fn_Clear(V_NrCaches_OBJSET_sv sv);
  return 0;
endfunction

function V_NrCaches_OBJSET_sv fn_RemoveElement(V_NrCaches_OBJSET_sv sv, Machines src);
  if ( src matches tagged Caches .c)
    sv[c] = 0;
  return sv;
endfunction

function V_NrCaches_OBJSET_sv fn_AddElement(V_NrCaches_OBJSET_sv sv, Machines src);
  if ( src matches tagged Caches .c)
      sv[c] = 1;
  return sv;
endfunction

function Bool fn_IsElement (V_NrCaches_OBJSET_sv sv, Machines i);
  if ( i matches tagged Caches .c)
    return unpack(sv[c]);
  else
    return False;
endfunction

function Cnt_V_NrCaches_OBJSET_sv fn_VectorCount (V_NrCaches_OBJSET_sv sv);
  return truncate(pack(countOnes(sv)));
endfunction




(*noinline*)
function Tuple5#(ENTRY_C1, Maybe#(Message), Maybe#(Message), Maybe#(Message),Bool) func_C1(Message inmsg, ENTRY_C1 cle);
  Message msg; 
  let address = inmsg.address ;
  Maybe#(Message) send_resp = tagged Invalid;
  Maybe#(Message) enq_defermsg1 = tagged Invalid;
  Maybe#(Message) enq_defermsg2 = tagged Invalid;
  Bool send_defermsg = False;
  case (cle.state) 

    C1_I: begin
    case (inmsg.msgtype)
       default: msg = inmsg;
    endcase
    end

    C1_I_Load: begin
    case (inmsg.msgtype)
      GetS_Ack: begin
        cle.cl = inmsg.cl;
        cle.state = C1_S;
        cle.perm = Load;

      end

      Inv: begin
        msg = fn_Resp(address,Inv_Ack,cle.id,inmsg.src,cle.cl);
        send_resp = tagged Valid msg;
        cle.state = C1_I_Load__Inv_I;
        cle.perm = None;

      end

       default: msg = inmsg;
    endcase
    end

    C1_I_Load__Inv_I: begin
    case (inmsg.msgtype)
      GetS_Ack: begin
        cle.cl = inmsg.cl;
        cle.state = C1_I;
        cle.perm = None;

      end

       default: msg = inmsg;
    endcase
    end

    C1_I_Store: begin
    case (inmsg.msgtype)
      Fwd_GetM: begin
        msg = fn_Resp(address,GetM_Ack_D,cle.id,inmsg.src,cle.cl);
        enq_defermsg1 = tagged Valid msg;
        cle.state = C1_I_Store__Fwd_GetM_I;
        cle.perm = None;

      end

      Fwd_GetS: begin
        msg = fn_Resp(address,GetS_Ack,cle.id,inmsg.src,cle.cl);
        enq_defermsg1 = tagged Valid msg;
        msg = fn_Resp(address,WB,cle.id,tagged Directory,cle.cl);
        enq_defermsg2 = tagged Valid msg;
        cle.state = C1_I_Store__Fwd_GetS_S;
        cle.perm = None;

      end

      GetM_Ack_AD: begin
        cle.acksExpected = inmsg.acksExpected;
        if (cle.acksExpected == cle.acksReceived) begin
        cle.state = C1_M;
        cle.perm = Store;

      end

        else begin
        cle.state = C1_I_Store_GetM_Ack_AD;
        cle.perm = None;
        end

      end

      GetM_Ack_D: begin
        cle.cl = inmsg.cl;
        cle.state = C1_M;
        cle.perm = Store;

      end

      Inv_Ack: begin
        cle.acksReceived = cle.acksReceived+1;
        cle.state = C1_I_Store;
        cle.perm = None;

      end

       default: msg = inmsg;
    endcase
    end

    C1_I_Store_GetM_Ack_AD: begin
    case (inmsg.msgtype)
      Fwd_GetM: begin
        msg = fn_Resp(address,GetM_Ack_D,cle.id,inmsg.src,cle.cl);
        enq_defermsg1 = tagged Valid msg;
        cle.state = C1_I_Store_GetM_Ack_AD__Fwd_GetM_I;
        cle.perm = None;

      end

      Fwd_GetS: begin
        msg = fn_Resp(address,GetS_Ack,cle.id,inmsg.src,cle.cl);
        enq_defermsg1 = tagged Valid msg;
        msg = fn_Resp(address,WB,cle.id,tagged Directory,cle.cl);
        enq_defermsg2 = tagged Valid msg;
        cle.state = C1_I_Store_GetM_Ack_AD__Fwd_GetS_S;
        cle.perm = None;

      end

      Inv_Ack: begin
        cle.acksReceived = cle.acksReceived+1;
        if (cle.acksExpected == cle.acksReceived) begin
        cle.state = C1_M;
        cle.perm = Store;

      end

        else begin
        cle.state = C1_I_Store_GetM_Ack_AD;
        cle.perm = None;
        end

      end

       default: msg = inmsg;
    endcase
    end

    C1_I_Store_GetM_Ack_AD__Fwd_GetM_I: begin
    case (inmsg.msgtype)
      Inv_Ack: begin
        cle.acksReceived = cle.acksReceived+1;
        if (cle.acksExpected == cle.acksReceived) begin
        cle.state = C1_I;
        cle.perm = None;
        send_defermsg = True;

      end

        else begin
        cle.state = C1_I_Store_GetM_Ack_AD__Fwd_GetM_I;
        cle.perm = None;
        end

      end

       default: msg = inmsg;
    endcase
    end

    C1_I_Store_GetM_Ack_AD__Fwd_GetS_S: begin
    case (inmsg.msgtype)
      Inv: begin
        msg = fn_Resp(address,Inv_Ack,cle.id,inmsg.src,cle.cl);
        send_resp = tagged Valid msg;
        cle.state = C1_I_Store_GetM_Ack_AD__Fwd_GetS_S__Inv_I;
        cle.perm = None;

      end

      Inv_Ack: begin
        cle.acksReceived = cle.acksReceived+1;
        if (cle.acksExpected == cle.acksReceived) begin
        cle.state = C1_S;
        cle.perm = Load;
        send_defermsg = True;

      end

        else begin
        cle.state = C1_I_Store_GetM_Ack_AD__Fwd_GetS_S;
        cle.perm = None;
        end

      end

       default: msg = inmsg;
    endcase
    end

    C1_I_Store_GetM_Ack_AD__Fwd_GetS_S__Inv_I: begin
    case (inmsg.msgtype)
      Inv_Ack: begin
        cle.acksReceived = cle.acksReceived+1;
        if (cle.acksExpected == cle.acksReceived) begin
        cle.state = C1_I;
        cle.perm = None;
        send_defermsg = True;

      end

        else begin
        cle.state = C1_I_Store_GetM_Ack_AD__Fwd_GetS_S__Inv_I;
        cle.perm = None;
        end

      end

       default: msg = inmsg;
    endcase
    end

    C1_I_Store__Fwd_GetM_I: begin
    case (inmsg.msgtype)
      GetM_Ack_AD: begin
        cle.acksExpected = inmsg.acksExpected;
        if (cle.acksExpected == cle.acksReceived) begin
        cle.state = C1_I;
        cle.perm = None;
        send_defermsg = True;

      end

        else begin
        cle.state = C1_I_Store_GetM_Ack_AD__Fwd_GetM_I;
        cle.perm = None;
        end

      end

      GetM_Ack_D: begin
        cle.cl = inmsg.cl;
        cle.state = C1_I;
        cle.perm = None;
        send_defermsg = True;

      end

      Inv_Ack: begin
        cle.acksReceived = cle.acksReceived+1;
        cle.state = C1_I_Store__Fwd_GetM_I;
        cle.perm = None;

      end

       default: msg = inmsg;
    endcase
    end

    C1_I_Store__Fwd_GetS_S: begin
    case (inmsg.msgtype)
      GetM_Ack_AD: begin
        cle.acksExpected = inmsg.acksExpected;
        if (cle.acksExpected == cle.acksReceived) begin
        cle.state = C1_S;
        cle.perm = Load;
        send_defermsg = True;

      end

        else begin
        cle.state = C1_I_Store_GetM_Ack_AD__Fwd_GetS_S;
        cle.perm = None;
        end

      end

      GetM_Ack_D: begin
        cle.cl = inmsg.cl;
        cle.state = C1_S;
        cle.perm = Load;
        send_defermsg = True;

      end

      Inv: begin
        msg = fn_Resp(address,Inv_Ack,cle.id,inmsg.src,cle.cl);
        send_resp = tagged Valid msg;
        cle.state = C1_I_Store__Fwd_GetS_S__Inv_I;
        cle.perm = None;

      end

      Inv_Ack: begin
        cle.acksReceived = cle.acksReceived+1;
        cle.state = C1_I_Store__Fwd_GetS_S;
        cle.perm = None;

      end

       default: msg = inmsg;
    endcase
    end

    C1_I_Store__Fwd_GetS_S__Inv_I: begin
    case (inmsg.msgtype)
      GetM_Ack_AD: begin
        cle.acksExpected = inmsg.acksExpected;
        if (cle.acksExpected == cle.acksReceived) begin
        cle.state = C1_I;
        cle.perm = None;
        send_defermsg = True;

      end

        else begin
        cle.state = C1_I_Store_GetM_Ack_AD__Fwd_GetS_S__Inv_I;
        cle.perm = None;
        end

      end

      GetM_Ack_D: begin
        cle.cl = inmsg.cl;
        cle.state = C1_I;
        cle.perm = None;
        send_defermsg = True;

      end

      Inv_Ack: begin
        cle.acksReceived = cle.acksReceived+1;
        cle.state = C1_I_Store__Fwd_GetS_S__Inv_I;
        cle.perm = None;

      end

       default: msg = inmsg;
    endcase
    end

    C1_M: begin
    case (inmsg.msgtype)
      Fwd_GetM: begin
        msg = fn_Resp(address,GetM_Ack_D,cle.id,inmsg.src,cle.cl);
        enq_defermsg1 = tagged Valid msg;
        send_defermsg = True;
        cle.state = C1_I;
        cle.perm = None;

      end

      Fwd_GetS: begin
        msg = fn_Resp(address,GetS_Ack,cle.id,inmsg.src,cle.cl);
        enq_defermsg1 = tagged Valid msg;
        msg = fn_Resp(address,WB,cle.id,tagged Directory,cle.cl);
        enq_defermsg2 = tagged Valid msg;
        send_defermsg = True;
        cle.state = C1_S;
        cle.perm = Load;

      end

       default: msg = inmsg;
    endcase
    end

    C1_M_Evict: begin
    case (inmsg.msgtype)
      Fwd_GetM: begin
        msg = fn_Resp(address,GetM_Ack_D,cle.id,inmsg.src,cle.cl);
        enq_defermsg1 = tagged Valid msg;
        send_defermsg = True;
        cle.state = C1_M_Evict_Fwd_GetM;
        cle.perm = None;

      end

      Fwd_GetS: begin
        msg = fn_Resp(address,GetS_Ack,cle.id,inmsg.src,cle.cl);
        enq_defermsg1 = tagged Valid msg;
        msg = fn_Resp(address,WB,cle.id,tagged Directory,cle.cl);
        enq_defermsg2 = tagged Valid msg;
        send_defermsg = True;
        cle.state = C1_S_Evict;
        cle.perm = None;

      end

      Put_Ack: begin
        cle.state = C1_I;
        cle.perm = None;

      end

       default: msg = inmsg;
    endcase
    end

    C1_M_Evict_Fwd_GetM: begin
    case (inmsg.msgtype)
      Put_Ack: begin
        cle.state = C1_I;
        cle.perm = None;

      end

       default: msg = inmsg;
    endcase
    end

    C1_S: begin
    case (inmsg.msgtype)
      Inv: begin
        msg = fn_Resp(address,Inv_Ack,cle.id,inmsg.src,cle.cl);
        send_resp = tagged Valid msg;
        cle.state = C1_I;
        cle.perm = None;

      end

       default: msg = inmsg;
    endcase
    end

    C1_S_Evict: begin
    case (inmsg.msgtype)
      Inv: begin
        msg = fn_Resp(address,Inv_Ack,cle.id,inmsg.src,cle.cl);
        send_resp = tagged Valid msg;
        cle.state = C1_M_Evict_Fwd_GetM;
        cle.perm = None;

      end

      Put_Ack: begin
        cle.state = C1_I;
        cle.perm = None;

      end

       default: msg = inmsg;
    endcase
    end

    C1_S_Store: begin
    case (inmsg.msgtype)
      Fwd_GetM: begin
        msg = fn_Resp(address,GetM_Ack_D,cle.id,inmsg.src,cle.cl);
        enq_defermsg1 = tagged Valid msg;
        cle.state = C1_I_Store__Fwd_GetM_I;
        cle.perm = None;

      end

      Fwd_GetS: begin
        msg = fn_Resp(address,GetS_Ack,cle.id,inmsg.src,cle.cl);
        enq_defermsg1 = tagged Valid msg;
        msg = fn_Resp(address,WB,cle.id,tagged Directory,cle.cl);
        enq_defermsg2 = tagged Valid msg;
        cle.state = C1_S_Store__Fwd_GetS_S;
        cle.perm = Load;

      end

      GetM_Ack_AD: begin
        cle.acksExpected = inmsg.acksExpected;
        if (cle.acksExpected == cle.acksReceived) begin
        cle.state = C1_M;
        cle.perm = Store;

      end

        else begin
        cle.state = C1_S_Store_GetM_Ack_AD;
        cle.perm = Load;
        end

      end

      GetM_Ack_D: begin
        cle.state = C1_M;
        cle.perm = Store;

      end

      Inv: begin
        msg = fn_Resp(address,Inv_Ack,cle.id,inmsg.src,cle.cl);
        send_resp = tagged Valid msg;
        cle.state = C1_I_Store;
        cle.perm = None;

      end

      Inv_Ack: begin
        cle.acksReceived = cle.acksReceived+1;
        cle.state = C1_S_Store;
        cle.perm = Load;

      end

       default: msg = inmsg;
    endcase
    end

    C1_S_Store_GetM_Ack_AD: begin
    case (inmsg.msgtype)
      Fwd_GetM: begin
        msg = fn_Resp(address,GetM_Ack_D,cle.id,inmsg.src,cle.cl);
        enq_defermsg1 = tagged Valid msg;
        cle.state = C1_I_Store_GetM_Ack_AD__Fwd_GetM_I;
        cle.perm = None;

      end

      Fwd_GetS: begin
        msg = fn_Resp(address,GetS_Ack,cle.id,inmsg.src,cle.cl);
        enq_defermsg1 = tagged Valid msg;
        msg = fn_Resp(address,WB,cle.id,tagged Directory,cle.cl);
        enq_defermsg2 = tagged Valid msg;
        cle.state = C1_S_Store_GetM_Ack_AD__Fwd_GetS_S;
        cle.perm = Load;

      end

      Inv_Ack: begin
        cle.acksReceived = cle.acksReceived+1;
        if (cle.acksExpected == cle.acksReceived) begin
        cle.state = C1_M;
        cle.perm = Store;

      end

        else begin
        cle.state = C1_S_Store_GetM_Ack_AD;
        cle.perm = Load;
        end

      end

       default: msg = inmsg;
    endcase
    end

    C1_S_Store_GetM_Ack_AD__Fwd_GetS_S: begin
    case (inmsg.msgtype)
      Inv: begin
        msg = fn_Resp(address,Inv_Ack,cle.id,inmsg.src,cle.cl);
        send_resp = tagged Valid msg;
        cle.state = C1_I_Store_GetM_Ack_AD__Fwd_GetS_S__Inv_I;
        cle.perm = None;

      end

      Inv_Ack: begin
        cle.acksReceived = cle.acksReceived+1;
        if (cle.acksExpected == cle.acksReceived) begin
        cle.state = C1_S;
        cle.perm = Load;
        send_defermsg = True;

      end

        else begin
        cle.state = C1_S_Store_GetM_Ack_AD__Fwd_GetS_S;
        cle.perm = Load;
        end

      end

       default: msg = inmsg;
    endcase
    end

    C1_S_Store__Fwd_GetS_S: begin
    case (inmsg.msgtype)
      GetM_Ack_AD: begin
        cle.acksExpected = inmsg.acksExpected;
        if (cle.acksExpected == cle.acksReceived) begin
        cle.state = C1_S;
        cle.perm = Load;
        send_defermsg = True;

      end

        else begin
        cle.state = C1_S_Store_GetM_Ack_AD__Fwd_GetS_S;
        cle.perm = Load;
        end

      end

      GetM_Ack_D: begin
        cle.state = C1_S;
        cle.perm = Load;
        send_defermsg = True;

      end

      Inv: begin
        msg = fn_Resp(address,Inv_Ack,cle.id,inmsg.src,cle.cl);
        send_resp = tagged Valid msg;
        cle.state = C1_I_Store__Fwd_GetS_S__Inv_I;
        cle.perm = None;

      end

      Inv_Ack: begin
        cle.acksReceived = cle.acksReceived+1;
        cle.state = C1_S_Store__Fwd_GetS_S;
        cle.perm = Load;

      end

       default: msg = inmsg;
    endcase
    end

endcase
return tuple5(cle, send_resp, enq_defermsg1, enq_defermsg2, send_defermsg);
endfunction
(*noinline*)
function Tuple5#(ENTRY_Dict, Maybe#(Message), Maybe#(Message), Maybe#(Message), Maybe#(Message)) func_Dict(Message inmsg, ENTRY_Dict cle);
  Message msg; 
  let address = inmsg.address ;
  Maybe#(Message) send_resp = tagged Invalid;
  Maybe#(Message) send_req = tagged Invalid;
  Maybe#(Message) send_fwd = tagged Invalid;
  Maybe#(Message) send_multicast = tagged Invalid;
  case (cle.state) 

    Dict_I: begin
    case (inmsg.msgtype)
      GetM: begin
        msg = fn_RespAck(address,GetM_Ack_AD,cle.id,inmsg.src,cle.cl,fn_VectorCount (cle.sv));
        send_resp = tagged Valid msg;
        cle.owner = inmsg.src;
        cle.state = Dict_M;
        cle.perm = None;

      end

      GetS: begin
        cle.sv = fn_AddElement(cle.sv,inmsg.src);
        msg = fn_Resp(address,GetS_Ack,cle.id,inmsg.src,cle.cl);
        send_resp = tagged Valid msg;
        cle.state = Dict_S;
        cle.perm = None;

      end

      PutM: begin
        msg = fn_Ack(address,Put_Ack,cle.id,inmsg.src);
        send_fwd = tagged Valid msg;
        cle.sv = fn_RemoveElement(cle.sv,inmsg.src);
        if (cle.owner == inmsg.src) begin
        cle.cl = inmsg.cl;
        cle.state = Dict_I;
        cle.perm = None;

      end

        else begin
        cle.state = Dict_I;
        cle.perm = None;
        end

      end

      PutS: begin
        msg = fn_Resp(address,Put_Ack,cle.id,inmsg.src,cle.cl);
        send_fwd = tagged Valid msg;
        cle.sv = fn_RemoveElement(cle.sv,inmsg.src);
        if (fn_VectorCount (cle.sv) == 0) begin
        cle.state = Dict_I;
        cle.perm = None;

      end

        else begin
        cle.state = Dict_I;
        cle.perm = None;
        end

      end

      Upgrade: begin
        msg = fn_RespAck(address,GetM_Ack_AD,cle.id,inmsg.src,cle.cl,fn_VectorCount (cle.sv));
        send_resp = tagged Valid msg;
        cle.owner = inmsg.src;
        cle.state = Dict_M;
        cle.perm = None;

      end

       default: msg = inmsg;
    endcase
    end

    Dict_M: begin
    case (inmsg.msgtype)
      GetM: begin
        msg = fn_Request(address,Fwd_GetM,inmsg.src,cle.owner);
        send_fwd = tagged Valid msg;
        cle.owner = inmsg.src;
        cle.state = Dict_M;
        cle.perm = None;

      end

      GetS: begin
        msg = fn_Request(address,Fwd_GetS,inmsg.src,cle.owner);
        send_fwd = tagged Valid msg;
        cle.sv = fn_AddElement(cle.sv,inmsg.src);
        cle.sv = fn_AddElement(cle.sv,cle.owner);
        cle.state = Dict_M_GetS;
        cle.perm = None;

      end

      PutM: begin
        msg = fn_Ack(address,Put_Ack,cle.id,inmsg.src);
        send_fwd = tagged Valid msg;
        cle.sv = fn_RemoveElement(cle.sv,inmsg.src);
        if (cle.owner == inmsg.src) begin
        cle.cl = inmsg.cl;
        cle.state = Dict_I;
        cle.perm = None;

      end

        else begin
        cle.state = Dict_M;
        cle.perm = None;
        end

      end

      PutS: begin
        msg = fn_Resp(address,Put_Ack,cle.id,inmsg.src,cle.cl);
        send_fwd = tagged Valid msg;
        cle.sv = fn_RemoveElement(cle.sv,inmsg.src);
        if (fn_VectorCount (cle.sv) == 0) begin
        cle.state = Dict_M;
        cle.perm = None;

      end

        else begin
        cle.state = Dict_M;
        cle.perm = None;
        end

      end

      Upgrade: begin
        msg = fn_Request(address,Fwd_GetM,inmsg.src,cle.owner);
        send_fwd = tagged Valid msg;
        cle.owner = inmsg.src;
        cle.state = Dict_M;
        cle.perm = None;

      end

       default: msg = inmsg;
    endcase
    end

    Dict_M_GetS: begin
    case (inmsg.msgtype)
      WB: begin
        if (inmsg.src == cle.owner) begin
        cle.cl = inmsg.cl;
        cle.state = Dict_S;
        cle.perm = None;

      end

        else begin
        cle.state = Dict_M_GetS;
        cle.perm = None;
        end

      end

       default: msg = inmsg;
    endcase
    end

    Dict_S: begin
    case (inmsg.msgtype)
      GetM: begin
        if (fn_IsElement (cle.sv,inmsg.src)) begin
        cle.sv = fn_RemoveElement(cle.sv,inmsg.src);
        msg = fn_RespAck(address,GetM_Ack_AD,cle.id,inmsg.src,cle.cl,fn_VectorCount (cle.sv));
        send_resp = tagged Valid msg;
        cle.state = Dict_M;
        cle.perm = None;
        msg = fn_Ack(address,Inv,inmsg.src,inmsg.src);
        send_multicast = tagged Valid msg;
        cle.owner = inmsg.src;
        cle.sv = fn_Clear(cle.sv);

      end

        else begin
        msg = fn_RespAck(address,GetM_Ack_AD,cle.id,inmsg.src,cle.cl,fn_VectorCount (cle.sv));
        send_resp = tagged Valid msg;
        cle.state = Dict_M;
        cle.perm = None;
        msg = fn_Ack(address,Inv,inmsg.src,inmsg.src);
        send_multicast = tagged Valid msg;
        cle.owner = inmsg.src;
        cle.sv = fn_Clear(cle.sv);
        end

      end

      GetS: begin
        cle.sv = fn_AddElement(cle.sv,inmsg.src);
        msg = fn_Resp(address,GetS_Ack,cle.id,inmsg.src,cle.cl);
        send_resp = tagged Valid msg;
        cle.state = Dict_S;
        cle.perm = None;

      end

      PutM: begin
        msg = fn_Ack(address,Put_Ack,cle.id,inmsg.src);
        send_fwd = tagged Valid msg;
        cle.sv = fn_RemoveElement(cle.sv,inmsg.src);
        if (cle.owner == inmsg.src) begin
        cle.cl = inmsg.cl;
        cle.state = Dict_S;
        cle.perm = None;

      end

        else begin
        cle.state = Dict_S;
        cle.perm = None;
        end

      end

      PutS: begin
        msg = fn_Resp(address,Put_Ack,cle.id,inmsg.src,cle.cl);
        send_fwd = tagged Valid msg;
        cle.sv = fn_RemoveElement(cle.sv,inmsg.src);
        if (fn_VectorCount (cle.sv) == 0) begin
        cle.state = Dict_I;
        cle.perm = None;

      end

        else begin
        cle.state = Dict_S;
        cle.perm = None;
        end

      end

      Upgrade: begin
        if (fn_IsElement (cle.sv,inmsg.src)) begin
        cle.sv = fn_RemoveElement(cle.sv,inmsg.src);
        msg = fn_RespAck(address,GetM_Ack_AD,cle.id,inmsg.src,cle.cl,fn_VectorCount (cle.sv));
        send_resp = tagged Valid msg;
        cle.state = Dict_M;
        cle.perm = None;
        msg = fn_Ack(address,Inv,inmsg.src,inmsg.src);
        send_multicast = tagged Valid msg;
        cle.owner = inmsg.src;
        cle.sv = fn_Clear(cle.sv);

      end

        else begin
        msg = fn_RespAck(address,GetM_Ack_AD,cle.id,inmsg.src,cle.cl,fn_VectorCount (cle.sv));
        send_resp = tagged Valid msg;
        cle.state = Dict_M;
        cle.perm = None;
        msg = fn_Ack(address,Inv,inmsg.src,inmsg.src);
        send_multicast = tagged Valid msg;
        cle.owner = inmsg.src;
        cle.sv = fn_Clear(cle.sv);
        end

      end

       default: msg = inmsg;
    endcase
    end

endcase
return tuple5(cle, send_resp, send_req, send_fwd, send_multicast);
endfunction


function Tuple2#(ENTRY_C1,Maybe#(Message)) func_frm_core (ENTRY_C1 cle, Bit#(`paddr) address, Access request, StableStates ss);

  Message msg=unpack(0); 
  Maybe#(Message) send_req = tagged Invalid;

  if (ss == I && request == Load) begin
    msg = fn_Request(address,GetS,cle.id,tagged Directory);
    send_req = tagged Valid msg;
    cle.state = C1_I_Load;
    cle.perm = None;
  end

  if (ss == I && request == Store) begin
    msg = fn_Request(address,GetM,cle.id,tagged Directory);
    send_req = tagged Valid msg;
    cle.acksReceived = 0;
    cle.state = C1_I_Store;
    cle.perm = None;
  end


  if (ss == M && request == Evict) begin
    msg = fn_Resp(address,PutM,cle.id,tagged Directory,cle.cl);
    send_req = tagged Valid msg;
    cle.state = C1_M_Evict;
    cle.perm = None;
  end

  if (ss == M && request == Load) begin
    cle.state = C1_M;
    cle.perm = Store;
  end

  if (ss == M && request == Store) begin
    cle.state = C1_M;
    cle.perm = Store;
  end


  if (ss == S && request == Evict) begin
    msg = fn_Request(address,PutS,cle.id,tagged Directory);
    send_req = tagged Valid msg;
    cle.state = C1_S_Evict;
    cle.perm = None;
  end

  if (ss == S && request == Load) begin
    cle.state = C1_S;
    cle.perm = Load;
  end

  if (ss == S && request == Store) begin
    msg = fn_Request(address,Upgrade,cle.id,tagged Directory);
    send_req = tagged Valid msg;
    cle.acksReceived = 0;
    cle.state = C1_S_Store;
    cle.perm = Load;
  end


  return tuple2(cle, send_req);

endfunction


endpackage
