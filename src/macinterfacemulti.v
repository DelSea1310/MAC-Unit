module mac_interface (
    input wire clk,
    input wire reset,
    input wire [7:0] addr,           // Dirección de 8 bits
    input wire [31:0] data_in,       // Datos de entrada para escritura
    input wire write_enable,         // Señal para habilitar escritura
    output reg [31:0] data_out,      // Datos de salida para lectura
    output wire IRQ_MAC              // Señal de interrupción del módulo MAC
);

    // Conexiones internas al módulo MAC
    reg [31:0] MAC_INA;
    reg [31:0] MAC_INB;
    reg [7:0] MAC_CTRL;
    wire [39:0] MAC_ACC;
    wire [15:0] MAC_OUT;

    // Instancia del módulo MAC
    mac mac_instance (
        .clk(clk),
        .reset(reset),
        .MAC_INA(MAC_INA),
        .MAC_INB(MAC_INB),
        .MAC_CTRL(MAC_CTRL),
        .MAC_OUT(MAC_OUT),
        .MAC_ACC(MAC_ACC),
        .IRQ_MAC(IRQ_MAC)          // Conexión de la señal de interrupción
    );

    // Proceso principal de lectura/escritura según la dirección
    always @(posedge clk) begin
        if (reset) begin
            // Resetear todos los registros
            MAC_INA <= 32'd0;
            MAC_INB <= 32'd0;
            MAC_CTRL <= 8'd0;
            data_out <= 32'd0;
        end else begin
            if (write_enable) begin
                // Escritura en los registros del módulo MAC
                case (addr)
                    8'h24: MAC_INA <= data_in;           // Dirección 0x24 para MAC_INA
                    8'h25: MAC_INB <= data_in;           // Dirección 0x25 para MAC_INB
                    8'h29: MAC_CTRL <= data_in[7:0];     // Dirección 0x29 para MAC_CTRL (solo 8 bits)
                    default: ;                           // Direcciones no válidas, no hacer nada
                endcase
            end else begin
                // Lectura de los registros del módulo MAC
                case (addr)
                    8'h26: data_out <= MAC_ACC[31:0];           // Dirección 0x26 para la parte baja de MAC_ACC
                    8'h27: data_out <= {24'd0, MAC_ACC[39:32]}; // Dirección 0x27 para la parte alta de MAC_ACC
                    8'h28: data_out <= {16'd0, MAC_OUT};        // Dirección 0x28 para MAC_OUT (solo 16 bits)
                    default: data_out <= 32'd0;                 // Direcciones no válidas, devuelve 0
                endcase
            end
        end
    end

endmodule

module mac (
    input wire clk,                   // Reloj
    input wire reset,                 // Señal de reset
    input wire [31:0] MAC_INA,        // Registro de entrada A
    input wire [31:0] MAC_INB,        // Registro de entrada B
    input wire [7:0] MAC_CTRL,        // Registro de control
    output wire [39:0] MAC_ACC,        // Acumulador interno de 40 bits
    output reg [15:0] MAC_OUT,        // Salida de 16 bits
    output reg IRQ_MAC                // Señal de interrupción
);

    // Decodificación de MAC_CTRL
    wire MAC_ON = MAC_CTRL[7];                     // Bit para encender el módulo
    wire [2:0] MAC_SHIFTER = MAC_CTRL[6:4];        // Control del desplazamiento
    wire [1:0] MAC_INPUT_MODE = MAC_CTRL[3:2];     // Modo de entrada
    wire MAC_START = MAC_CTRL[1];                  // Inicio de la operación MAC
    wire MAC_I_MSK = MAC_CTRL[0];
    wire [4:0] bit_counter;

    // Variables para manejar entradas A y B según el modo de entrada
   // reg [39:0] ACC
    reg [15:0] A;
    reg [15:0] B;
    reg [1:0] state;                // Estado interno para manejar el caso 11
    wire mac_start_latch;            // Latch para detectar el flanco ascendente de MAC_START
    wire mac_done;                   // Indica cuando la operación MAC ha concluido

    product mac_product (
        .clk(clk),
        .reset(reset),
        .A(A),
        .B(B),
        .MAC_START(MAC_START),
        .MAC_ACC(MAC_ACC),
        .mac_start_latch(mac_start_latch),
        .bit_counter(bit_counter),
        .mac_done(mac_done)          // Conexión de la señal de interrupción
    );

    // Lógica de selección de entrada basada en MAC_INPUT_MODE y el estado interno
    always @(*) begin
        case (MAC_INPUT_MODE)
            2'b00: begin
                A = MAC_INA[15:0];
                B = MAC_INA[31:16];
            end
            2'b01: begin
                A = MAC_INA[15:0];
                B = MAC_INB[15:0];
            end
            2'b10: begin
                A = MAC_INA[31:16];
                B = MAC_INB[31:16];
            end
            2'b11: begin
                if (state == 2'b00) begin
                    // Primera operación con los 16 bits más bajos
                    A = MAC_INA[15:0];
                    B = MAC_INB[15:0];
                end else begin
                    // Segunda operación con los 16 bits más altos
                    A = MAC_INA[31:16];
                    B = MAC_INB[31:16];
                end
            end
            default: begin
                A = 16'd0;
                B = 16'd0;
            end
        endcase
    end

    // Lógica del MAC principal y de actualización de MAC_OUT
    always @(posedge clk) begin
        if (reset) begin
           // MAC_ACC <= 40'd0;
            MAC_OUT <= 16'd0;
            IRQ_MAC <= 1'b0;
            state <= 2'b00;
            //mac_start_latch <= 1'b0;
           // mac_done <= 1'b0;
        end else if (MAC_ON) begin
            // Detecta flanco ascendente de MAC_START
            if (MAC_START && !mac_start_latch) begin
                //mac_start_latch <= 1'b1;
                //mac_done <= 1'b0; // Reiniciar el indicador de operación completada

                // Realizar la operación MAC según el estado y el modo de entrada
                if (MAC_INPUT_MODE == 2'b11) begin
                    // Caso especial: realizar dos operaciones para el modo 11
                    if (state == 2'b00) begin
                       // MAC_ACC <= MAC_ACC + (A * B); // Primera multiplicación
                      if (bit_counter == 16)   begin
                      state <= 2'b01;               // Cambiar al segundo estado
                      end
                    end else if (state == 2'b01) begin
                        //MAC_ACC <= MAC_ACC + (A * B); // Segunda multiplicación
                      if (bit_counter == 16)   begin
                         state <= 2'b00;               // Cambiar al segundo estado
                      end              // Reiniciar el estado
                        //mac_done <= 1'b1;             // Señal de que la operación ha concluido
                    end
                end else begin
                    // Otros modos: una sola operación
                  //  MAC_ACC <= MAC_ACC + (A * B);
                   // mac_done <= 1'b1; // Señal de que la operación ha concluido
                end
           end //else if (!MAC_START) begin
                //mac_start_latch <= 1'b0;  // Reiniciar latch cuando MAC_START es 0
            //end

            // Actualización de MAC_OUT basada en MAC_SHIFTER
            case (MAC_SHIFTER)
                3'b000: MAC_OUT <= MAC_ACC[31:16];
                3'b001: MAC_OUT <= MAC_ACC[30:15];
                3'b010: MAC_OUT <= MAC_ACC[29:14];
                3'b011: MAC_OUT <= MAC_ACC[28:13];
                3'b100: MAC_OUT <= MAC_ACC[27:12];
                3'b101: MAC_OUT <= MAC_ACC[26:11];
                3'b110: MAC_OUT <= MAC_ACC[25:10];
                3'b111: MAC_OUT <= MAC_ACC[24:9];
                default: MAC_OUT <= MAC_ACC[31:16];
            endcase

            // Generación de interrupción si MAC_I_MSK está activado y la operación ha concluido
            if (MAC_I_MSK && mac_done) begin
                IRQ_MAC <= 1'b1;
            end else begin
                IRQ_MAC <= 1'b0;
            end
        end else begin
            MAC_OUT <= 16'd0;
            IRQ_MAC <= 1'b0;
        end
    end

endmodule


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
