`ifndef MYCPU_H
    `define MYCPU_H

    
	`define BR_BUS_WD       34
    `define FS_TO_DS_BUS_WD 65
    //`define DS_TO_ES_BUS_WD 136
    `define DS_TO_ES_BUS_WD 172 
    //�޸�ԭ��lab6���andiָ��ʱ���zimm�ź�;div�źţ�mf��mt�ź�;load;store; mfc0,mtc0
    `define ES_TO_MS_BUS_WD 126
    //ԭ����71��������load_choice�޸�; mfc0,mtc0
    `define MS_TO_WS_BUS_WD 117
    `define WS_TO_RF_BUS_WD 38
    `define CR_BADVADDR     8
    `define CR_COUNT        9
    `define CR_COMPARE      11
    `define CR_STATUS       12
    `define CR_CAUSE        13
    `define CR_EPC          14
    //`define CR_BADVADDR     8
   // `define CR_COUNT        9
    //`define CR_COMPARE      11
   // `define CR_STATUS       12
    //`define CR_CAUSE        13
   // `define CR_EPC          14
    
`endif
