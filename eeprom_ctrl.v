// �?个eeprom的控制模�?
/*
    模块主要联系用户和�?�线，包含写和读的两个方面�??
*/

module eeprom_ctrl(
    input                   i_clk               ,
    input                   i_rst               ,

    /*-------- IIC总线�? --------*/
    output [6:0]            o_operation_device  , // 1
    output [15:0]           o_operation_addr    , // 1
    output [7:0]            o_operation_len     , // 1
    output [1:0]            o_operation_type    , // 1
    output                  o_opeartion_valid   , // 1
    input                   i_operation_ready   ,   

    output [7:0]            o_write_data        , // 1
    input                   i_write_req         ,   

    input [7:0]             i_read_data         ,   
    input                   i_read_valid        ,   

    /*-------- 用户�? --------*/
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

    output [7:0]            o_user_read_data    , // 1
    output                  o_user_read_sop     , // 1
    output                  o_user_read_eop     , // 1
    output                  o_user_read_valid     // 1

);
/*
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)

    else if ()

    else if ()

    else

end
*/
// 把给IIC的输出绑定寄存器
reg [6:0]                   ro_operation_device                                                                 ;
reg [15:0]                  ro_operation_addr                                                                   ;
reg [7:0]                   ro_operation_len                                                                    ;
reg [1:0]                   ro_operation_type                                                                   ; 
reg                         ro_opeartion_valid                                                                  ;

assign                      o_operation_device = ro_operation_device                                            ;
assign                      o_operation_addr   = ro_operation_addr                                              ;
assign                      o_operation_len    = ro_operation_len                                               ;
assign                      o_operation_type   = ro_operation_type                                              ;
assign                      o_opeartion_valid  = ro_opeartion_valid                                             ;

// 把用户输入进来的数据锁存
reg [2:0]                   ri_user_device_addr                                                                 ;
reg [15:0]                  ri_user_operate_addr                                                                ;
reg [7:0]                   ri_user_operate_len                                                                 ;
reg [1:0]                   ri_user_operate_type                                                                ;

// 和用户握�?
wire                        w_user_operate_active                                                               ;
assign                      w_user_operate_active = i_user_operate_valid & o_user_operate_ready                 ;
// 使用FIFO保存用户输入的数据，IIC总线发�?�req，表示从FIFO读要写的数据
// 使用FIFO保存总线读到的数据，read_valid时把读到的数据写入FIFO
// 因为EEPROM和IIC读操作是随机读，�?以当用户想读多个数据时，这里有一个状态机的内�?
reg [7:0]                   ri_user_write_data                                                              ;
reg                         ri_user_write_valid                                                             ;

// 和IIC握手
wire                        w_iic_active                                                                        ;
assign                      w_iic_active = o_opeartion_valid & i_operation_ready                                ;

// �?要一个读计数器判断读了多少个
reg [15:0]                  r_read_cnt                                                                          ;
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst) begin
        ri_user_write_data  <= 'd0;
        ri_user_write_valid <= 'd0;
    end else begin
        ri_user_write_data  <= i_user_write_data ;
        ri_user_write_valid <= i_user_write_valid;
    end
end

FIFO_WRITE FIFO_WRITE_U0 (
  .clk      (i_clk),      
  .srst     (i_rst),    
  .din      (ri_user_write_data),      
  .wr_en    (ri_user_write_valid),  
  .rd_en    (i_write_req),  
  .dout     (o_write_data),    
  .full     (       ),    
  .empty    (      )  
);

reg [7:0]                   ri_read_data                                                                    ;
reg                         ri_read_valid                                                                   ;

wire [7:0]                  w_read_fifo_data                                                                ;
wire                        w_read_fifo_empty                                                                   ;
reg                         r_read_fifo_rden                                                                    ;

// �?要iic_ready上升�?
reg                         r_iic_ready_1d                                                                       ;
wire                        w_iic_ready_pos                                                                      ;
assign                      w_iic_ready_pos = !r_iic_ready_1d & i_operation_ready                                ;
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst) begin
        ri_read_data  <= 'd0;
        ri_read_valid <= 'd0;
    end else begin
        ri_read_data  <= i_read_data ;
        ri_read_valid <= i_read_valid;
    end
end

FIFO_READ FIFO_READ_U0 (
  .clk      (i_clk),  
  .srst     (i_rst),  
  .din      (ri_read_data),  
  .wr_en    (ri_read_valid),  
  .rd_en    (r_read_fifo_rden),  
  .dout     (w_read_fifo_data),  
  .full     (       ),  
  .empty    (w_read_fifo_empty)  
);
reg [7:0]                   r_st_current                                                                        ;
reg [7:0]                   r_st_next                                                                           ;

localparam                  P_ST_IDLE   =   0                                                                   ,
                            P_ST_RUN    =   1                                                                   ,
                            P_ST_WRITE  =   2                                                                   ,
                            P_ST_READ   =   3                                                                   ,
                            P_ST_REREAD =   4                                                                   ,
                            P_ST_OREAD  =   5                                                                   ;
                            
// 握手后用户给的数据锁�?
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst) begin
        ri_user_device_addr  <= 'd0;
        ri_user_operate_addr <= 'd0;
        ri_user_operate_len  <= 'd0;
        ri_user_operate_type <= 'd0;
    end else if (w_user_operate_active) begin
        ri_user_device_addr  <= i_user_device_addr ;
        ri_user_operate_addr <= i_user_operate_addr;
        ri_user_operate_len  <= i_user_operate_len ;
        ri_user_operate_type <= i_user_operate_type;
    end else begin
        ri_user_device_addr  <= ri_user_device_addr ;
        ri_user_operate_addr <= ri_user_operate_addr;
        ri_user_operate_len  <= ri_user_operate_len ;
        ri_user_operate_type <= ri_user_operate_type;
    end
end

reg [15:0]                              r_read_addr         ;

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_read_addr <= 'd0;
    else if (w_user_operate_active)
        r_read_addr <= i_user_operate_addr + 1;
    else if (r_st_current == P_ST_REREAD && r_st_next == P_ST_READ)
        r_read_addr <= r_read_addr + 1;
    else
        r_read_addr <= r_read_addr;
end
        
        
        
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_st_current <= P_ST_IDLE;
    else
        r_st_current <= r_st_next;
end

always@(*)
begin
    case(r_st_current)
        P_ST_IDLE   :   r_st_next = w_user_operate_active       ?       P_ST_RUN        :       P_ST_IDLE       ;
        P_ST_RUN    :   r_st_next = w_iic_active                ?       ri_user_operate_type == 1               ?       P_ST_WRITE      :       P_ST_READ       :       P_ST_RUN    ;
        P_ST_WRITE  :   r_st_next = w_iic_ready_pos             ?       P_ST_IDLE       :       P_ST_WRITE      ;
        P_ST_READ   :   r_st_next = w_iic_ready_pos             ?       r_read_cnt == ri_user_operate_len - 1      ?       P_ST_OREAD     :       P_ST_REREAD       :       P_ST_READ   ;
        P_ST_REREAD :   r_st_next = P_ST_READ                   ;
        P_ST_OREAD  :   r_st_next = w_read_fifo_empty           ?       P_ST_IDLE       :       P_ST_OREAD      ;
        default     :   r_st_next = P_ST_IDLE                   ;
    endcase
end


always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_read_cnt <= 'd0;
    else if (r_st_current == P_ST_IDLE)
        r_read_cnt <= 'd0;
    else if (ri_user_operate_type == 2 && r_st_current == P_ST_READ && w_iic_ready_pos)
        r_read_cnt <= r_read_cnt + 1;
    else
        r_read_cnt <= r_read_cnt;
end


always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_iic_ready_1d <= 'd1;
    else
        r_iic_ready_1d <= i_operation_ready;
end

// o_operation_device
// o_operation_addr  
// o_operation_len   
// o_operation_type  
// o_opeartion_valid 
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst) begin
        ro_operation_device <= 'd0;
        ro_operation_addr   <= 'd0;
        ro_operation_len    <= 'd0;
        ro_operation_type   <= 'd0;
        ro_opeartion_valid  <= 'd0;
    end else if (w_user_operate_active) begin
        ro_operation_device <= {4'b0000, i_user_device_addr} ;
        ro_operation_addr   <= i_user_operate_addr;
        ro_operation_len    <= i_user_operate_len ;
        ro_operation_type   <= i_user_operate_type;
        ro_opeartion_valid  <= 'd1;
    end else if (w_iic_active) begin
        ro_operation_device <= {4'b0000, i_user_device_addr} ;
        ro_operation_addr   <= i_user_operate_addr;
        ro_operation_len    <= i_user_operate_len ;
        ro_operation_type   <= i_user_operate_type;
        ro_opeartion_valid  <= 'd0;
    end else if (r_st_current == P_ST_REREAD && r_st_next == P_ST_READ) begin
        ro_operation_device <= {4'b0000, ri_user_device_addr} ;
        ro_operation_addr   <= r_read_addr;
        ro_operation_len    <= ri_user_operate_len ;
        ro_operation_type   <= ri_user_operate_type;
        ro_opeartion_valid  <= 'd1;
    end else begin
        ro_operation_device <= ro_operation_device;
        ro_operation_addr   <= ro_operation_addr  ;
        ro_operation_len    <= ro_operation_len   ;
        ro_operation_type   <= ro_operation_type  ;
        ro_opeartion_valid  <= ro_opeartion_valid ;
    end
end



reg                         ro_user_operate_ready                                                               ;
assign                      o_user_operate_ready = ro_user_operate_ready                                        ;
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_operate_ready <= 'd1;
    else if (w_user_operate_active)
        ro_user_operate_ready <= 'd0;
    else if (r_st_current == P_ST_IDLE)
        ro_user_operate_ready <= 'd1;
    else
        ro_user_operate_ready <= ro_user_operate_ready;
end

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_read_fifo_rden <= 'd0;
    else if (w_read_fifo_empty)  
        r_read_fifo_rden <= 'd0;
    else if (r_st_current == P_ST_OREAD)
        r_read_fifo_rden <= 'd1;
    else
        r_read_fifo_rden <= r_read_fifo_rden;
end

reg [7:0]                   ro_user_read_data                                                                   ;
reg                         ro_user_read_sop                                                                    ;
reg                         ro_user_read_eop                                                                    ;
reg                         ro_user_read_valid                                                                  ;
assign                      o_user_read_data = ro_user_read_data                                                ;
assign                      o_user_read_sop  = ro_user_read_sop                                                 ;
assign                      o_user_read_eop  = ro_user_read_eop                                                 ;
assign                      o_user_read_valid= ro_user_read_valid                                               ;

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_read_data <= 'd0;
    else
        ro_user_read_data <= w_read_fifo_data;                                                                  ;
end

reg                         r_fifo_read_rden_1d                                                                 ;
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_fifo_read_rden_1d <= 'd0;
    else
        r_fifo_read_rden_1d <= r_read_fifo_rden;
end

wire                        w_fifo_read_rden_pos                                                                ;
assign                      w_fifo_read_rden_pos = !r_fifo_read_rden_1d & r_read_fifo_rden                      ;

reg                         r_read_sop_valid                                                                    ;

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_read_sop_valid <= 'd0;
    else
        r_read_sop_valid <= w_fifo_read_rden_pos;
end 

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_read_sop <= 'd0;
    else if (r_read_sop_valid)
        ro_user_read_sop <= 'd1;
    else
        ro_user_read_sop <= 'd0;
end

reg                         r_read_fifo_empty_1d                                                                ;
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_read_fifo_empty_1d <= 'd1;
    else
        r_read_fifo_empty_1d <= w_read_fifo_empty;
end

wire                        w_read_fifo_empty_pos                                                               ;
assign                      w_read_fifo_empty_pos = !r_read_fifo_empty_1d & w_read_fifo_empty                   ;

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_read_eop <= 'd0;
    else if (w_read_fifo_empty_pos)
        ro_user_read_eop <= 'd1;
    else
        ro_user_read_eop <= 'd0;
end

reg                         w_read_fifo_empty_pos_1d                                                                ;
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        w_read_fifo_empty_pos_1d <= 'd0;
    else
        w_read_fifo_empty_pos_1d <= w_read_fifo_empty_pos;
end

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)  
        ro_user_read_valid <= 'd0;
    else if (w_read_fifo_empty_pos_1d)
        ro_user_read_valid <= 'd0;
    else if (r_read_sop_valid)      
        ro_user_read_valid <= 'd1;
    else    
        ro_user_read_valid <= ro_user_read_valid;
end




// 和用户握手后 就可以开启控�? 进�?�开启�?�线
// 这里用一下状态机


endmodule
