`timescale 1ns / 1ps

module TB_Cloneless_mid_pSquare_dSHARES_IPM_kRED_verilog;

reg clk, rst, read, write;
reg [2:0] address;
reg [3:0] data_in;
reg [123:0] ciphertext;
reg [3:0] state = 4'b0000;

wire [3:0] data_out;
wire [123:0] plaintext;
wire [159:0] seed;

parameter clk_period = 10;
integer counter;

// Unit Under Test
Cloneless UUT (clk, rst, read, write, address, data_in, data_out);

// Test Vector
assign plaintext = 124'hF00CDAD7A2893AD16895566C2BB7DF4;
assign seed = 160'hC4C1E9A9DB026CCA5B1F2835A77D200C2F1197C4;

// Clock Process
always begin
    clk <= 0;
    #(clk_period/2);
    clk <= 1;
    #(clk_period/2);
end

// Stimulation Process
always @(posedge clk) begin
    case(state)
        4'b0000:
            begin
                rst                                     = 1'b1;
                read                                    = 1'b0;
                write                                   = 1'b0;
                address                                 = 3'b000;
                data_in                                 = 4'b0000;
                ciphertext                              = 124'h0000000000000000000000000000000;
                counter                                 = 0;
                state                                   = 4'b0001;
            end
        4'b0001:
            begin
                rst                                     = 1'b0;
                write                                   = 1'b1;
                data_in                                 = 4'b1000;
                state                                   = 4'b0010;
            end
        4'b0010:
            begin
                address                                 = 3'b010;
                data_in                                 = plaintext[120-4*counter +: 4];
                counter                                 = counter + 1;
                if (counter == 31) begin
                    counter                             = 0;
                    state                               = 4'b0011;
                end
            end
        4'b0011:
            begin
                address                                 = 3'b011;
                data_in                                 = seed[156-4*counter +: 4];
                counter                                 = counter + 1;
                if (counter == 40) begin
                    counter                             = 0;
                    state                               = 4'b0100;
                end
            end
        4'b0100:
            begin
                address                                 = 3'b000;
                data_in                                 = 4'b0100;
                state                                   = 4'b0101;
            end
        4'b0101:
            begin
                read                                    = 1'b1;
                write                                   = 1'b0;
                address                                 = 3'b100;
                if (data_out[3] == 1'b1) begin
                    state                               = 4'b0110;
                end
            end
        4'b0110:
            begin
                address                                 = 3'b101;
                state                                   = 4'b0111;
            end
        4'b0111:
            begin
                ciphertext[120-4*counter +: 4]          = data_out;
                counter                                 = counter + 1;
                if (counter == 31) begin
                    counter                             = 0;
                    state                               = 4'b1000;
                end
            end
        4'b1000:
            begin
                read                                    = 1'b0;
                address                                 = 3'b000;
                data_in                                 = 4'b0000;
                if(ciphertext == 124'h1D209E842606FF65984DCD619F408FF) begin
                    $display("SUCCESS");
                end else begin
                    $display("FAILURE");
                end
                state                                   = 4'b1001;
            end
        4'b1001:
            begin
                rst                                     = 1'b1;
                $finish;
            end
    endcase
end

endmodule

