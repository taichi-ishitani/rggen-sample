module rggen_bit_field_rwl_rwe
  import rggen_rtl_pkg::*;
#(
  parameter rggen_rwle_mode   MODE          = RGGEN_LOCK_MODE,
  parameter int               WIDTH         = 1,
  parameter bit [WIDTH-1:0]   INITIAL_VALUE = '0
)(
  input   logic             clk,
  input   logic             rst_n,
  input   logic             i_lock_or_enable,
  rggen_bit_field_if.slave  bit_field_if,
  output  logic [WIDTH-1:0] o_value
);
  logic [WIDTH-1:0] write_data;
  logic [WIDTH-1:0] write_mask;
  logic [WIDTH-1:0] value;

  assign  o_value                           = value;
  assign  bit_field_if.value[WIDTH-1:0]     = value;
  assign  bit_field_if.read_data[WIDTH-1:0] = value;

  assign  write_data  = bit_field_if.write_data[WIDTH-1:0];
  assign  write_mask  = bit_field_if.write_mask[WIDTH-1:0];
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      value <= INITIAL_VALUE;
    end
    else if ((i_lock_or_enable == MODE) && bit_field_if.write_access) begin
      value <= (value      & (~write_mask))
             | (write_data &   write_mask );
    end
  end
endmodule
