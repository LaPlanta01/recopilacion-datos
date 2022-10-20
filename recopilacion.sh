#!/bin/bash

# METODOS Y VARIABLES
PSQL="psql --username=postgres --dbname=pacientes -t --no-align -c"

comprobarPresiones (){
	DNI_PRESIONES=$($PSQL "SELECT dni FROM presiones")

	for i in $DNI_PRESIONES
	do
		if [[ $i == $DNI ]]
		then
			PRESION=1
			echo -e "\n### Paciente con DNI:" $DNI "ya tiene registros de presiones 1er y ultimo año ###"
		fi
	done
	return $PRESION
}
comprobarDni () {
	DNI_CRONICOS=$($PSQL "SELECT dni FROM cronicos_sj")
  	read DNI

  	for i in $DNI_CRONICOS          
	do
 		if [[ $i == $DNI ]]
		then
 			echo -e "\n### Paciente con DNI:" $DNI "ya esta registrado ###" 
 		fi                             
	done
	return $DNI
}

sacarPromedio () {
	SIS=hola
	SIS1=0
	DIAS1=0
	ARG=0
	while [[ $SIS != 'alto' ]]
	do                                              
  		read -p "Sistolica: " SIS
  		SIS1=$(( $SIS1 + $SIS ))
	
	  	if [[ $SIS != 'alto' ]]
		then                      
		 	read -p "Diastolica: " DIAS
 			DIAS1=$(( $DIAS1 + $DIAS ))
 			echo ----------------------
 		fi

 		ARG=$(( $ARG + 1 ))          
	done                                 
	if [[ $SIS1 > 0 && $DIAS1 > 0 ]]
	then
 		ARG=$(( $ARG - 1 ))                  
 		PROM_SIS=$(( $SIS1 / $ARG ))         
 		PROM_DIAS=$(( $DIAS1 / $ARG )) 
                                              
 		return $PROM_SIS                     
 		return $PROM_DIAS                    
	fi
 }


echo -e "\n~~ Accion a realizar (insertar/leer/actualizar/borrar/salir) ~~\n"
read ACCION

while [[ $ACCION != 'salir' ]]
do

	if [[ $ACCION == 'borrar' ]]
	then 
		echo -e "\nDe que tabla desea borrar todos los datos?"
		read TABLA
		echo -e "\nSeguro? Se van a eliminar todos los datos de $TABLA (si/no)"
		read SEGURO
		if [[ $SEGURO == 'si' ]]
		then
			if [[ $TABLA == 'todas' ]]
			then
				BORRAR=$($PSQL "TRUNCATE TABLE cronicos_sj, tx_hta, controles_hta, imc_hta, covid_hta RESTART IDENTITY")
			else
				BORRAR=$($PSQL "TRUNCATE TABLE $TABLA RESTART IDENTITY")
			fi

			if [[ $BORRAR == 'TRUNCATE TABLE' ]]
			then
				echo -e "\nSe han eliminado los datos de la tabla '$TABLA' correctamente."
			fi
		fi

	elif [[ $ACCION == 'insertar' ]]
	then 
		CONTINUAR='si'

		while [[ $CONTINUAR != 'no' ]]
		do
			echo -e "\nEn que tabla desea insertar los datos?(cronicos_sj/tx_hta/controles_hta/imc_hta/covid_hta)"
			read TABLA

			echo -e "\nDni del paciente:"
			comprobarDni
			comprobarPresiones
			
			
			if [[ $TABLA != 'cronicos_sj' && $TABLA != 'covid_hta' && $PRESION != 1 ]]
			then
				echo -e "\n~~ Promedio tension arterial durante el 1er año ~~"
				sacarPromedio
				P_TAS_ANO_1=$PROM_SIS
				P_TAD_ANO_1=$PROM_DIAS
	
				if [[ $TABLA == 'controles_hta' || $TABLA == 'imc_hta' ]]
				then
					echo -e "\n~~ Promedio tension arterial durante el ultimo año ~~"
	                        	sacarPromedio
					P_TAS_ULT_ANO=$PROM_SIS
					P_TAD_ULT_ANO=$PROM_DIAS
				fi
			fi



			if [[ $TABLA == 'cronicos_sj' ]]
			then

				echo -e "\nAño en que nacio el paciente:"
				read ANO_NACIMIENTO
				EDAD=$(( 2022 - $ANO_NACIMIENTO ))
				EDAD=$(echo -e $EDAD | sed "s/^/'/;s/$/'/")

				echo -e "\nSexo del paciente:"
				read SEXO
				SEXO=$(echo -e $SEXO | sed "s/^/'/;s/$/'/")

				echo -e "\nFactores de riesgo:"
				read FACTORES
				FACTORES=$(echo -e $FACTORES | sed "s/^/'/;s/$/'/")

				echo -e "\nAntecedentes personales:"
				read ANTECEDENTES_P
				ANTECEDENTES_P=$(echo -e $ANTECEDENTES_P | sed "s/^/'/;s/$/'/")
				if [[ $ANTECEDENTES_P == "''" ]]
				then
					ANTECEDENTES_P=null
				fi

				echo -e "\nAntecedentes familiares:"
				read ANTECEDENTES_F
				ANTECEDENTES_F=$(echo -e $ANTECEDENTES_F | sed "s/^/'/;s/$/'/")
				if [[ $ANTECEDENTES_F == "''" ]]
				then
					ANTECEDENTES_F=null
				fi

				echo -e "\nFecha de diagnostico HTA"
				read FECHA_HTA
				FECHA_HTA=$(echo -e $FECHA_HTA | sed "s/^/'/;s/$/'/")
				if [[ $FECHA_HTA == "''" ]]
				then
					FECHA_HTA=null
				fi

				echo -e "\nFecha de diagnostico DBT"
				read FECHA_DBT
				FECHA_DBT=$(echo -e $FECHA_DBT | sed "s/^/'/;s/$/'/")
				if [[ $FECHA_DBT == "''" ]]
				then
					FECHA_DBT=null
				fi

				echo -e "\nTratamientos acutuales:"
                        	read TRATAMIENTO
                        	TRATAMIENTO=$(echo -e $TRATAMIENTO | sed "s/^/'/;s/$/'/")
                        	if [[ $TRATAMIENTO == "''" ]]
                        	then
                        	        TRATAMIENTO=null
				fi
	
				echo -e "\nControles por año:"
				read FREC_CONTROLES
				FREC_CONTROLES=$(echo -e $FREC_CONTROLES | sed "s/^/'/;s/$/'/")
	
				echo -e "\nTuvo Covid?"
				read COVID
				COVID=$(echo -e $COVID | sed "s/^/'/;s/$/'/")

				echo -e "\nTalla en mts:"
				read TALLA

				echo -e "\nPeso en kg:"
				read PESO

				IMC=$(echo "scale=2; $PESO / $TALLA ^ 2" | bc)

				INSERT_DATOS=$($PSQL "INSERT INTO cronicos_sj (edad, sexo, f_de_riesgo, antecedentes_p, antecedentes_f, fecha_dx_hta, fecha_dx_dbt, tratamiento, controles_por_año, covid, imc, dni) VALUES ($EDAD, $SEXO, $FACTORES, $ANTECEDENTES_P, $ANTECEDENTES_F, $FECHA_HTA, $FECHA_DBT, $TRATAMIENTO, $FREC_CONTROLES, $COVID, $IMC, $DNI)")
			elif [[ $TABLA == 'tx_hta' ]]
			then
				

				echo -e "\nTratamiento inicial:"
				read TX_INICIAL
				TX_INICIAL=$(echo -e $TX_INICIAL | sed "s/^/'/;s/$/'/")

				echo -e "\nTratamiento nuevo:"
				read TX_NUEVO
				TX_NUEVO=$(echo -e $TX_NUEVO | sed "s/^/'/;s/$/'/")

				echo -e "\n~~ Promedio tension arterial durante el año anterior al cambio de tratamiento ~~"
				sacarPromedio
				P_TAS_ANO_ANTES_CAMBIO=$PROM_SIS
				P_TAD_ANO_ANTES_CAMBIO=$PROM_DIAS

				echo -e "\nFecha de cambio de tratamiento:"
                                read FECHA_CAMBIO_TX
                                FECHA_CAMBIO_TX=$(echo -e $FECHA_CAMBIO_TX | sed "s/^/'/;s/$/'/")

				echo -e "\n~~ Promedio tension arterial durante el año posterior al cambio de tratamiento ~~"
				sacarPromedio
				P_TAS_ANO_DESP_CAMBIO=$PROM_SIS 	
				P_TAD_ANO_DESP_CAMBIO=$PROM_DIAS
				
				INSERT_DATOS=$($PSQL "INSERT INTO tx_hta (dni, tx_inicial, p_tas_año_1, p_tad_año_1, tx_nuevo, p_tas_año_ante_cambio, p_tad_año_ante_cambio, fecha_cambio_tx, p_tas_año_desp_cambio, p_tad_año_desp_cambio) VALUES ($DNI, $TX_INICIAL, $P_TAS_ANO_1, $P_TAD_ANO_1, $TX_NUEVO, $P_TAS_ANO_ANTES_CAMBIO, $P_TAD_ANO_ANTES_CAMBIO, $FECHA_CAMBIO_TX, $P_TAS_ANO_DESP_CAMBIO, $P_TAD_ANO_DESP_CAMBIO)")

			elif [[ $TABLA == 'controles_hta' ]]
			then

				echo -e "\nControles realizados durante el primer año posterior al diagnostico:"
                                read CONTROLES_ANO_1

				echo -e "\nControles realizados durante los 5 PRIMEROS AÑOS:"
                                read CONTROLES_5_ANOS
				if [[ $CONTROLES_5_ANOS == '' ]]
				then 
					CONTROLES_5_ANOS=null
				fi

				echo -e "\n~~ Promedio tension arterial durante los PRIMEROS 5 años POSTERIORES al diagnostico ~~"
				sacarPromedio
				P_TAS_5_ANOS=$PROM_SIS
				if [[ $P_TAS_5_ANOS == '' ]]
				then
					P_TAS_5_ANOS=null
				fi
				P_TAD_5_ANOS=$PROM_DIAS 
				if [[ $P_TAD_5_ANOS == '' ]]
				then
					P_TAD_5_ANOS=null
				fi

				echo -e "\nControles realizados durante el ULTIMO AÑO:"                   
                                read CONTROLES_ULT_ANO              

				INSERT_DATOS=$($PSQL "INSERT INTO controles_hta (dni, controles_año_1, p_tas_año_1, p_tad_año_1, con_durante_5_pri_años, p_tas_5_años, p_tad_5_años, controles_ultimo_año, p_tas_ult_año, p_tad_ult_año) VALUES ($DNI, $CONTROLES_ANO_1, $P_TAS_ANO_1, $P_TAD_ANO_1, $CONTROLES_5_ANOS, $P_TAS_5_ANOS, $P_TAD_5_ANOS, $CONTROLES_ULT_ANO, $P_TAS_ULT_ANO, $P_TAD_ULT_ANO)")

			elif [[ $TABLA == 'imc_hta' ]]
			then

				echo -e "\nTalla en mts (con .):"                                                            
				read TALLA

				echo -e "\nPeso inicial en kg:"
				read PESO_INICIAL
				IMC_INICIAL=$(echo "scale=2; $PESO_INICIAL / $TALLA ^ 2" | bc)

				echo -e "\nPeso durante el 3er año POSTERIOR a su diagnostico:"                   
                                read PESO_ANO_3              
				IMC_ANO_3=$(echo "scale=2; $PESO_ANO_3 / $TALLA ^ 2" | bc)
				if [[ $IMC_ANO_3 == "''" ]]
				then
					IMC_ANO_3=null
				fi

				echo -e "\n~~ Promedio tension arterial durante el 3er año POSTERIOR al diagnostico ~~"
				sacarPromedio
				P_TAS_ANO_3=$PROM_SIS 
				if [[ $P_TAS_ANO_3 == "''" ]]
				then
					P_TAS_ANO_3=null
				fi

				P_TAD_ANO_3=$PROM_DIAS
				if [[ $P_TAD_ANO_3 == "''" ]]
				then
					P_TAD_ANO_3=null
				fi

				echo -e "\nPeso del ultimo año:"                   
                                read PESO_ULT_ANO             
                                IMC_ULT_ANO=$(echo "scale=2; $PESO_ULT_ANO / $TALLA ^ 2" | bc) 

				INSERT_DATOS=$($PSQL "INSERT INTO imc_hta (dni, imc_inicial, p_tas_año_1, p_tad_año_1, imc_año_3, p_tas_año_3, p_tad_año_3, imc_actual, p_tas_ult_año, p_tad_ult_año) VALUES ($DNI, $IMC_INICIAL, $P_TAS_ANO_1, $P_TAD_ANO_1, $IMC_ANO_3, $P_TAS_ANO_3, $P_TAD_ANO_3, $IMC_ULT_ANO, $P_TAS_ULT_ANO, $P_TAD_ULT_ANO)")
			
			elif [[ $TABLA == 'covid_hta' ]]
			then
				echo -e "\nFecha de diagnostico de COVID (dd-mm-aaaa):"
				read FECHA_COVID
				FECHA_COVID=$(echo -e $FECHA_COVID | sed "s/^/'/;s/$/'/")

				echo -e "\n~~ Promedio tension arterial durante el año ANTERIOR al diagnostico covid ~~"
				sacarPromedio
				P_TAS_ANO_ANT=$PROM_SIS 
				P_TAD_ANO_ANT=$PROM_DIAS

				echo -e "\n~~ Promedio tension arterial durante el año POSTERIOR al diagnostico covid ~~"
				sacarPromedio
				P_TAS_ANO_DESP=$PROM_SIS
				P_TAD_ANO_DESP=$PROM_DIAS

				echo -e "\n~~ Promedio tension arterial durante los ULTIMOS 6 MESES ~~"
				sacarPromedio
				P_TAS_ULT_6_MESES=$PROM_SIS
				P_TAD_ULT_6_MESES=$PROM_DIAS

				INSERT_DATOS=$($PSQL "INSERT INTO covid_hta (dni, fecha_dx_covid, p_tas_año_ant, p_tad_año_ant, p_tas_año_desp, p_tad_año_desp, p_tas_ult_6_meses, p_tad_ult_6_meses) VALUES ($DNI, $FECHA_COVID, $P_TAS_ANO_ANT, $P_TAD_ANO_ANT, $P_TAS_ANO_DESP, $P_TAD_ANO_DESP, $P_TAS_ULT_6_MESES, $P_TAD_ULT_6_MESES)")

			fi


			if [[ $INSERT_DATOS =~ INSERT.* ]]
			then
				echo -e "\n~~ Datos insertados correctamente ~~"	
			fi

			echo -e "\nContinuar?(si/no)"
			read CONTINUAR 
		done

	elif [[ $ACCION == 'leer' ]]
	then
		CONTINUAR='si'

		while [[ $CONTINUAR != 'no' ]]
		do
			echo -e "\nQue tabla desea leer?"
			read TABLA
	
			echo -e "\nQue columna desea leer?(como aparece en la tabla y separadas por coma/todas)"
			read COLUMNA

			echo -e "\nCondicion?(si/no):" 
			read CONDICION 

			if [[ $CONDICION == 'no' ]] 
			then
				if [[ $COLUMNA == 'todas' ]]
				then
					CONSULTA=$($PSQL "SELECT * FROM $TABLA") 
				else
					CONSULTA=$($PSQL "SELECT $COLUMNA FROM $TABLA")
				fi
			elif [[ $COLUMNA == 'todas' ]]
			then
				echo -e "\nColumna de la condicion (como aparece en la tabla):"
				read COLUMNA_COND	

				echo -e "\nComparacion de la condicion(=/!=/</etc.):" 
				read SIGNO	

				echo -e "\nValor de la condicion:"
				read VALOR_COND

				CONSULTA=$($PSQL "SELECT * FROM $TABLA WHERE $COLUMNA_COND $SIGNO '$VALOR_COND'") 
			else 
				echo -e "\nColumna de la condicion (como aparece en la tabla):"
                                read COLUMNA_COND       
  
                                echo -e "\nComparacion de la condicion(=/!=/</etc.):" 
                                read SIGNO
                                  
                                echo -e "\nValor de la condicion:"
                                read VALOR_COND

				CONSULTA=$($PSQL "SELECT $COLUMNA FROM $TABLA WHERE $COLUMNA_COND $SIGNO '$VALOR_COND'")

			fi

			echo $CONSULTA

			echo -e "\nContinuar(si/no)"
			read CONTINUAR
		done

	fi
	
	if [[ $ACCION == 'actualizar' ]]
	then
		CONTINUAR='si'	
		
		while [[ $CONTINUAR != 'no' ]]
		do
			echo -e "\nQue tabla desea actualizar?"
			read TABLA

			echo -e "\nQue columna desea actualizar?"
			read COLUMNA

			echo -e "\nInserte el ID del paciente"
			read ID

			echo -e "\nValor a insertar:"
			read VALOR

			ACTUALIZAR=$($PSQL "UPDATE $TABLA SET $COLUMNA = '$VALOR' WHERE patient_id = $ID") 

			if [[ $ACTUALIZAR =~ UPDATE.* ]]
			then
				echo -e "\nSe actualizo la columna '$COLUMNA' con el valor '$VALOR' en la tabla '$TABLA' del paciente numero '$ID' con exito."
			fi

			echo -e "\nContinuar?(si/no)"
			read CONTINUAR 
		done
	fi	

	echo -e "\n~~ Accion a realizar (insertar/leer/actualizar/borrar/salir) ~~"
	read ACCION
done






