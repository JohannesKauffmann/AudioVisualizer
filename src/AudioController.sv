module AudioController
(
    input   logic   AUD_ADC_CLK,    // 1 = left channel, 0 = right channel
                    AUD_BCLK,
                    AUD_ADC_DATA
);

    parameter [4:0] dataLength = 5'd16; // 16-bits audio

    reg [5:0] bit_counter;
    
    reg [31:0] tmp_data;

    always_ff @ (AUD_ADC_CLK)
    begin
        bit_counter = 5'd0;
    end

    always_ff @ (posedge AUD_BCLK)
    begin
        if (bit_counter >= 0 && bit_counter < dataLength)
        begin
            bit_counter = bit_counter + 1;

            if (AUD_ADC_CLK == 1'b1)
                // left audio data
                tmp_data[dataLength + (dataLength - bit_counter)] <= AUD_ADC_DATA;
            else
                // right audio data
                tmp_data[dataLength - bit_counter] <= AUD_ADC_DATA;
        end
    end

endmodule
