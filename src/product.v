module product(
    input wire clk,                  // Reloj
    input wire reset,                // Señal de reset
    input wire [15:0] A,             // Registro de entrada A
    input wire [15:0] B,             // Registro de entrada B
    input wire MAC_START,            // Señal para iniciar la operación
    output reg [39:0] MAC_ACC,       // Acumulador interno de 40 bits
    output reg mac_start_latch,      // Señal para bloquear el inicio mientras opera
    output reg mac_done, 
    output reg [4:0] bit_counter // Señal para indicar que el cálculo ha terminado
);

    reg [31:0] product;              // Registro temporal para el resultado del producto

    always @(posedge clk) begin
        if (reset) begin
            MAC_ACC <= 40'd0;        // Inicializar acumulador
            product <= 32'd0;        // Inicializar producto
            mac_start_latch <= 1'b0; // Reiniciar latch
            mac_done <= 1'b0;        // Reiniciar señal de finalización
            bit_counter <= 5'd0;     // Reiniciar contador de bits
        end else begin
            if (MAC_START && !mac_start_latch) begin
                // Iniciar el cálculo del producto
                mac_start_latch <= 1'b1; // Activar el latch para bloquear reinicio
                mac_done <= 1'b0;       // Reiniciar señal de finalización
                product <= 32'd0;       // Inicializar producto
                bit_counter <= 5'd0;    // Iniciar contador de bits
            end

            if (mac_start_latch && !mac_done) begin
                // Realizar el cálculo del producto bit por bit
              if (bit_counter < 16) begin
                    if (B[bit_counter]) begin
                        // Si el bit actual de B es 1, sumar A desplazado
                        product <= product + ({16'd0, A} << bit_counter);
                    end
                    bit_counter <= bit_counter + 1; // Incrementar el contador de bits
                end else begin
                    // Finalizar el cálculo cuando se hayan procesado todos los bits
                    MAC_ACC <= MAC_ACC + {8'd0, product}; // Actualizar acumulador
                    mac_done <= 1'b1;       // Indicar que la operación ha terminado
                    product <= 32'd0;
                end
            end

            if (!MAC_START) begin
                // Reiniciar latch cuando MAC_START es 0
                mac_start_latch <= 1'b0;
            end
        end
    end
endmodule