module AudioController
(
    input   logic   AUD_ADC_CLK,    // 1 = left channel, 0 = right channel
                    AUD_BCLK,       // Audio bitclock
                    AUD_ADC_DATA,   // Audio data line

                    wrfull_sig,     // FIFO full indicator

    output logic    wrreq_sig,      // FIFO write request input

    output logic [31:0] data_sig    // FIFO data input
);
    parameter [4:0] dataLength = 5'd16; // Bit depth is 16 bits.

    reg [4:0] left_counter = 5'd0;      // Counters for each audio channel.
    reg [4:0] right_counter = 5'd0;
    logic [31:0] audio_data = 10'b0;              // 16 MSBs hold left channel data, 16 LSBs hold right channel data.

//    always_ff @ (posedge AUD_ADC_CLK)
//    begin
//        audio_data <= audio_data + 10'b1;
//    end

    always_ff @ (posedge AUD_BCLK)
    begin
        // Depending on the left/right channel, increment counter for current channel
        // and reset the counter for the other channel.
        if (AUD_ADC_CLK)
        begin
            right_counter = 5'd0;

            // Only retrieve data when counter is in range.
            if (left_counter >= 0 && left_counter < dataLength)
            begin
                left_counter = left_counter + 1'b1;

                audio_data[getIndex(left_counter, AUD_ADC_CLK)] <= AUD_ADC_DATA;
            end
        end
        else
        begin
            left_counter = 5'd0;

            if (right_counter >= 0 && right_counter < dataLength)
            begin
                right_counter = right_counter + 1'b1;

                audio_data[getIndex(right_counter, AUD_ADC_CLK)] <= AUD_ADC_DATA;
            end

            // Write data to FIFO after last bit has been received
            if (right_counter == dataLength && wrfull_sig == 1'b0)
            begin
                wrreq_sig <= 1'b1;
                data_sig <= audio_data;
                right_counter = right_counter + 1'b1;
            end
            else
            begin
                // Indicate writing is done
                wrreq_sig <= 1'b0;
            end
        end
    end

    // Given an index and left/right indicator, returns the array index to write data to where 0 >= index <= 31.
    function [4:0] getIndex
    (
        input logic [4:0] bit_cnt,  // bit_cnt should be 1 <= bit_cnt <= 16.
        input logic isLeft          // Indicates left or right channel.
    );
    begin
        if (isLeft)
            return dataLength + (dataLength - bit_cnt);
        else
            return dataLength - bit_cnt;
    end
    endfunction

endmodule
