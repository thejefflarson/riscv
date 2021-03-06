`default_nettype none
module skidbuffer
#(
  parameter WIDTH = 32
)
(
  input  var logic             clk,
  input  var logic             reset,
  output var logic             input_ready,
  input  var logic             input_valid,
  input  var logic [WIDTH-1:0] input_data,
  input  var logic             output_ready,
  output var logic             output_valid,
  output var logic [WIDTH-1:0] output_data
);
  logic [WIDTH-1:0] buffer;
  logic [WIDTH-1:0] out;
  logic [WIDTH-1:0] selected_data;

  logic             insert;
  logic             remove;
  always_comb begin
    insert = (input_ready && input_valid);
    remove = (output_ready && output_valid);
  end

  always_comb begin
    output_data = out;
  end

  localparam empty = 2'b00;
  localparam busy = 2'b01;
  localparam full = 2'b10;
  logic [1:0] state = empty;
  always_ff @(posedge clk) begin
    if (reset) begin
      input_ready <= 1;
      output_valid <= 0;
      state <= empty;
    end begin
      input_ready <= 1;
      output_valid <= 1;
      (* parallel_case, full_case *)
      case(state)
        empty: if (insert && !remove) begin
          state <= busy;
          out <= input_data;
        end else begin
          output_valid <= 0;
        end
        busy: if (insert && !remove) begin
          buffer <= input_data;
          state <= full;
        end else if (!insert && remove) begin
          state <= empty;
        end else if (insert && remove) begin
          state <= busy;
          out <= input_data;
        end
        full: if (!insert && remove) begin
          state <= busy;
          input_ready <= 0;
          out <= buffer;
        end else if (insert && remove) begin
          buffer <= input_data;
          out <= buffer;
        end
      endcase
    end
  end // always_ff @ (posedge clk)
 `ifdef FORMAL
  logic clocked;
  initial clocked = 0;
  always_ff @(posedge clk) clocked = 1;
  initial assume(reset);
  always_comb if(!clocked) assume(reset);
  (* keep *) logic stable;
  always_ff @(posedge clk) stable <= output_valid == $past(output_valid);
  // data stability tests
  always_ff @(posedge clk) if(clocked && $past(!reset) && $past(input_valid) && $past(!input_ready)) assume(input_valid && $stable(input_data));
  always_ff @(posedge clk) if(clocked && $past(!reset) && $past(output_valid) && $past(!output_ready)) begin
    assert(output_valid);
    assert($stable(output_data));
  end
 `endif
endmodule
