# TP1-Taller

## Compilación

1. Entrar a la carpeta ledger: ```cd ledger```

2. Compilar el proyecto: ```mix compile```

3. Crear el ejecutable hacer: ```mix escript.build```

4. Ejecutar las funciones disponibles :
- ```./ledger transacciones [flags]```
- ```./ledger balance [flags]```

Por ejemplo: 
- ```./ledger transacciones -t=transacciones.csv -c1=userA -c2=userB -o=salida.csv```
- ```./ledger balance -c1=userA -m=USDT -o=balance.csv```

4. Para ejecutar los test: ```mix test```

    Aclaracion: Se instalo una dependencia para ver la cobertura de los test:

    Se debe ejercutar: ```mix coveralls```
   


## Manejo de Errores en Transferencia

Se tomaron desiciones para los distintos manejos de errores:

- Se detecta lineas mal formateadas en el csv:

    ejemplo: 
    - 1;1006751404;USDT;;20000.00;userA;;alta_cuenta;

    Aca tiene mas de 8 parametros, por lo que va a dar error.

- Se valida el tipo de transaccioón, si hay una transacción distinta de transferencia, swap, alta_cuenta dara error:
    
    - ejemplo: 1;1022751404;USDT;;20000.00;userA;;sumar_moneda

- Se valida si el monto a transaferir es negativo o cero, por lo contrario dara error:

    ejemplo: 
    - 1;1754937004;USDT;USDT;-100.50;userA;userB;transferencia
    - 4;8854937004;USDT;USDT;0.00;userA;userB;transferencia

- Se valida que la moneda origen o moneda destina sean validas, es decir, que esten en el csv de monedas,por lo contrario dara error:
    
    ejemplo: 
    - 1;1754937004;USDT;DOG;100.50;userA;userB;transferencia
    - 2;11754937004;BTTC;USDT;100.50;userA;userB;transferencia

- Se valida que el tipo transferencia tenga una cuenta origen y cuenta destino, por lo contrario dara error:

    ejemplo: 
    - 1;1754937004;USDT;USDT;100.50;;userB;transferencia
    - 2;11754937004;USDT;USDT;100.50;userA;;transferencia

- Se valida que el tipo swap tenga cuenta origen y moneda destino, por lo contrario dara error:

    ejemplo: 
    - 2;1993418041;USDT;;11000.00;userA;;swap
    - 6;1755541804;BTC;USDT;0.1;;;swap

- Se valida que una cuenta no dada de alta no puede hacer transacciones:
    ejemplo:
    - 1;1006751404;USDT;;20000.00;userA;;alta_cuenta
    - 2;1993418041;USDT;BTC;11000.00;userA;;swap
    - 3,4651623000;USDT;USDT;1000.00,userB;userA;transferencia

    La cuenta `userB` no esta dada de alta por lo que dara error

- Si los usuarios no existen al momento de indicar las flags `-c1` o `-c2` dara error:
    ejemplo:
    - ```./ledger transacciones -t=transacciones.csv -c1=userA -c2=user123 -o=salida.csv```
      
      user123 no existe por que dara error: "Error: No se encontraron transacciones que coincidan con los filtros"

## Manejo de Errores en Balance

- Si no se especifica la flag `-c1` dara error:

    - ```./ledger balance ```
    
    Esto dara : "Error: Debe especificarse el flag -c1"

- Si hay errores en las transacciones, el calculo de balance no se ejecuta

- Si la flag `-m` tiene una moneda invalida, dara error








