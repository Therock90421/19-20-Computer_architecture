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
    output        inst_sram_en   ,
    output [ 3:0] inst_sram_wen  ,
    output [31:0] inst_sram_addr ,
    output [31:0] inst_sram_wdata,
    input  [31:0] inst_sram_rdata
);

reg         fs_valid;
wire        fs_ready_go;
wire        fs_allowin;
wire        to_fs_valid;

wire [31:0] seq_pc;
wire [31:0] nextpc;

wire         br_taken;                                          //��ID�д�������pc�Ƿ���ת
wire [ 31:0] br_target;
assign {br_taken,br_target} = br_bus;

wire [31:0] fs_inst;                                            //ȡֵ�Ĵ���
reg  [31:0] fs_pc;                                              //pc������
assign fs_to_ds_bus = {fs_inst ,
                       fs_pc   };                               

// pre-IF stage
assign to_fs_valid  = ~reset;                                    //pc��д��
assign seq_pc       = fs_pc + 3'h4;                             //pc+4
//assign nextpc       = br_taken ? br_target : seq_pc;            //����2
assign nextpc       = (fs_pc == 32'hbfbffffc)?seq_pc:br_taken ? br_target : seq_pc; 
// IF stage
assign fs_ready_go    = 1'b1;
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

assign fs_inst         = inst_sram_rdata;

endmodule
