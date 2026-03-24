module fifo_assertions #(
    WIDTH,
    ADDR
)(
    clk,
    rstn,
    read,
    write,
    data_in,
    data_out,
    full,
    empty,
    count,
    rdp,
    wrp
);
    input clk;                                                   
    input rstn;                     
    input read;                     
    input write;                     
    input [WIDTH-1:0] data_in;                    
    input [WIDTH-1:0] data_out;                   
    input full;
    input empty;  
    input [ADDR:0] count;
    input [ADDR-1:0] rdp, wrp; 
    
    localparam DEPTH = 2**ADDR;
      
    // Assertions -------------------------------------------------------------------------------
    
    // reset property
    property reset;
        @(posedge clk)
            !rstn |=> (!data_out && !full && empty);
    endproperty 

    // full check 
    property full_check;
        @(posedge clk)
            (count == DEPTH && !empty) |-> full;
    endproperty

    // empty check 
    property empty_check;
        @(posedge clk)
            (count == 0 && !full) |-> empty;
    endproperty

    // read rule check
    property read_check;    
        @(posedge clk)
            disable iff(!rstn)
                read 
                |=>(
                    if(!$past(empty))  
                        (rdp != $past(rdp))
                    else 
                        ($stable(rdp))
                );

                // read |=> !full;
    endproperty 

    // write rule check 
    property write_check;    
        @(posedge clk)
            disable iff(!rstn) 
            write 
            |=>(
                if(!$past(full))
                    (wrp != $past(wrp))
                else 
                    ($stable(wrp))
            );               
    endproperty 

    // no full and empty
    property no_full_no_empty;    
        @(posedge clk)
            disable iff(!rstn)
                ((full |-> !empty) or (empty |-> !full)); 
    endproperty 

    // Full de-assert after read
    property full_deassert;    
        @(posedge clk)
            disable iff(!rstn)
                (full && read && !write) |=> !full;
    endproperty

    // count correctness ------------------------------------------------------------ 
    // simultaneous read - write
    property r_w;    
        @(posedge clk)
            disable iff(!rstn)
                (read && write && !full && !empty) |=> count == $past(count);
    endproperty

    // if read decrement count
    property count_dec;
        @(posedge clk)
        disable iff(!rstn)
        (read && !empty && !write) |=> count == $past(count) - 1;
    endproperty


    // if write increment count
    property count_inc;
        @(posedge clk)
            disable iff(!rstn)
                (write && !full && !read) |=> count == $past(count) + 1;
    endproperty
        
    RESET : assert property(reset)
                $display("------RESET------: PASS");
            else
                $display("------RESET------: FAIL");

    FIFO_FULL : assert property(full_check)
                $display("------FIFO_FULL------: PASS");
            else
                $display("------FIFO_FULL------: FAIL");

    FIFO_EMPTY : assert property(empty_check)
                $display("------FIFO_EMPTY------: PASS");
            else
                $display("------FIFO_EMPTY------: FAIL");
    
    READ_CHECK : assert property(read_check)
                $display("------READ_CHECK------: PASS");
            else
                $display("------READ_CHECK------: FAIL");
    
    WRITE_CHECK : assert property(write_check)
                $display("------WRITE_CHECK------: PASS");
            else
                $display("------WRITE_CHECK------: FAIL");

    NO_FULL_EMPTY : assert property(no_full_no_empty)
                $display("------NO_FULL_EMPTY------: PASS");
            else
                $display("------NO_FULL_EMPTY------: FAIL");

    FULL_DEASSERT : assert property(full_deassert)
                $display("------FULL_DEASSERT------: PASS");
            else
                $display("------FULL_DEASSERT------: FAIL");

    R_W : assert property(r_w)
                $display("------SIMULTANEOUS_READ_WRITE------: PASS");
            else
                $display("------SIMULTANEOUS_READ_WRITE------: FAIL");

    IF_READ_COUNT_MINUS : assert property(count_dec)
                $display("------IF_READ_COUNT_MINUS------: PASS");
            else
                $display("------IF_READ_COUNT_MINUS------: FAIL");

    IF_WRITE_COUNT_PLUS : assert property(count_inc)
                $display("------IF_WRITE_COUNT_PLUS------: PASS");
            else
                $display("------IF_WRITE_COUNT_PLUS------: FAIL");

endmodule
                         
                         
                        