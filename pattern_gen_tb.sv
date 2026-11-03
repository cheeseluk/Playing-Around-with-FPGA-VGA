`timescale 1ns / 1ps
// ^ "time unit / precision". #1 now means 1 ns. Put this at the top of every tb.

// =====================================================================
// Testbench for pattern_gen
// A testbench is just a module with NO ports. It only exists in simulation.
// =====================================================================
module pattern_gen_tb;

    // -----------------------------------------------------------------
    // 1. Signals that connect to the DUT (device under test).
    //    Inputs to the DUT are things WE drive; outputs are things WE read.
    // -----------------------------------------------------------------
    logic [9:0] x, y;
    logic       active;
    logic [3:0] r, g, b;

    // Bookkeeping
    int errors = 0;
    int checks = 0;

    // -----------------------------------------------------------------
    // 2. Instantiate the DUT.
    //    .* connects every port to a signal with the same name in this scope.
    //    (Explicit form would be: .x(x), .y(y), .active(active), ...)
    // -----------------------------------------------------------------
    pattern_gen dut (.*);

    // -----------------------------------------------------------------
    // 3. A reusable "check" task.
    //    Tasks are like functions but can contain delays (#).
    //    'automatic' gives each call its own local variables (always use it).
    // -----------------------------------------------------------------
    task automatic check(input logic [9:0]  tx, ty,
                         input logic        tactive,
                         input logic [11:0] expected,
                         input string       label);
        x      = tx;
        y      = ty;
        active = tactive;
        #1;                                   // let combinational logic settle
        checks++;
        if ({r, g, b} !== expected) begin     // !== also catches X/Z
            errors++;
            $error("[%s] x=%0d y=%0d active=%0b: got %h, expected %h",
                   label, tx, ty, tactive, {r, g, b}, expected);
        end
    endtask

    // -----------------------------------------------------------------
    // 4. Reference model: what SHOULD the color be?
    //    Write this a DIFFERENT way than the DUT (no x/80 here!),
    //    otherwise a wrong idea passes its own test.
    // -----------------------------------------------------------------
    function automatic logic [11:0] expected_bar_color(input logic [9:0] tx);
        
        logic [11:0] BAR_COLORS [8] = '{12'hFFF, 12'hFF0, 12'h0FF, 12'h0F0, 12'hF0F, 12'hF00, 12'h00F, 12'h000};

        for (int i = 0; i < 8; i++) begin
            if (tx <= 80*(i+1) -1) begin
                return BAR_COLORS[i];
            end
        end
        return 12'hXXX;   // placeholder: makes every bar check fail until you fill it in
    endfunction

    // -----------------------------------------------------------------
    // 5. The actual test sequence. 'initial' runs once, top to bottom.
    // -----------------------------------------------------------------
    initial begin
        $display("=== pattern_gen tb start ===");

        // --- Test 1: blanking. active=0 must ALWAYS be black. (complete) ---
        check(10'd0,   10'd0,   1'b0, 12'h000, "blank");
        check(10'd320, 10'd240, 1'b0, 12'h000, "blank");
        check(10'd700, 10'd500, 1'b0, 12'h000, "blank");   // off-screen coords

        // --- Test 2: border must be white. ---
        check(10'd0,   10'd0,   1'b1, 12'hFFF, "border TL corner");
        check(10'd320, 10'd0,   1'b1, 12'hFFF, "border top edge");
        check(10'd639, 10'd0, 1'b1, 12'hFFF, "top right corner");
        // TODO: other 3 corners, and the middle of the left, right, bottom edges

        // --- Test 3: bar boundaries (where off-by-one bugs live). ---
        // y=240 so we're nowhere near the border.
        check(10'd79, 10'd240, 1'b1, 12'hFFF, "bar 0 last col");
        check(10'd80, 10'd240, 1'b1, 12'hFF0, "bar 1 first col");
        // TODO: every other boundary: 159/160, 239/240, ... 559/560
        // Careful: x=1 and x=638 are bars too, but x=0 and x=639 are border!

        // --- Test 4: exhaustive sweep of the visible area. ---
        // TODO: nested loops over every x (0..639) and y (0..479).
        //       Decide the expected color yourself:
        //         border pixel -> 12'hFFF
        //         otherwise    -> expected_bar_color(x)
        //       then call check(...) with label "sweep".
        // Hint: loop variables can be declared inline: for (int i = 0; ...)

        for (int yy = 0; yy <480; yy++) begin
            for (int xx = 0; xx < 640; xx++) begin
                if (xx == 0 || yy == 0 || xx == 639 || yy == 479) begin
                    check(xx, yy, 1'b1, 12'hFFF, "edge cases");
                end
                else begin
                    check(xx, yy, 1'b1, expected_bar_color(xx), "sweeping...");
                end
            end
        end

        // --- Summary ---
        $display("=== %0d checks, %0d errors ===", checks, errors);
        if (errors == 0) $display("PASS");
        else             $display("FAIL");
        $finish;   // end the simulation
    end

endmodule

