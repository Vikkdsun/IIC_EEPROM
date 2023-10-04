module iic_top(
    input                   i_clk               ,
    input                   i_rst               ,

    input [2:0]             i_user_device_addr  ,
    input [15:0]            i_user_operate_addr ,
    input [7:0]             i_user_operate_len  ,
    input [1:0]             i_user_operate_type ,
    input                   i_user_operate_valid,
    output                  o_user_operate_ready,
    input [7:0]             i_user_write_data   ,
    input                   i_user_write_sop    ,
    input                   i_user_write_eop    ,
    input                   i_user_write_valid  ,
    output [7:0]            o_user_read_data    , 
    output                  o_user_read_sop     , 
    output                  o_user_read_eop     , 
    output                  o_user_read_valid   ,

    output                  o_iic_scl           ,
    inout                   io_iic_sda           
);

wire [6:0]                   w_operation_device                              ;
wire [15:0]                  w_operation_addr                                ;
wire [7:0]                   w_operation_len                                 ;
wire [1:0]                   w_operation_type                                ;
wire                         w_opeartion_valid                               ;
wire                         w_operation_ready                               ;
wire [7:0]                   w_write_data                                    ;
wire                         w_write_req                                     ;
wire [7:0]                   w_read_data                                     ;
wire                         w_read_valid                                    ;


iic_drive iic_drive_u0(
    .i_clk                      (i_clk),
    .i_rst                      (i_rst),

    .i_operation_device         (w_operation_device),
    .i_operation_addr           (w_operation_addr  ),
    .i_operation_len            (w_operation_len   ),
    .i_operation_type           (w_operation_type  ),
    .i_opeartion_valid          (w_opeartion_valid ),
    .o_operation_ready          (w_operation_ready ),   // 1
    .i_write_data               (w_write_data      ),   
    .o_write_req                (w_write_req       ),   // 1
    .o_read_data                (w_read_data       ),   // 1
    .o_read_valid               (w_read_valid      ),   // 1


    .o_iic_scl                  (o_iic_scl ),   // 1
    .io_iic_sda                 (io_iic_sda)    // 1
);

eeprom_ctrl eeprom_ctrl_u0(
    .i_clk                      (i_clk),
    .i_rst                      (i_rst),  

    /*-------- IIC总线�? --------*/
    .o_operation_device         (w_operation_device), // 1
    .o_operation_addr           (w_operation_addr  ), // 1
    .o_operation_len            (w_operation_len   ), // 1
    .o_operation_type           (w_operation_type  ), // 1
    .o_opeartion_valid          (w_opeartion_valid ), // 1
    .i_operation_ready          (w_operation_ready ),   
    .o_write_data               (w_write_data      ), // 1
    .i_write_req                (w_write_req       ),   
    .i_read_data                (w_read_data       ),   
    .i_read_valid               (w_read_valid      ),   

    /*-------- 用户�? --------*/
    .i_user_device_addr         (i_user_device_addr  ),
    .i_user_operate_addr        (i_user_operate_addr ),
    .i_user_operate_len         (i_user_operate_len  ),
    .i_user_operate_type        (i_user_operate_type ),
    .i_user_operate_valid       (i_user_operate_valid),
    .o_user_operate_ready       (o_user_operate_ready),
    .i_user_write_data          (i_user_write_data   ),
    .i_user_write_sop           (i_user_write_sop    ),
    .i_user_write_eop           (i_user_write_eop    ),
    .i_user_write_valid         (i_user_write_valid  ),
    .o_user_read_data           (o_user_read_data    ), // 1
    .o_user_read_sop            (o_user_read_sop     ), // 1
    .o_user_read_eop            (o_user_read_eop     ), // 1
    .o_user_read_valid          (o_user_read_valid   )  // 1

);


endmodule
