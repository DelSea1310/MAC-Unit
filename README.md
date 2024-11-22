Proyecto: Diseño de un Microprocesador con RISC-V

El proyecto se centra en el diseño de un microprocesador basado en la arquitectura RISC-V, y uno de los módulos principales es el Multiply-Accumulate (MAC) Unit. Este módulo desempeña un papel crucial al realizar operaciones de multiplicación y acumulación, fundamentales en diversos cálculos aritméticos. Su funcionamiento se basa en multiplicar dos registros, extraídos de registros más grandes denominados MAC_INA y MAC_INB, según el modo de entrada configurado (MAC_INPUT_MODE). Posteriormente, los resultados de esta multiplicación se suman con el valor acumulado actual (MAC_ACC) del módulo, y el resultado final se envía a la salida (MAC_OUT). 

El valor de MAC_OUT se obtiene tomando los bits [31:16] del acumulado (MAC_ACC). Sin embargo, si el registro de desplazamiento (MAC_SHIFTER) contiene un valor específico, la salida será desplazada hacia la izquierda hasta alcanzar un máximo definido en los bits [24:9] del acumulado. Cabe destacar que el módulo solo inicia la multiplicación cuando el bit de inicio (MAC_START) está activado (en 1). Mientras este bit permanezca desactivado (0), el módulo estará inactivo. Una vez activado, ejecutará la operación y se bloqueará hasta recibir una nueva instrucción. Además, si el bit MAC_I_MSK está activo, el módulo enviará una interrupción al usuario para notificar la finalización de la operación. Por último, si el bit de encendido (MAC_ON) no está en 1, el módulo permanecerá apagado.

![image alt](https://drive.google.com/file/d/1_srFWBWl9kfJeGSkfZ6Dztm20vS-jZ4I/view?usp=drive_link)
![image alt](https://drive.google.com/file/d/1_vFxtTHUk_yZm5k5P_Hkz_te0_Bbcdwo/view?usp=drive_link)
![image alt](https://drive.google.com/file/d/1_vOolHD9m0_w-UgA7Rt80xSJk0iVyDVJ/view?usp=drive_link)

Diagrama de bloques del diseño

Para entender mejor el diseño, se desarrolló un diagrama de bloques que representa de forma visual la estructura del módulo. Este diagrama puede visualizarse descargando el archivo "diagramaMAC.drawio" y abriéndolo en la página web [https://www.drawio.com](https://www.drawio.com).

Elementos terminados y pendientes

En cuanto a los avances realizados, se completaron la mayoría de los elementos del módulo. Entre los logros principales se encuentra la implementación de la multiplicación sin utilizar el operador "*", empleando técnicas de desplazamiento y suma. Asimismo, se configuró exitosamente la interfaz del módulo, se implementó el reset sincrónico, y se garantizó el correcto funcionamiento de MAC_START, que permite iniciar y finalizar las operaciones de manera controlada. Además, los cambios realizados en MAC_SHIFTER se reflejan correctamente en la salida (MAC_OUT), y dependiendo del modo de entrada (MAC_INPUT_MODE), se seleccionan adecuadamente los bits más o menos significativos de MAC_INA y MAC_INB para asignarlos a los registros internos A y B. Otro punto destacado es la funcionalidad de la máscara de interrupción (MAC_I_MSK), que permite notificar al usuario cuando la operación ha finalizado.

Sin embargo, algunos aspectos quedaron pendientes. No fue posible implementar la multiplicación con signos debido a las limitaciones al evitar el uso del operador "*", lo que ocasionaba fallos en los cálculos. También, en el modo [1 1], no se logró implementar la doble multiplicación requerida, logrando únicamente la ejecución de la primera operación.

Vista RTL del diseño

Tras realizar la implementación utilizando el lenguaje de descripción de hardware Verilog, se generó la vista RTL del diseño. Esta representación gráfica detalla los componentes y las conexiones entre ellos, constituyendo un paso clave para validar tanto la estructura como la funcionalidad del sistema antes de avanzar hacia las etapas de síntesis y diseño físico (layout). 


IMAGEN AQUI

Diagramas de tiempo de los módulos

Se desarrollaron múltiples módulos testbench para evaluar diferentes casos y configuraciones. El proyecto incluye tres módulos principales: 

- mac_interface: Es el módulo principal encargado de la comunicación entre los componentes. 
- mac: En este módulo se definen y analizan las variables y condiciones específicas para el funcionamiento del sistema. 
- product: Aquí se realiza la multiplicación utilizando sumas y desplazamientos en lugar del operador "*".

Testbench del módulo product

Se implementó un testbench para verificar el correcto funcionamiento de la multiplicación. 

IMAGNE AQUI

En este testbench, las entradas A y B se configuran con valores en decimal: 33.333 y 55.555, respectivamente. Al activar MAC_START, se inicia el proceso matemático. El latch mac_start_latch se activa, permitiendo que el contador de bits (bit_counter) incremente hasta alcanzar 16. En ese momento, se activa la señal mac_done, bloqueando el ciclo de multiplicación y reflejando el cambio en el acumulado (MAC_ACC). Si MAC_START se desactiva, el latch correspondiente se apaga. Al activarlo nuevamente, el proceso se reinicia, comenzando una nueva multiplicación.

**Testbench del módulo MAC con input_mode [0 0]**

En este testbench se evalúa el funcionamiento del modo [0 0], donde A se asigna a los 16 bits menos significativos de MAC_INA y B a los 16 bits más significativos del mismo registro. En este modo, MAC_INB es insignificante y no se utiliza en la operación.

**IMAGEN AQUÍ**

Como se observa en la imagen, los valores decimales de los bits seleccionados de MAC_INA son 55.555 y 22.222. Estos se multiplican entre sí, y tras 19 ciclos de reloj, el resultado aparece en MAC_OUT. Además, el registro MAC_CTRL muestra que la posición 0 está en 1, lo que indica que se ha activado la notificación al usuario una vez que la operación ha finalizado.

**Testbench del módulo MAC con input_mode [0 1]**

Este testbench evalúa el modo [0 1], en el que A se asigna a los 16 bits menos significativos de MAC_INA, mientras que B se asigna a los 16 bits menos significativos de MAC_INB.

**IMAGEN AQUÍ**

Como se puede observar en la imagen, los valores decimales de los bits menos significativos de ambos registros son 33.333 y 55.555, respectivamente. Estos se multiplican entre sí, y el resultado aparece en MAC_OUT después de 19 ciclos de reloj. También se puede notar que el registro MAC_SHIFTER está configurado como [0 1 0], lo que indica que la salida se desplazará dos bits hacia la izquierda antes de ser entregada.

**Testbench del módulo MAC con input_mode [1 0]**

Este testbench valida el funcionamiento del modo [1 0], donde A se asigna a los 16 bits más significativos de MAC_INA y B a los 16 bits más significativos de MAC_INB.

**IMAGEN AQUÍ**

Como se observa en la imagen, los valores decimales de los bits más significativos de ambos registros son 22.222. Estos se multiplican entre sí y el resultado aparece en MAC_OUT tras 19 ciclos de reloj. En este caso, MAC_CTRL en la posición 0 está en 0, lo que indica que no se activó la notificación al usuario al actualizar la salida.

**Testbench del módulo MAC con input_mode [1 1]**

En este testbench se evalúa el modo [1 1], donde los 16 bits menos significativos de ambos registros se asignan a A y B, y se realiza una primera multiplicación. Luego, los 16 bits más significativos de los registros se asignan nuevamente a A y B para realizar una segunda multiplicación, cuyo resultado se suma al de la primera.

**IMAGEN AQUÍ**

Sin embargo, en este modo, la segunda multiplicación no se pudo realizar. Por lo tanto, el resultado obtenido corresponde únicamente al producto de los 16 bits menos significativos de cada registro.

**Testbench del módulo MAC comprobando el acumulador**

En este testbench se utilizan los modos [0 1] y [1 0] para comprobar que, al realizar dos multiplicaciones, los resultados se sumen correctamente en el acumulador MAC_ACC.

**IMAGEN AQUÍ**

Como se observa en la imagen, se realiza la primera multiplicación utilizando el modo [0 1], donde los valores decimales correspondientes son 33.333 y 55.555. El resultado se almacena en MAC_ACC. Posteriormente, se desactiva y reactiva MAC_START para iniciar una nueva operación en el modo [1 0]. En esta segunda operación, ambos registros tienen un valor decimal de 22.222, y el resultado de la multiplicación se suma al acumulado previo, reflejando el funcionamiento esperado. Además en la primera multiplicación se activo la mascara para notificar el usuario, caso contrario en la segunda multiplicación.

**Testbench del módulo mac_interface**

En este testbench se evalúa el funcionamiento de la interfaz, probando la escritura y lectura en las direcciones correspondientes de los registros MAC_INA, MAC_INB y MAC_CTRL.

IMAGEN AQUÍ

Como se observa en la imagen, las direcciones se cambian para configurar los registros. Durante la escritura, la señal write_enable está activa en el flanco del reloj. Después de 19 ciclos de reloj, se desactiva write_enable para permitir la lectura de las salidas MAC_ACCH, MAC_ACCL y MAC_OUT. En la imagen se puede ver el estado de cada bit, mostrando cómo se configura y procesa la información correctamente.


Caracterización de área y temporización del chip:

El análisis de temporización realizado sobre el diseño confirma que todas las restricciones establecidas se cumplen satisfactoriamente. Para el tiempo de setup, el slack más pequeño registrado es de 3.46 ns, lo que asegura que todas las señales llegan a tiempo para ser configuradas adecuadamente, sin fallas en los 223 endpoints evaluados. En cuanto al tiempo de hold, el slack mínimo alcanzado es de 0.129 ns, garantizando la estabilidad necesaria de las señales durante el periodo requerido, también sin endpoints fallidos. Respecto al ancho de pulso, el peor slack observado es de 4.045 ns, lo que certifica que las señales mantienen la duración adecuada sin inconvenientes en los 202 endpoints revisados. En conclusión, el diseño cumple todas las restricciones de temporización, demostrando su solidez y correcta implementación.

IMAGEN AQUI

Se llevó a cabo una síntesis con el objetivo de optimizar la configuración del diseño, priorizando una reducción en el tamaño ocupado y logrando tiempos de slack más eficientes.

IMAGEN AQUI

Con la tabla resultante se puede observar que el único con un worst setup slack (ns) positivo es el del área 3, esto produce que el área selecionada para el .json sea el área 3 , posteriormente se abre MAGIC para ver la imagen de layout final 

IMAGEN AQUI 

Para poder ver la caracterización del área se media la distancia total ocupada por las celdas obteniendo el resultado en la terminal.

IMAGEN AQUI

