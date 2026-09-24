`include "uart_env.sv"

class uart_test;

    uart_env env;

    integer directed_tests;
    integer randomized_tests;

    function new();

        env = new();

        directed_tests   = 10;
        randomized_tests = 100;

    endfunction


    task build;

        env.build();

        $display("[TEST] UART test environment ready");

    endtask


    task report;

        $display("");
        $display("================================================");
        $display("             UART TEST SUMMARY");
        $display("================================================");

        $display(
            "DIRECTED TESTS       = %0d",
            directed_tests
        );

        $display(
            "RANDOMIZED TESTS     = %0d",
            randomized_tests
        );

        $display(
            "TOTAL TESTS          = %0d",
            directed_tests + randomized_tests
        );

        $display(
            "PASSED CHECKS        = %0d",
            env.scoreboard.passed_checks
        );

        $display(
            "FAILED CHECKS        = %0d",
            env.scoreboard.failed_checks
        );

        if (env.scoreboard.failed_checks == 0)
            $display("OVERALL RESULT = PASS");
        else
            $display("OVERALL RESULT = FAIL");

        $display("================================================");

    endtask

endclass