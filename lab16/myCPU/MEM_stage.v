`include "mycpu.h"

module mem_stage(
    input                          clk           ,
    input                          reset         ,
    //allowin
    input                          ws_allowin    ,
    output                         ms_allowin    ,
    //from es
    input                          es_to_ms_valid,
    input  [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus  ,
    //to ws
    output                         ms_to_ws_valid,
    output [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus  ,
    //from data-sram
    input  [31                 :0] data_sram_rdata,
    
    //output  [5   :0]                ms_dest_withvalid
    output  [38   :0]                ms_dest_withvalid,
    input                           ws_to_ms_bus,
    output                          ms_to_es_bus,
    input data_data_ok,
    output ms_to_es_tlbp
);
reg WB_EX;
reg         ms_valid;
wire        ms_ready_go;

reg [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus_r;
wire        ms_res_from_mem;
wire        ms_gr_we;
wire [ 4:0] ms_dest;
wire [31:0] ms_alu_result;
wire [31:0] ms_pc;
////////////////////////////////////
wire inst_lb,inst_lbu,inst_lh,inst_lhu;
wire inst_lwl,inst_lwr;
wire inst_mfc0,inst_mtc0;
wire [31:0] ms_rt_value;
wire [1:0] load_choice;
wire [4:0] rt;

wire ms_ex;
wire ex;
wire inst_eret;
wire ms_bd;
wire [ 4:0] ms_excode;
wire [31:0] ms_badvaddr;

wire load_store;
///////////////////////////////////
wire ms_refetch;
////////////////////////////////
wire tlbp,tlbr,tlbwi;
wire tlbp_found;
wire [3:0] index;
wire tlb_miss_ms;
//////////////////////////////
assign {
       tlb_miss_ms,
       ms_refetch,          //167
       index,               //166:163
       tlbp_found,          //162
       tlbp,                //161
       tlbr,                //160
       tlbwi,               //159
       load_store,       //158
       ms_badvaddr,      //157:126
       ex,               //125
       inst_eret,        //124
       ms_bd,            //123
       ms_excode,        //122:118
       rt,               //117:113
       inst_mfc0,        //112
       inst_mtc0,        //111
       ms_rt_value,      //110:79
       inst_lwl,         //78
       inst_lwr,         //77
       load_choice,      //76:75
       inst_lb,          //74
       inst_lbu,         //73
       inst_lh,          //72
       inst_lhu,         //71
        ms_res_from_mem,  //70:70
        ms_gr_we       ,  //69:69                     
        ms_dest        ,  //68:64          //mfc0时为rd
        ms_alu_result  ,  //63:32
        ms_pc             //31:0
       } = (~WB_EX & ~ws_to_ms_bus ) ? es_to_ms_bus_r : 0;

wire [31:0] mem_result;
wire [31:0] ms_final_result;
////////////////////////////////////////////////////////////////////////
    wire    block_valid,block;
    assign block = (ms_dest == 5'd0)?0:ms_gr_we;
    assign block_valid = block&ms_to_ws_valid;
    assign ms_dest_withvalid = {inst_mfc0&ms_valid|ms_res_from_mem&~ms_ready_go&ms_valid,ms_final_result,block_valid,ms_dest};
   // assign ms_dest_withvalid = {block_valid,ms_dest};
reg flag;
always@(posedge clk) begin
    if(reset)
        flag <= 0;
    if(es_to_ms_valid && ms_allowin)
        flag <= 1;
    if(ms_to_ws_valid && ws_allowin) 
        flag <= 0;
end
   
   assign ms_to_es_tlbp = inst_mtc0 & flag;  //先不考虑修改的是不是entryhi
   //未考虑wb阶段的写那一拍
///////////////////////////////////////////////////////////////////////


assign ms_ex = ex & ms_to_ws_valid;

assign ms_to_es_bus = ms_ex | (inst_eret | tlbwi | tlbr) &ms_to_ws_valid ;

assign ms_to_ws_bus = {
                       tlb_miss_ms,
                       ms_refetch,          //157
                       index,               //156:153
                       tlbp_found,          //152
                       tlbp,                //151
                       tlbr,                //150
                       tlbwi,               //149
                       ms_badvaddr    ,  //148:117
                       ms_ex          ,  //116
                       inst_eret      ,  //115
                       ms_bd          ,  //114
                       ms_excode      ,  //113:109
                       rt             ,  //108:104
                       inst_mfc0      ,  //103
                       inst_mtc0      ,  //102
                       ms_rt_value    ,  //101:70
                       ms_gr_we       ,  //69:69
                       ms_dest        ,  //68:64     //mfc0时为rd
                       ms_final_result,  //63:32
                       ms_pc             //31:0
                      };
///////////////////////////////////////////////
reg data_data_arrived;
always @(posedge clk)begin
    if(reset)
        data_data_arrived<=0;
    else if(data_data_arrived)
        data_data_arrived<=0;
    else if(data_data_ok)
        data_data_arrived<=1;
end


always@(posedge clk)begin
    if(reset)
        WB_EX<=1'b0;
    else if(ws_to_ms_bus)
        WB_EX<=1'b1;
    else if(es_to_ms_valid && ms_allowin)
        WB_EX<=1'b0;
end
//assign ms_ready_go    = !ms_res_from_mem||data_data_arrived;
//assign ms_ready_go    = !ms_res_from_mem||data_data_arrived||data_data_ok ||ex;//sw也需要阻塞
//assign ms_ready_go    = !load_store||data_data_arrived||data_data_ok ||ex;//sw也需要阻塞
assign ms_ready_go    = !load_store||data_data_arrived||ex ||  ws_to_ms_bus   ||  WB_EX;//sw也需要阻塞
assign ms_allowin     = !ms_valid|| ms_ready_go && ws_allowin;
assign ms_to_ws_valid = ms_valid && ms_ready_go;
always @(posedge clk) begin
    if (reset) begin
        ms_valid <= 1'b0;
    end
    else if (ms_allowin) begin
        ms_valid <= es_to_ms_valid;
    end

    if (es_to_ms_valid && ms_allowin) begin
        es_to_ms_bus_r  <= es_to_ms_bus;            
    end
end

assign mem_result = data_sram_rdata;
////////////////////////////////////
wire   [31:0] MEM_result;
assign MEM_result =  (inst_lb)?  (load_choice == 2'b00)?{{24{mem_result[7]}},mem_result[7:0]}
                                 :(load_choice == 2'b01)?{{24{mem_result[15]}},mem_result[15:8]}
                                 :(load_choice == 2'b10)?{{24{mem_result[23]}},mem_result[23:16]}
                                 :{{24{mem_result[31]}},mem_result[31:24]}
                     :(inst_lbu)? (load_choice == 2'b00)?{24'b0,mem_result[7:0]}
                                 :(load_choice == 2'b01)?{24'b0,mem_result[15:8]}
                                 :(load_choice == 2'b10)?{24'b0,mem_result[23:16]}
                                 :{24'b0,mem_result[31:24]}
                     :(inst_lh)?  (load_choice == 2'b00)?{{16{mem_result[15]}},mem_result[15:0]}
                                 :{{16{mem_result[31]}},mem_result[31:16]}
                     :(inst_lhu)? (load_choice == 2'b00)?{16'b0,mem_result[15:0]}
                                 :{16'b0,mem_result[31:16]}
                     :(inst_lwl)? (load_choice == 2'b00)?{mem_result[7:0],ms_rt_value[23:0]}
                                 :(load_choice == 2'b01)?{mem_result[15:0],ms_rt_value[15:0]}
                                 :(load_choice == 2'b10)?{mem_result[23:0],ms_rt_value[7:0]}
                                 :mem_result
                     :(inst_lwr)? (load_choice == 2'b00)?mem_result
                                 :(load_choice == 2'b01)?{ms_rt_value[31:24],mem_result[31:8]}
                                 :(load_choice == 2'b10)?{ms_rt_value[31:16],mem_result[31:16]}
                                 :{ms_rt_value[31:8],mem_result[31:24]}
                     :mem_result;
                     
                     
assign ms_final_result = ms_res_from_mem ? MEM_result
                                         : ms_alu_result;

endmodule
