# TP2-Taller

## Compilación

1. Entrar a la carpeta del proyecto: ```cd ledger```

2. Levantar Docker: ```make db```

3. Compilar el Proyecto: ```make compile```

4. Crear la base de datos y ejecutar las migraciones:  ```make setup```

    Este comando también ejecutará el archivo seeds.exs, que cargará datos iniciales en la base de datos para poder probar los comandos.
    Además dejara el entorno preparado para ejecutar los tests posteriormente

5. Ejecutar los tests: ```make test```

    Aclaración: Se utilizo Ecto Sandbox para garantizar que los tests no afecten a otros tests ni a los datos reales de la base de datos

## Errores Manejados

- **Usuarios:**
    - El usuario debe ser mayor a 18 años.
    - El nombre de usuario es obligatorio.
    - La fecha de nacimiento es obligatoria.
    - Al editar, el nuevo nombre debe ser distinto al anterior.
    - No se puede borrar un usuario con transacciones asociadas.
    - No se puede ver un usuario que no existe (ID inexistente)
    - El ID debe ser un número válido(no se aceptan cadenas u otros formatos).
    - Debe indicarse el flag ```-id=<id>``` en las operaciones que los requieran(ver,editar,borrar)
    - La fecha de nacimiento debe tener un formato válido(YYYY-MM-DD).

- **Monedas:**
    - El nombre de la moneda es obligatorio.
    - El nombre debe estar en mayúsculas y tener 3 a 4 letras.
    - El nombre de la moneda debe ser único(no puede repetirse en la base de datos)
    - El precio en dólares es obligatorio al crear una moneda.
    - El precio en dólares no puede ser negativo.
    - Al editar, el ```precio_dolares``` debe ser un número válido y no negativo.
    - No se puede borrar una moneda con transacciones asociadas.
    - No se puede ver una moneda que no existe(ID inexistente).
    - Debe indicarse el flag ```-id=<id>``` en las operaciones que lo requieran(ver, editar, borrar).
    - Debe indicarse el flag ```-p=<precio>``` al crear/editar cuando se quiere setear el precio.

- **Transacciones:**
    - El monto es obligatorio y debe ser mayor a 0.
    - No se puede dar de alta una cuenta que ya fue creada para el mismo usuario y moneda.
    - En un swap, la moneda de origen y destino no pueden ser la misma.
    - Los usuarios y monedas deben existir previamente.
    - La cuenta del usuario debe estar dada de alta para la moneda antes de usarla en transferencias o swaps.
    - No se puede deshacer una transacción inexistente.
    - Solo puede deshacerse la última transacción de cada cuenta involucrada.
    - No se puede ver una transacción que no existe(ID inexistente).
    - El ID debe ser un número válido.
    - Debe indicarse el flag ```-id=<id>``` en las operaciones que lo requieran(ver, deshacer).
    - Debe indicarse el flag ```-a=<monto>``` en las operaciones que lo requieran(alta_cuenta, transferencia, swap).

## Aclaraciones

- Para los comandos del TP1 tanto para el de transacciones y balance sigue funcionando todo igual, con la difencia de que si no se especifica la flag ```-t=<archivo>``` la información la toma de la base de datos.
    - ```./ledger balance -c1=<id-usuario>```
    - ```./ledger transacciones -c1=<id-usuario> -c2=<id-usuario>```


# TP1-Taller

## Compilación

1. Entrar a la carpeta ledger: ```cd ledger```

2. Compilar el proyecto: ```mix compile```

3. Crear el ejecutable: ```mix escript.build```

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

- Se valida que la moneda origen o moneda destina sean validas, es decir, que esten en el csv de monedas:
    
    ejemplo: 
    - 1;1754937004;USDT;DOG;100.50;userA;userB;transferencia
    - 2;11754937004;BTTC;USDT;100.50;userA;userB;transferencia

    DOG y BTTC no se encuentra en el csv de monedas por lo que dara error

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
      
      user123 no existe, por lo que dara error: "Error: No se encontraron transacciones que coincidan con los filtros"

## Manejo de Errores en Balance

- Si no se especifica la flag `-c1` dara error:

    - ```./ledger balance ```
    
    Esto dara : "Error: Debe especificarse el flag -c1"

- Si hay errores en las transacciones, el calculo de balance no se ejecuta

- Si la flag `-m` tiene una moneda invalida que no esta en el csv de monedas, dara error








