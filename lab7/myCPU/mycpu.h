`ifndef MYCPU_H
    `define MYCPU_H

    //`define BR_BUS_WD       32  ����1��
	`define BR_BUS_WD       33
    `define FS_TO_DS_BUS_WD 64
    //`define DS_TO_ES_BUS_WD 136
    `define DS_TO_ES_BUS_WD 157 
    //�޸�ԭ��lab6���andiָ��ʱ���zimm�ź�;div�źţ�mf��mt�ź�;load;store
    `define ES_TO_MS_BUS_WD 111
    //ԭ����71��������load_choice�޸�
    `define MS_TO_WS_BUS_WD 70
    `define WS_TO_RF_BUS_WD 38
`endif
