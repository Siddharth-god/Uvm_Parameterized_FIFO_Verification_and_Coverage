
// rtl 
package fifo_pkg;

parameter WIDTH = 8;
parameter ADDR  = 4;

endpackage


import uvm_pkg::*;
`include "uvm_macros.svh"
import fifo_pkg::*;

//------------------------------------DEFAULT MACROS--------------------------------------
`define NEW_COMP	\
	function new(string name = "", uvm_component parent);	\
		super.new(name,parent);	\
	endfunction

//******** NEW Object
`define NEW_OBJ	\
	function new(string name = "");	\
		super.new(name);	\
	endfunction
//----------------------------------------------------------------------------------------

module fifo #(
    WIDTH, 
    ADDR
)(
    input  logic clk,
    input  logic rstn,
    input  logic read,
    input  logic write,
    input  logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] data_out,
    output logic full,
    output logic empty
);
    localparam DEPTH = 2**ADDR;

    // for sva check for data
    logic [WIDTH-1:0] q_data;

    logic [WIDTH-1:0] fifo_mem [DEPTH-1:0];
    logic [ADDR-1:0]  rdp;
    logic [ADDR-1:0]  wrp;
    logic [ADDR : 0]  count;

    always_ff @(posedge clk) begin
        if(!rstn) begin
            rdp <= 0;
            wrp <= 0;
            count <= 0;
            data_out <= 0;

            for(int i=0; i<DEPTH; i++) begin
                fifo_mem[i] <= 0;
            end
        end
        else begin
            if(read && !empty) begin
                data_out <= fifo_mem[rdp];
                rdp <= rdp + 1;
                count--;
            end

            if(write && !full) begin
                fifo_mem[wrp] <= data_in;
                wrp <= wrp + 1;
                count++;
            end
        end
    end

    assign empty = (count == 0);
    assign full = (count == DEPTH);

endmodule
// Interface 

interface fifo_if #(WIDTH)(input bit clk);
    logic rstn;
    logic read;
    logic write;
    logic [WIDTH-1:0] data_in;
    logic [WIDTH-1:0] data_out;
    logic full;
    logic empty;

    clocking wr_drv_cb@(posedge clk);
        // default input #1 output #1; 
        output  rstn;
        output  write;
        output  data_in;
    endclocking 

    clocking wr_mon_cb@(posedge clk);
        // default input #1 output #1; 
        input  rstn;
        input  write;
        input  data_in;   
        input  full;
        input  empty;  
    endclocking 

    clocking rd_drv_cb@(posedge clk);
        // default input #1 output #1; 
        input  rstn; // why input check one more time. 
        output read;  
    endclocking

    clocking rd_mon_cb@(posedge clk);
        // default input #1 output #1; 
        default input #0; // why 1step will misalign ? 
        input rstn;
        input read;
        input data_out; // Can cause race in complex designs -- (as per industry #1step is correct which is by default present)
        input full;
        input empty;    
    endclocking

    modport WR_DRV(clocking wr_drv_cb);
    modport WR_MON(clocking wr_mon_cb);
    modport RD_DRV(clocking rd_drv_cb);
    modport RD_MON(clocking rd_mon_cb);
    
endinterface

// Uvm tb 


// Global Config -------------------------------------------------------------------------------

class g_config extends uvm_object;
    `uvm_object_utils(g_config)
    `NEW_OBJ

    virtual fifo_if #(WIDTH) vif;
    uvm_active_passive_enum is_active; 

endclass

// Transaction -------------------------------------------------------------------------------

class xtn extends uvm_sequence_item;
    `uvm_object_utils(xtn)
    `NEW_OBJ

    bit rstn; //-- not a part of transaction so no need to use. 
    rand bit read;
    rand bit write;
    rand bit [WIDTH-1:0] data_in;
    bit [WIDTH-1:0] data_out;
    bit full;
    bit empty;

    virtual function void do_print(uvm_printer printer);
        printer.print_field("data_in",data_in,8,UVM_DEC);
        printer.print_field("write",write,1,UVM_DEC);
        printer.print_field("read",read,1,UVM_DEC);
        printer.print_field("rstn",rstn,1,UVM_DEC);
        printer.print_field("full",full,1,UVM_DEC);
        printer.print_field("empty",empty,1,UVM_DEC);
        printer.print_field("data_out",data_out,8,UVM_DEC);
    endfunction 
endclass 


// Sequence -------------------------------------------------------------------------------

class seq_base extends uvm_sequence #(xtn);
    `uvm_object_utils(seq_base)
    `NEW_OBJ
endclass    

// only write / burst write
class seq_write extends seq_base;
    `uvm_object_utils(seq_write)
    `NEW_OBJ

    task body();
        //m_sequencer.lock(this);
        repeat(16) begin 
            req = xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {write == 1 && read == 0;});
            finish_item(req);
        end
        //m_sequencer.unlock(this);
    endtask 
endclass 

// only read / burst read 
class seq_read extends seq_base;
    `uvm_object_utils(seq_read)
    `NEW_OBJ

    task body();
        //m_sequencer.lock(this);
        repeat(16) begin 
            req = xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {write == 0 && read == 1;});
            finish_item(req);
        end
        //m_sequencer.unlock(this);
    endtask 
endclass 

// random traffic write
class seq_random_wr extends seq_base;
    `uvm_object_utils(seq_random_wr)
    `NEW_OBJ

    task body();
        //m_sequencer.lock(this);
        repeat(2) begin 
            req = xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {
                write dist { 1:=50, 0:=50};
            });
            finish_item(req);
        end
        //m_sequencer.unlock(this);
    endtask 
endclass 

// random traffic read
class seq_random_rd extends seq_base;
    `uvm_object_utils(seq_random_rd)
    `NEW_OBJ

    task body();
        //m_sequencer.lock(this);
        repeat(2) begin 
            req = xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {
                read dist { 1:=50, 0:=50};
            });
            finish_item(req);
        end
        //m_sequencer.unlock(this);
    endtask 
endclass 


// Sequencer -------------------------------------------------------------------------------
class wr_seqr extends uvm_sequencer #(xtn);
    `uvm_component_utils(wr_seqr)
    `NEW_COMP

endclass 

class rd_seqr extends uvm_sequencer #(xtn);
    `uvm_component_utils(rd_seqr)
    `NEW_COMP

endclass 

// Virtual seqr -------------------------------------------------------------------------------

class vseqr extends uvm_sequencer #(uvm_sequence_item);
    `uvm_component_utils(vseqr)
    `NEW_COMP

    rd_seqr rseqr;
    wr_seqr wseqr;
endclass

// Virtual seqr -------------------------------------------------------------------------------

class vseq extends uvm_sequence #(uvm_sequence_item);
    `uvm_object_utils(vseq)
    `NEW_OBJ

    // declare handles for sequences -- handles cannot be declared inside body else error.
    seq_write seq_wrh; 
    seq_read seq_rdh;
    seq_random_wr seq_rdm_wr_h;
    seq_random_rd seq_rdm_rd_h;

    vseqr vseqrh;

    task body();

        // casting to assign parent seqr handle with child seqr handle. 
        if(!$cast(vseqrh, m_sequencer))
            `uvm_fatal(get_full_name(), "Casting failed in Vsequence");

        // create the objects for sequences
        seq_rdh = seq_read::type_id::create("seq_rdh");
        seq_wrh = seq_write::type_id::create("seq_wrh");

        // for random ------
        seq_rdm_wr_h = seq_random_wr::type_id::create("seq_rdm_wr_h");
        seq_rdm_rd_h = seq_random_rd::type_id::create("seq_rdm_rd_h");


        // start sequence on physical sequencer

        // Burst mode ------------------------------------
        $display("\n-----------------------------BURST MODE ON-----------------------------\n\n");
        seq_wrh.start(vseqrh.wseqr);
        seq_rdh.start(vseqrh.rseqr);


        // Simultaneous read and write -------------------

        $display("\n-----------------------------SIMULTANEOUS RW MODE ON-----------------------------\n\n");
        fork
            seq_rdh.start(vseqrh.rseqr);
            seq_wrh.start(vseqrh.wseqr);
        join

        // Random traffic ----------------------------

        $display("\n-----------------------------RANDOM TRAFFIC MODE ON-----------------------------\n\n");
        fork
            seq_rdm_wr_h.start(vseqrh.wseqr);
            seq_rdm_rd_h.start(vseqrh.rseqr);
        join
    endtask
endclass    

// Driver -------------------------------------------------------------------------------
// If Both driver sets reset in interface rstn is x, design breaks --- good question and topic to add on linkdin

class wr_driver extends uvm_driver #(xtn);
    `uvm_component_utils(wr_driver)
    `NEW_COMP

    virtual fifo_if #(WIDTH) vif;
    g_config g_cfg; 


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db #(g_config)::get(this,"","g_config",g_cfg))
            `uvm_fatal(get_full_name(),"Cannot get() config from TEST")
    endfunction     

     // connect config vif to vif 
    function void connect_phase(uvm_phase phase);
        vif = g_cfg.vif;
    endfunction    

    task run_phase(uvm_phase phase);

        @(vif.wr_drv_cb) begin 
            vif.wr_drv_cb.rstn <= 0;
            vif.wr_drv_cb.data_in <= 0;
            vif.wr_drv_cb.write <= 0;
        end
        repeat(2) @(vif.wr_drv_cb);

            vif.wr_drv_cb.rstn <= 1; // reset released

        forever begin
            seq_item_port.get_next_item(req);

// We usually do not use driver print because it makes reading output log harder that it needs to be. 

            @(vif.wr_drv_cb) begin 
                vif.wr_drv_cb.rstn <= 1;
                vif.wr_drv_cb.data_in <= req.data_in;
                vif.wr_drv_cb.write <= req.write;
            end

            seq_item_port.item_done();
        end
    endtask

endclass 

class rd_driver extends uvm_driver #(xtn); // read driver cannot control reset else logic breaks
    `uvm_component_utils(rd_driver)
    `NEW_COMP

    virtual fifo_if #(WIDTH) vif;
    g_config g_cfg;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db #(g_config)::get(this,"","g_config",g_cfg))
            `uvm_fatal(get_full_name(),"Cannot get() config from TEST")
    endfunction     

    // connect config vif to vif 
    function void connect_phase(uvm_phase phase);
        vif = g_cfg.vif;
    endfunction

    task run_phase(uvm_phase phase);

        forever begin
            seq_item_port.get_next_item(req);
/*
            `uvm_info(get_type_name(),"nDriving transaction", UVM_LOW)
                req.print();
*/
/*            `uvm_info(get_type_name(),
                        $sformatf("\nDriving transaction ==> read=%0d\n",
                        req.read), 
                        UVM_LOW)
*/
            @(vif.rd_drv_cb)

            if(vif.rd_drv_cb.rstn)
                vif.rd_drv_cb.read <= req.read;

            seq_item_port.item_done();
        end
    endtask

endclass 

// Monitor -------------------------------------------------------------------------------\Logic needs to be written

class rd_monitor extends uvm_monitor;
    `uvm_component_utils(rd_monitor)
    `NEW_COMP

    virtual fifo_if #(WIDTH) vif;
    uvm_analysis_port #(xtn) rd_mon_port;
    g_config g_cfg;


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        rd_mon_port = new("rd_mon_port",this);

        if(!uvm_config_db #(g_config)::get(this,"","g_config",g_cfg))
            `uvm_fatal(get_full_name(),"Cannot get() config from TEST")
    endfunction 

    // connect config vif to vif 
    function void connect_phase(uvm_phase phase);
        vif = g_cfg.vif;
    endfunction    

    task run_phase(uvm_phase phase);
        xtn xtnh;
        
        forever begin 
            @(vif.rd_mon_cb)
            
            if(vif.rd_mon_cb.read && !vif.rd_mon_cb.empty) begin 
                xtnh = xtn::type_id::create("xtnh");
                xtnh.read = vif.rd_mon_cb.read;
                xtnh.data_out = vif.rd_mon_cb.data_out;
                xtnh.full = vif.rd_mon_cb.full;
                xtnh.empty = vif.rd_mon_cb.empty;
/*
                `uvm_info(get_type_name(),
                        $sformatf("\nSampling transaction ==> data_out=%0d | read=%0d | full=%0d | empty=%0d\n",
                        xtnh.data_out,
                        xtnh.read, 
                        xtnh.full, 
                        xtnh.empty), 
                        UVM_LOW)
*/
                `uvm_info(get_type_name(),"Sampling transaction", UVM_LOW)
                xtnh.print();

                rd_mon_port.write(xtnh);
            end
        end
    endtask

endclass


class wr_monitor extends uvm_monitor;
    `uvm_component_utils(wr_monitor)
    `NEW_COMP

    virtual fifo_if #(WIDTH) vif;
    uvm_analysis_port #(xtn) wr_mon_port;
    g_config g_cfg;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        wr_mon_port = new("wr_mon_port",this);

        if(!uvm_config_db #(g_config)::get(this,"","g_config",g_cfg))
            `uvm_fatal(get_full_name(),"Cannot get() config from TEST")
    endfunction     

    // connect config vif to vif 
    function void connect_phase(uvm_phase phase);
        vif = g_cfg.vif;
    endfunction

    task run_phase(uvm_phase phase);
        xtn xtnh;

        forever begin 
            @(vif.wr_mon_cb)
            
            if(vif.wr_mon_cb.write && !vif.wr_mon_cb.full)  begin 
                xtnh = xtn::type_id::create("xtnh");
                xtnh.write = vif.wr_mon_cb.write;
                xtnh.data_in = vif.wr_mon_cb.data_in;
                xtnh.rstn = vif.wr_mon_cb.rstn;   // not declared in xtn, directly driving reset to dut from driver.

                `uvm_info(get_type_name(),"Sampling transaction", UVM_LOW)
                xtnh.print();

                wr_mon_port.write(xtnh);
            end
        end
    endtask    
endclass

// Agent -------------------------------------------------------------------------------
class wr_agent extends uvm_agent;
    `uvm_component_utils(wr_agent)
    `NEW_COMP

    wr_seqr wr_seqr_h;
    wr_monitor wr_monitor_h;
    wr_driver wr_driver_h;


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        wr_monitor_h = wr_monitor::type_id::create("wr_monitor_h",this);
        //if(is_active == UVM_ACTIVE) begin 
            wr_driver_h = wr_driver::type_id::create("wr_driver_h",this);
            wr_seqr_h = wr_seqr::type_id::create("wr_seqr_h",this);
        //end
    endfunction    

    function void connect_phase(uvm_phase phase);
        wr_driver_h.seq_item_port.connect(wr_seqr_h.seq_item_export);
    endfunction  

endclass 

class rd_agent extends uvm_agent;
    `uvm_component_utils(rd_agent)
    `NEW_COMP

    rd_seqr rd_seqr_h;
    rd_monitor rd_monitor_h;
    rd_driver rd_driver_h;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        rd_monitor_h = rd_monitor::type_id::create("rd_monitor_h",this);
        //if(is_active == UVM_ACTIVE) begin 
            rd_driver_h = rd_driver::type_id::create("rd_driver_h",this);
            rd_seqr_h = rd_seqr::type_id::create("rd_seqr_h",this);
        //end
    endfunction   

    function void connect_phase(uvm_phase phase);
        rd_driver_h.seq_item_port.connect(rd_seqr_h.seq_item_export);
    endfunction   

endclass 

// Scoreboard -------------------------------------------------------------------------------

class sb extends uvm_scoreboard; 
    `uvm_component_utils(sb)
    // comparision related handles 
    xtn rd_xtn;
    xtn wr_xtn; 
    xtn ref_data[$];
    xtn pop_ref;

    // coverage related handles 
    xtn write_cov_data; 
    xtn read_cov_data;
    
    uvm_tlm_analysis_fifo #(xtn) fifo_rd;
    uvm_tlm_analysis_fifo #(xtn) fifo_wr;

    // write coverage 
    covergroup write_coverage;
        // option.per_instance == 1; 
        W_DATA : coverpoint write_cov_data.data_in{
            bins low = {[0:63]};
            bins mid1 = {[64:127]};
            bins mid2 = {[128:191]};
            bins high = {[192:255]};
        }

        W_ENB : coverpoint write_cov_data.write{
            bins high = {1};
        }

        W_RESET : coverpoint write_cov_data.rstn{
            bins low = {0};
        }

        DATA_ENB_RST : cross W_DATA, W_ENB, W_RESET;
    endgroup

    // read coverage
    covergroup read_coverage;
        // option.per_instance == 1; 
        R_DATA : coverpoint read_cov_data.data_out{
            bins low = {[0:63]};
            bins mid1 = {[64:127]};
            bins mid2 = {[128:191]};
            bins high = {[192:255]};
        }

        R_EMPTY : coverpoint read_cov_data.empty{
            bins low = {0};
            bins high = {1};
        }

        R_FULL : coverpoint read_cov_data.full{
            bins low = {0};
            bins high = {1};
        }

        DATA_EMPTY_FULL : cross R_DATA, R_EMPTY, R_FULL;
    endgroup

    
    function new(string name="",uvm_component parent);
        super.new(name,parent);
        fifo_rd = new("fifo_rd",this);
        fifo_wr = new("fifo_wr",this);

        write_coverage = new();
        read_coverage = new();
    endfunction

    function void ref_model(xtn local_wrxtn);
        if(local_wrxtn.write && !local_wrxtn.full)
            ref_data.push_back(local_wrxtn);
    endfunction 

    function void pop_here(xtn local_rdxtn);
        if(local_rdxtn.read && !local_rdxtn.empty) begin 
            pop_ref = ref_data.pop_front();  
            $display("---------pop_expected_ref----------|| data_in = %0d",pop_ref.data_in);
        end
    endfunction
    
    task run_phase(uvm_phase phase);
        fork
            forever begin
                fifo_wr.get(wr_xtn);
                $display("/////////// get write mon data /////////// data_in=%0d | rstn=%0d | write=%0d",
                            wr_xtn.data_in, wr_xtn.rstn, wr_xtn.write);
                ref_model(wr_xtn);
                write_cov_data = wr_xtn;
                write_coverage.sample();
            end
            forever begin
                fifo_rd.get(rd_xtn);
                $display("/////////// get read mon data /////////// data_out=%0d | read=%0d | full=%0d | empty=%0d",
                            rd_xtn.data_out, rd_xtn.read, rd_xtn.full, rd_xtn.empty);
                pop_here(rd_xtn);

                if(!(pop_ref.data_in == rd_xtn.data_out))
                    `uvm_error(get_type_name(), $sformatf(
                                    "\n\nScoreboard Error [Data Mismatch]: \n Received Transaction: %d \n Expected Transaction: %d\n",
                                    rd_xtn.data_out, pop_ref.data_in))
                else 
                    `uvm_info(get_type_name(),$sformatf("\n\n Scoreboard Success [Data Match Successfully] ==> [ DATA OUT = EXP OUT ] : [%0d = %0d]\n",
                        rd_xtn.data_out, pop_ref.data_in),
                        UVM_LOW)
                read_cov_data = rd_xtn;
                read_coverage.sample();
            end
        join

    endtask 
endclass


// Environment -------------------------------------------------------------------------------
class env extends uvm_env;
    `uvm_component_utils(env)
    `NEW_COMP

    rd_agent rd_agent_h;
    wr_agent wr_agent_h;
    sb sbh;
    vseqr vseqrh;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sbh = sb::type_id::create("sbh",this);
        rd_agent_h = rd_agent::type_id::create("rd_agent_h",this);
        wr_agent_h = wr_agent::type_id::create("wr_agent_h",this);
        vseqrh = vseqr::type_id::create("vseqrh",this);
    endfunction  

    function void connect_phase(uvm_phase phase);
        // connect vseqr seqr's and agent seqr's
        vseqrh.rseqr = rd_agent_h.rd_seqr_h;
        vseqrh.wseqr = wr_agent_h.wr_seqr_h; 

        // connect analysis port and analysis fifo
        rd_agent_h.rd_monitor_h.rd_mon_port.connect(sbh.fifo_rd.analysis_export);
        wr_agent_h.wr_monitor_h.wr_mon_port.connect(sbh.fifo_wr.analysis_export);
    endfunction   

endclass 

// Test -------------------------------------------------------------------------------
class test extends uvm_test;
    `uvm_component_utils(test)
    `NEW_COMP

    env envh;
    g_config g_cfg;
    vseq vseqh;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        g_cfg = g_config::type_id::create("g_cfg");
        vseqh = vseq::type_id::create("vseqh");

        if(!uvm_config_db #(virtual fifo_if #(WIDTH))::get(this,"","fifo_if",g_cfg.vif))
            `uvm_fatal(get_full_name(),"Cannot get() vif from TOP")

        // set config to all low levels
        uvm_config_db #(g_config)::set(this,"*","g_config",g_cfg);

        envh = env::type_id::create("envh",this);
    endfunction     

    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction 

    task run_phase(uvm_phase phase);
            phase.raise_objection(this);
            vseqh.start(envh.vseqrh);
            phase.drop_objection(this);
    endtask 

endclass 

module uvm_fifo;

    bit clk = 0;

    parameter WIDTH = 8;
    parameter ADDR  = 4;
    
    always #5 clk = ~clk;

    fifo_if #(.WIDTH(WIDTH)) IF(clk);

    fifo #(
        .WIDTH(WIDTH),
        .ADDR(ADDR)
        ) DUT(
        .clk(clk),
        .rstn(IF.rstn),
        .data_in(IF.data_in),
        .data_out(IF.data_out),
        .read(IF.read),
        .write(IF.write),
        .full(IF.full),
        .empty(IF.empty)
    );

    bind fifo fifo_assertions #(
        .WIDTH(WIDTH),
        .ADDR(ADDR)
        ) FIFO_ASSERTIONS(
        .clk(clk),
        .rstn(rstn),
        .data_in(data_in),
        .data_out(data_out),
        .read(read),
        .write(write),
        .full(full),
        .empty(empty),
        .count(DUT.count),
        .rdp(DUT.rdp),
        .wrp(DUT.wrp)
    );


    initial begin 
        uvm_config_db #(virtual fifo_if #(WIDTH))::set(null,"*","fifo_if",IF);
        run_test("test"); 
    end
endmodule 
//-------------------------------------------------------------END---------------------------------------------------------------
