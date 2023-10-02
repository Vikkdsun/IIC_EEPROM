`timescale 1ns/1ns

module iic_drive_tb();

reg clk,rst;

localparam P_CLK_PORIED = 10;

initial 
begin   
    rst = 1;
    #100;
    @(posedge clk)rst = 0;
end

always
begin
    clk = 0;
    #(P_CLK_PORIED/2);
    clk = 1;
    #(P_CLK_PORIED/2);
end

reg  [6 :0]       i_drive           ;
reg  [15:0]       i_operation_addr  ;
reg  [7 :0]       i_operation_len   ;
reg  [1 :0]       i_operation_type  ;
reg               i_opeartion_valid ;
wire              o_operation_ready ;
reg  [7 :0]       i_write_data      ;
wire              o_write_req       ;
wire [7 :0]       o_read_data       ;
wire              o_read_valid      ;
wire              o_iic_scl         ;
wire              io_iic_sda        ;

pullup(o_iic_scl    );
pullup(io_iic_sda   );

initial
begin
    i_drive           = 0;
    i_operation_addr  = 0;
    i_operation_len   = 0;
    i_operation_type  = 0;
    i_opeartion_valid = 0;
    i_write_data      = 0;
    wait(!rst);
    repeat(10)@(posedge clk) ;
//    forever
//    begin
        send_data();
        rev_data(0);
        rev_data(1);
//        rev_data(2);
//        rev_data(3);
//        rev_data(4);
//        rev_data(5);
//        rev_data(6);
//        rev_data(7);
//    end
end

 iic_drive#(
     .P_ADDR_WIDTH               (16)              
 )
 iic_drive_u0
 (             
     .i_clk                      (clk                ),//模块输入时钟
     .i_rst                      (rst                ),//模块输入复位-高有效

     /*--------用户接口--------*/
     .i_operation_device                    (i_drive            ),//用户输入设备地址
     .i_operation_addr           (i_operation_addr   ),//用户输入存储地址
     .i_operation_len            (i_operation_len    ),//用户输入读写长度
     .i_operation_type           (i_operation_type   ),//用户输入操作类型
     .i_opeartion_valid          (i_opeartion_valid  ),//用户输入有效信号
     .o_operation_ready          (o_operation_ready  ),//用户输出准备信号

     .i_write_data               (i_write_data       ),//用户输入写数据
     .o_write_req                (o_write_req        ),//用户写数据请求信号
     .o_read_data                (o_read_data        ),//输出IIC读到的数据
     .o_read_valid               (o_read_valid       ),//输出IIC读数据有效

     /*--------IIC接口--------*/
     .o_iic_scl                  (o_iic_scl          ),//IIC的时钟
     .io_iic_sda                 (io_iic_sda         ) //IIC的双向数据项
 );

//XC7Z010_TOP XC7Z010_TOP_u0(
//    .i_clk           (clk)           ,
//    .o_iic_scl       (o_iic_scl)           ,//IIC的时钟
//    .io_iic_sda      (io_iic_sda)            //IIC的双向数据项   
//);  

AT24C64 AT24C64_u0
(
    .SDA                        (io_iic_sda         ), 
    .SCL                        (o_iic_scl          ), 
    .WP                         (0                  )
);

task send_data();//顺序执行
begin
    i_drive           <= 7'b0000_011;
    i_operation_addr  <= 16'h0000;
    i_operation_len   <= 2;
    i_operation_type  <= 1;
    i_opeartion_valid <= 1;
    @(posedge clk);
    wait(!o_operation_ready);
    i_drive           <= 0;
    i_operation_addr  <= 0;
    i_operation_len   <= 0;
    i_operation_type  <= 0;
    i_opeartion_valid <= 0;
    @(posedge clk);
    wait(o_operation_ready);
end
endtask

task rev_data(input [15:0] addr);//顺序执行
begin
    i_drive           <= 7'b0000_011;
    i_operation_addr  <= addr;
    i_operation_len   <= 1;
    i_operation_type  <= 2;
    i_opeartion_valid <= 1;
    @(posedge clk);
    wait(!o_operation_ready);
    i_drive           <= 0;
    i_operation_addr  <= 0;
    i_operation_len   <= 0;
    i_operation_type  <= 0;
    i_opeartion_valid <= 0;
    @(posedge clk);
    wait(o_operation_ready);
end
endtask


always@(posedge clk,posedge rst)
begin
    if(rst)
        i_write_data <= 'd0;
    else if(o_write_req)
        i_write_data <= 8'haa;
    else 
        i_write_data <= i_write_data;
end

endmodule
