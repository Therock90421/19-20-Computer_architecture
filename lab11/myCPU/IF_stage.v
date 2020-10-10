`include "mycpu.h"

module if_stage(
    input                          clk            ,
    input                          reset          ,
    //allwoin
    input                          ds_allowin     ,            //ds_allowin��������������ID
    //brbus
    input  [`BR_BUS_WD       -1:0] br_bus         ,
    //to ds
    output                         fs_to_ds_valid ,            //��IF��������ID��Ч
    output [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus   ,            //IF��ID����
    // inst sram interface
    output      inst_req   ,
    output [ 3:0] inst_sram_wen  ,
    output [31:0] inst_sram_addr ,
    output [31:0] inst_sram_wdata,
    input  [31:0] inst_sram_rdata,
    input  [33   :0]                ws_to_fs_bus,
    
    input  inst_data_ok,
    input  inst_addr_ok
);
/////////////////////////////////////ȡֵ��û��д���⴦��
reg         fs_valid;
wire        fs_ready_go;
wire        fs_allowin;
wire        to_fs_valid;

wire inst_sram_en;

wire [31:0] seq_pc;
wire [31:0] nextpc;

wire         br_taken;                                          //��ID�д�������pc�Ƿ���ת
wire [ 31:0] br_target;
wire         fs_bd;
assign {fs_bd,br_taken,br_target} = br_bus;

wire [31:0] fs_inst;                                            //ȡֵ�Ĵ���
reg  [31:0] fs_pc;                                              //pc������
wire [31:0] badvaddr;
wire fs_ex;
assign fs_to_ds_bus = {
                       fs_ex,   //97
                       badvaddr,//96:65
                       fs_bd,   //64
                       fs_inst ,//63:32
                       fs_pc   };   
wire ft_address_error;
wire wb_ex;
//assign ft_address_error = ~(nextpc[1:0] == 2'b00); //����bug
assign ft_address_error = ~(fs_pc[1:0] == 2'b00); 
assign fs_ex = ft_address_error && fs_valid && ~wb_ex; //��wb_ex�ź�Ϊ�������ˮ��
assign badvaddr = (fs_ex)? fs_pc
                   : 32'h0;
////////////////////////////////////

wire inst_eret;
wire [31:0] cp0_rdata;
assign {
        wb_ex,
        inst_eret,
        cp0_rdata
} = ws_to_fs_bus;                            
//////////////////////////////////
// pre-IF stage
reg inst_addr_arrived;
always @(posedge clk) begin
    if(reset)
        inst_addr_arrived<=0;
    else if(fs_to_ds_valid)
        inst_addr_arrived<=0;
    else if(inst_addr_ok)
        inst_addr_arrived<=1;
end

assign inst_req     = ~reset && ~inst_addr_arrived;
assign to_fs_valid  = ~reset && (inst_addr_ok&inst_req);                                    //pc��д��
assign seq_pc       = fs_pc + 3'h4;                             //pc+4
///////////////////////////////////
assign nextpc       =  wb_ex? 32'hbfc00380 :
                        inst_eret? cp0_rdata :
                        br_taken ? br_target : seq_pc; 
///////////////////////////////////                        
// IF stage
assign fs_ready_go    = inst_data_ok;
assign fs_allowin     = !fs_valid || fs_ready_go && ds_allowin; //fs���Է�����ds������룬����һ��fs�����ݾͽ�����  ��  fs��������Ч
assign fs_to_ds_valid =  fs_valid && fs_ready_go;               //fs��������Ч��fs���Է���
always @(posedge clk) begin
    if (reset) begin                                           //
        fs_valid <= 1'b0;                                     //reset�ڼ�fs_valid��ֵΪ0
    end
    else if (fs_allowin) begin
        fs_valid <= to_fs_valid;                              //���fs�������
    end

    if (reset) begin
        fs_pc <= 32'hbfbffffc;  //trick: to make nextpc be 0xbfc00000 during reset 
    end
    else if (to_fs_valid && fs_allowin) begin                   //����ʱ��pcΪ32'hbfbffffc��nextpcΪbfc00000����ʱ�����ram����һ�Ĺ���pc������bfc00000����ʱinst_sram_rdataΪbfc00000��Ӧ��ָ��
        fs_pc <= nextpc;
    end
end

assign inst_sram_en    = to_fs_valid && fs_allowin;
assign inst_sram_wen   = 4'h0;
assign inst_sram_addr  = nextpc;
assign inst_sram_wdata = 32'b0;


assign fs_inst         =  (~wb_ex & ~fs_ex & ~inst_eret )? inst_sram_rdata : 32'b0;   //������Ϊbug
/////���������eret�Ĵ������޸�fs_pc��ֵ�����ǽ�fs_instָ���Ϊ0���Ϳ����������Ч��
endmodule
