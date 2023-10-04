`timescale 1ns/1ns

module iic_top_tb();

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

wire                        w_iic_scl               ;
wire                        w_iic_sda               ;
wire [7:0]                  w_user_read_data        ;
wire                        w_user_read_sop         ;
wire                        w_user_read_eop         ;
wire                        w_user_read_valid       ;
wire                        w_user_operate_ready    ;

reg [2:0]                   i_drive                 ;
reg [15:0]                  i_operation_addr        ;
reg [7:0]                   i_operation_len         ;
reg [1:0]                   i_operation_type        ;
reg                         i_opeartion_valid       ;

reg [2:0]                   r_drive                 ;
reg [15:0]                  r_operation_addr        ;
reg [7:0]                   r_operation_len         ;
reg [1:0]                   r_operation_type        ;
wire                    w_act = i_opeartion_valid & w_user_operate_ready    ;
always@(posedge clk or posedge rst)
begin
    if (rst) begin
        r_drive          <= 'd0;
        r_operation_addr <= 'd0;
        r_operation_len  <= 'd0;
        r_operation_type <= 'd0;
    end else if (w_act) begin
        r_drive          <= i_drive         ;
        r_operation_addr <= i_operation_addr;
        r_operation_len  <= i_operation_len ;
        r_operation_type <= i_operation_type;
    end else begin
        r_drive          <= r_drive         ;
        r_operation_addr <= r_operation_addr;
        r_operation_len  <= r_operation_len ;
        r_operation_type <= r_operation_type;
    end
end
    

reg [7:0]                   i_user_write_data           ;
reg                         i_user_write_sop            ;
reg                         i_user_write_eop            ;
reg                         i_user_write_valid          ;

iic_top iic_top_u0(
    .i_clk                  (clk),
    .i_rst                  (rst),

    .i_user_device_addr     (i_drive          ),
    .i_user_operate_addr    (i_operation_addr ),
    .i_user_operate_len     (i_operation_len  ),
    .i_user_operate_type    (i_operation_type ),
    .i_user_operate_valid   (i_opeartion_valid),
    .o_user_operate_ready   (w_user_operate_ready),
    .i_user_write_data      (i_user_write_data ),
    .i_user_write_sop       (i_user_write_sop  ),
    .i_user_write_eop       (i_user_write_eop  ),
    .i_user_write_valid     (i_user_write_valid),
    .o_user_read_data       (w_user_read_data ), 
    .o_user_read_sop        (w_user_read_sop  ), 
    .o_user_read_eop        (w_user_read_eop  ), 
    .o_user_read_valid      (w_user_read_valid),

    .o_iic_scl              (w_iic_scl),
    .io_iic_sda             (w_iic_sda)
);

AT24C64 AT24C64_u0
(
    .SDA                        (w_iic_sda          ), 
    .SCL                        (w_iic_scl          ), 
    .WP                         (0                  )
);


task send_data();//˳��ִ��
begin
    i_drive           <= 3'b011;
    i_operation_addr  <= 16'h0000;
    i_operation_len   <= 4;
    i_operation_type  <= 1;
    i_opeartion_valid <= 1;
    @(posedge clk);
    i_drive           <= 0;
    i_operation_addr  <= 0;
    i_operation_len   <= 0;
    i_operation_type  <= 0;
    i_opeartion_valid <= 0;
    @(posedge clk);
    wait(w_user_operate_ready);
end
endtask

task rev_data();//˳��ִ��
begin
    i_drive           <= 3'b011;
    i_operation_addr  <= 16'h0000;
    i_operation_len   <= 4;
    i_operation_type  <= 2;
    i_opeartion_valid <= 1;
    @(posedge clk);
    i_drive           <= 0;
    i_operation_addr  <= 0;
    i_operation_len   <= 0;
    i_operation_type  <= 0;
    i_opeartion_valid <= 0;
    @(posedge clk);
    wait(w_user_operate_ready);
end
endtask


// i_user_write_data 
// i_user_write_sop  
// i_user_write_eop  
// i_user_write_valid

//  i_operation_len   
always@(posedge clk or posedge rst)
begin
    if (rst)
        i_user_write_sop <= 'd0;
    else if (w_act)
        i_user_write_sop <= 'd1;
    else
        i_user_write_sop <= 'd0;
end

always@(posedge clk or posedge rst)
begin
    if (rst)
        i_user_write_valid <= 'd0;
    else if (i_user_write_eop)
        i_user_write_valid <= 'd0;
    else if (w_act)
        i_user_write_valid <= 'd1;
    else 
        i_user_write_valid <= i_user_write_valid;
end

always@(posedge clk or posedge rst)
begin
    if (rst)
        i_user_write_data <= 'd0;
    else if (i_user_write_valid)
        i_user_write_data <= i_user_write_data + 1;
    else
        i_user_write_data <= i_user_write_data;
end

always@(posedge clk or posedge rst)
begin
    if (rst)
        i_user_write_eop <= 'd0;
    else if (r_write_cnt == r_operation_len - 2)
        i_user_write_eop <= 'd1;
    else 
        i_user_write_eop <= 'd0;
end

reg [15:0]              r_write_cnt                                         ;
always@(posedge clk or posedge rst)
begin
    if (rst)
        r_write_cnt <= 'd0;
    else if (r_write_cnt == r_operation_len - 1)
        r_write_cnt <= 'd0;
    else if (i_user_write_valid)  
        r_write_cnt <= r_write_cnt + 1;
    else
        r_write_cnt <= r_write_cnt;
end

pullup(w_iic_scl    );
pullup(w_iic_sda   );

initial
begin
    i_drive           = 0;
    i_operation_addr  = 0;
    i_operation_len   = 0;
    i_operation_type  = 0;
    i_opeartion_valid = 0;
    wait(!rst);
    repeat(10)@(posedge clk) ;
//    forever
//    begin
        send_data();
        rev_data();
        send_data();
        rev_data();
//        rev_data(2);
//        rev_data(3);
//        rev_data(4);
//        rev_data(5);
//        rev_data(6);
//        rev_data(7);
//    end
end






endmodule
