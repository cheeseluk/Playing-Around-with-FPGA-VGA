module pattern_gen (input logic [9:0] x, y,
                    input logic active,
                    output logic [3:0] r, g, b);

                    logic [2:0] colors;
                    
                    always_comb begin
                        colors = x/80;
                        case (active)
                            1'b0: begin 
                                r = 4'b0000;
                                b = 4'b0000;
                                g = 4'b0000;
                            end
                            1'b1: begin
                                if (x == 0 || x == 639 || y == 0 || y == 479) begin
                                    {r, g, b} = '1;
                                end 

                                else case (colors)
                                
                                        3'd0: {r, g, b} = 12'hFFF;

                                        3'd1: {r, g, b} = 12'hFF0;

                                        3'd2: {r, g, b} = 12'h0FF;

                                        3'd3: {r, g, b} = 12'h0F0;

                                        3'd4: {r, g, b} = 12'hF0F;   

                                        3'd5: {r, g, b} = 12'hF00;

                                        3'd6: {r, g, b} = 12'h00F;

                                        3'd7: {r, g, b} = 12'h000;

                                endcase
                            end
                        endcase
                    end

endmodule
