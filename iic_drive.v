module iic_drive(
    input                   i_clk,
    input                   i_rst,

    input [6:0]             i_operation_device  ,
    input [15:0]            i_operation_addr    ,
    input [7:0]             i_operation_len     ,
    input [1:0]             i_operation_type    ,
    input                   i_opeartion_valid   ,
    output                  o_operation_ready   ,   // 1



    input [7:0]             i_write_data        ,   
    output                  o_write_req         ,   // 1

    output [7:0]            o_read_data         ,   // 
    output                  o_read_valid        ,   // 


    output                  o_iic_scl           ,   // 1
    inout                   io_iic_sda              // 1
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

// ????
wire                        w_operation_active                                              ;
assign                      w_operation_active = o_operation_ready & i_opeartion_valid      ; 

localparam                  P_TYPE_W        =   1                                           ,
                            P_TYPE_R        =   2                                           ;

// ??????????
reg [7:0]                   r_st_current                                                    ;
reg [7:0]                   r_st_next                                                       ;

localparam                  P_ST_IDLE       =   0                                           ,
                            P_ST_START      =   1                                           ,
                            P_ST_DEVICE     =   2                                           ,
                            P_ST_ADDR1      =   3                                           ,
                            P_ST_ADDR2      =   4                                           ,
                            P_ST_WRITE      =   5                                           ,
                            P_ST_READ       =   6                                           ,
                            P_ST_WAIT       =   7                                           ,
                            P_ST_EMPTY      =   8                                           ,
                            P_ST_STOP       =   9                                           ;
reg [7:0]                   r_st_cnt                                                        ;

reg                         ro_iic_scl                                                      ;
assign                      o_iic_scl = ro_iic_scl                                          ;

reg                         r_scl_st                                                        ;
reg                         r_st_restart                                                    ;

reg [6:0]                   ri_operation_device                                             ;
reg [15:0]                  ri_operation_addr                                               ;
reg [7:0]                   ri_operation_len                                                ;
reg [1:0]                   ri_operation_type                                               ;

reg                         ro_iic_sda                                                      ;
reg                         r_iic_sda_ctrl                                                  ;
wire                        w_iic_sda                                                       ;
assign                      io_iic_sda = r_iic_sda_ctrl ? ro_iic_sda : 1'bz                 ;
assign                      w_iic_sda = !r_iic_sda_ctrl ? io_iic_sda : 1'b0                 ;            

reg                         r_iic_sda_1d                                                    ;
reg                         r_w_cnt                                                         ;
reg                         r_no_ack                                                        ;

reg [7:0]                   ri_write_data                                                   ;
reg                         ro_write_req                                                    ;
assign                      o_write_req = ro_write_req                                      ;
reg                         ro_write_req_1d                                                 ;
reg                     ro_operation_ready                                                  ;
assign                  o_operation_ready = ro_operation_ready                              ;

reg [7:0]               ro_read_data                                                        ;
reg                     ro_read_valid                                                       ;
assign                  o_read_data  = ro_read_data                                         ;
assign                  o_read_valid = ro_read_valid                                        ;


// ?????
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_st_current <= P_ST_IDLE;
    else
        r_st_current <= r_st_next;
end

// ?????
always@(*)
begin
    case(r_st_current)
        P_ST_IDLE   :   r_st_next = w_operation_active              ?   P_ST_START      :   P_ST_IDLE       ;
        P_ST_START  :   r_st_next = P_ST_DEVICE                     ;
        P_ST_DEVICE :   r_st_next = r_st_cnt == 9 & !r_scl_st       ?   r_st_restart    ?   P_ST_READ       :   P_ST_ADDR1  :   P_ST_DEVICE ;
        P_ST_ADDR1  :   r_st_next = r_iic_sda_1d                    ?   P_ST_EMPTY      :  r_st_cnt == 9 && !r_scl_st       ?   P_ST_ADDR2  :   P_ST_ADDR1;
        P_ST_ADDR2  :   r_st_next = r_st_cnt == 9 & !r_scl_st       ?   ri_operation_type == P_TYPE_W       ?   P_ST_WRITE  :   P_ST_WAIT   :   P_ST_ADDR2;
        P_ST_WRITE  :   r_st_next = r_st_cnt == 9 & !r_scl_st       ?   r_w_cnt == ri_operation_len - 1     ?   P_ST_WAIT   :   P_ST_WRITE  :   P_ST_WRITE;
        P_ST_READ   :   r_st_next = r_st_cnt == 9 & !r_scl_st       ?   P_ST_WAIT       :   P_ST_READ       ;
        P_ST_WAIT   :   r_st_next = P_ST_EMPTY;
        P_ST_EMPTY  :   r_st_next = P_ST_STOP;
        P_ST_STOP   :   r_st_next = r_no_ack | r_st_restart         ?   P_ST_START      :   P_ST_IDLE       ;
        default     :   r_st_next = P_ST_IDLE;
    endcase
end
// ?????????

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_st_cnt <= 'd0;
    else if (r_st_current != r_st_next || r_st_current <= P_ST_START || r_st_current >= P_ST_STOP || (r_st_cnt == 9 && !r_scl_st))
        r_st_cnt <= 'd0;
    else if (r_scl_st)
        r_st_cnt <= r_st_cnt + 1;
    else
        r_st_cnt <= r_st_cnt;
end

// ???
// o_iic_scl

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_iic_scl <= 'd1;
    else if (r_st_current == P_ST_EMPTY || r_st_current == P_ST_STOP || r_st_current == P_ST_IDLE || r_st_current == P_ST_START)
        ro_iic_scl <= 'd1;
    else if (r_st_current >= P_ST_DEVICE && r_st_current <= P_ST_WAIT)
        ro_iic_scl <= ~ro_iic_scl;
    else        
        ro_iic_scl <= ro_iic_scl;
end 


always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_scl_st <= 'd1;
    else if (r_st_current == P_ST_EMPTY || r_st_current == P_ST_STOP || r_st_current == P_ST_IDLE || r_st_current == P_ST_START)
        r_scl_st <= 'd1;
    else if (r_st_current >= P_ST_DEVICE && r_st_current <= P_ST_WAIT)
        r_scl_st <= ~r_scl_st;
    else        
        r_scl_st <= r_scl_st;
end 

// restart

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_st_restart <= 'd0;
    else if (ri_operation_type == P_TYPE_R && r_st_current == P_ST_DEVICE && r_st_next != P_ST_DEVICE)
        r_st_restart <= 'd0;
    else if (ri_operation_type == P_TYPE_R && r_st_current == P_ST_ADDR2 && r_st_next == P_ST_WAIT)
        r_st_restart <= 'd1;
    else
        r_st_restart <= r_st_restart;
end

// ????


always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst) begin
        ri_operation_device <= 'd0;
        ri_operation_addr   <= 'd0;
        ri_operation_len    <= 'd0;
        ri_operation_type   <= 'd0;
    end else if (w_operation_active) begin
        ri_operation_device <= i_operation_device;
        ri_operation_addr   <= i_operation_addr  ;
        ri_operation_len    <= i_operation_len   ;
        ri_operation_type   <= i_operation_type  ;
    end else begin
        ri_operation_device <= ri_operation_device;
        ri_operation_addr   <= ri_operation_addr  ;
        ri_operation_len    <= ri_operation_len   ;
        ri_operation_type   <= ri_operation_type  ;
    end
end

// ???????


always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_iic_sda_ctrl <= 'd1;
    else if (r_st_cnt == 8 && r_scl_st)
        r_iic_sda_ctrl <= 'd0;
    else if (r_st_next == P_ST_IDLE)
        r_iic_sda_ctrl <= 'd1;
    else if (r_st_current == P_ST_READ)
        r_iic_sda_ctrl <= 'd0;
//    else if (r_st_current == P_ST_WAIT)
//        r_iic_sda_ctrl <= 'd0;
    else if (r_st_cnt == 0)
        r_iic_sda_ctrl <= 'd1;
    else
        r_iic_sda_ctrl <= r_iic_sda_ctrl;
end

//always@(posedge i_clk,posedge i_rst)
//begin
//    if(i_rst)
//        r_iic_sda_ctrl <= 'd0;
//    else if(r_st_cnt == 8 && r_scl_st || r_st_next == P_ST_IDLE)
//        r_iic_sda_ctrl <= 'd0;
//    else if(r_st_current >= P_ST_START && r_st_current <= P_ST_WRITE || r_st_current == P_ST_STOP)
//        r_iic_sda_ctrl <= 'd1;
//    else
//        r_iic_sda_ctrl <= r_iic_sda_ctrl;
//end

// ????w_sda ??????????? ?????????????????

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_iic_sda_1d <= 'd0;
    else
        r_iic_sda_1d <= w_iic_sda;
end

// ?????????????

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_w_cnt <= 'd0;
    else if (ri_operation_type == P_TYPE_W && r_st_current == P_ST_WRITE && r_st_cnt == 9 && !r_scl_st)
        r_w_cnt <= r_w_cnt + 1;
    else if (r_st_current != P_ST_WRITE)
        r_w_cnt <= 'd0;
    else
        r_w_cnt <= r_w_cnt;
end

// ???????????stop ?????no ack?????restart stop??start ??????IDLE

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_no_ack <= 'd0;
    else if (r_st_current == P_ST_ADDR1 && r_st_next == P_ST_ADDR1)
        r_no_ack <= 'd0;
    else if (r_st_current == P_ST_ADDR1 && r_st_next == P_ST_EMPTY)
        r_no_ack <= 'd1;
    else
        r_no_ack <= r_no_ack;
end

// ?????? ro_iic_sda
// P_ST_IDLE  
// P_ST_START 
// P_ST_DEVICE
// P_ST_ADDR1 
// P_ST_ADDR2 
// P_ST_WRITE 
// P_ST_READ  
// P_ST_STOP  

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_iic_sda <= 'd1;
    else if (r_st_current == P_ST_START)
        ro_iic_sda <= 'd0;
    else if (r_st_current == P_ST_DEVICE && r_scl_st && r_st_cnt == 7)
        ro_iic_sda <= r_st_restart ?    1'b1   :   1'b0;
    else if (r_st_current == P_ST_DEVICE && r_scl_st)
        ro_iic_sda <= ri_operation_device[6 - r_st_cnt];
    else if (r_st_current == P_ST_ADDR1 && r_scl_st)
        ro_iic_sda <= ri_operation_addr[15 - r_st_cnt];
    else if (r_st_current == P_ST_ADDR2 && r_scl_st)
        ro_iic_sda <= ri_operation_addr[7 - r_st_cnt];
    else if (r_st_current == P_ST_WRITE && r_scl_st)
        ro_iic_sda <= ri_write_data[7 - r_st_cnt];
    else if (r_st_current == P_ST_WAIT || r_st_current == P_ST_EMPTY)
        ro_iic_sda <= 'd0;
    else if (r_st_current == P_ST_STOP)
        ro_iic_sda <= 'd1;
    else 
        ro_iic_sda <= ro_iic_sda;
end

// ??????????

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_write_req <= 'd0;
    else if (r_st_current == P_ST_ADDR2 && r_st_cnt == 8 && !r_scl_st && ri_operation_type == P_TYPE_W)
        ro_write_req <= 'd1;
    else if (r_st_current == P_ST_WRITE && r_st_cnt == 8 && !r_scl_st && r_w_cnt < ri_operation_len - 1)
        ro_write_req <= 'd1;
    else
        ro_write_req <= 'd0;
end


always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_write_req_1d <= 'd0;
    else
        ro_write_req_1d <= ro_write_req;
end

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ri_write_data <= 'd0;
    else if (ro_write_req_1d)
        ri_write_data <= i_write_data;
    else
        ri_write_data <= ri_write_data;
end

// ???????

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_operation_ready <= 'd1;
    else if (r_st_current ==P_ST_IDLE)
        ro_operation_ready <= 'd1;
    else if (w_operation_active)
        ro_operation_ready <= 'd0;
    else
        ro_operation_ready <= ro_operation_ready;
end

// read
// o_read_data 
// o_read_valid

always@(posedge o_iic_scl or posedge i_rst)
begin
    if (i_rst)
        ro_read_data <= 'd0;
    else if (r_st_current == P_ST_READ)  
        ro_read_data <= {ro_read_data[6:0], w_iic_sda};
    else
        ro_read_data <= ro_read_data;
end

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_read_valid <= 'd0;
    else if (r_st_current == P_ST_READ && r_st_cnt == 9 && !r_scl_st)
        ro_read_valid <= 'd1;
    else
        ro_read_valid <= 'd0;
end






endmodule
