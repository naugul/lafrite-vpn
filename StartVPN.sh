#!/bin/bash

echo ""
echo "Verificando servicios..."
echo ""

maxtries=5
count=1

strongswan="up"
while [[ $strongswan = "up" && $count != $maxtries ]]
do
if [[ $(ps -ef | grep -v grep | grep ipsec | wc -l) > 0 ]]
then 
  echo "  Servicio Strongswan corriendo. Tratando de detener..."
  service ipsec stop
  sleep 2s
  count=$((count+1))
else
  echo "  Strongswan detenido..."
  strongswan="down"
  count=1
fi
done

xl2tpd="up"
while [[ $xl2tpd = "up" && $count != $maxtries ]]
do
if [[ $(ps -ef | grep -v grep | grep xl2tpd | wc -l) > 0 ]]
then 
  echo "  Servicio xl2tpd corriendo. Tratando de detener..."
  service xl2tpd stop
  sleep 2s
  count=$((count+1))
else
  echo "  xl2tpd detenido..."
  xl2tpd="down"
  count=1
fi
done

echo ""
echo "Iniciando servicios..."
echo ""

count=1
while [[ $strongswan = "down" && $count != $maxtries ]]
do
  service ipsec start
  sleep 2s
  if [[ $(ps -ef | grep -v grep | grep ipsec | wc -l) > 0 ]]
  then
    strongswan="up"
    count=1
    echo "  Strongswan iniciado..."
  else
    count=$((count+1))
    echo "  Error al iniciar Strongswan, reintentando..."
  fi
done

while [[ $xl2tpd = "down" && $count != $maxtries ]]
do
  service xl2tpd start
  sleep 2s
  if [[ $(ps -ef | grep -v grep | grep xl2tpd | wc -l) > 0 ]]
  then
    xl2tpd="up"
    count=1
    echo "  xl2tpd iniciado..."
  else
    count=$((count+1))
    echo "  Error al iniciar xl2tpd, reintentando..."
  fi
done

echo ""
echo "Levantando IPSec y PPP..."
echo ""

if [[ $xl2tpd = "up" && $strongswan = "up" ]]
then
  count=1
  ipsecerror=1
  while [[ $ipsecerror = "1" && $count != $maxtries ]]
  do
  ipsec up remicoop
  sleep 2s
  if [[ $(ipsec status | grep up | wc -l) > 0 ]]
  then
    echo ""
    echo "  IPSec operativo, discando..."
    ipsecerror=0
    ppperror=1
    count=1
    while [[ $ppperror = "1" && $count != $maxtries ]]
    do
    echo "c remicoop" > /var/run/xl2tpd/l2tp-control
    sleep 2s
    if [[ $(ip route | grep ppp | wc -l) > 0 ]]
    then
      ppperror=0
      count=1
      if [[ $(ip route | grep 192.168.20.0 | wc -l) > 0  ]]
      then
        echo "    Usuario aceptado, ruta existente..."
      else
        ip route add 192.168.20.0/24 dev ppp0
        echo "    Usuario aceptado, ruta cargada..."
      fi
      if [[ $(ping -c 1 192.168.20.100 | grep received | wc -l) > 0 ]]
      then
        ip=$(ip route | grep ppp0 | sed -n 's/.*src //p')
        echo "      Ping satisfactorio."
        echo ""
        echo "VPN operativa. IP de este equipo: "$ip
        echo ""
      else
        echo "      Error al cargar la ruta... Raro..."
      fi
    else
      echo "  Error al discar, reintentado..."
      ppperror=1
      count=$((count+1))
    fi
    done
  else
    echo ""
    echo "Error en el tunel... Reintentando en 5 segundos."
    echo ""
    ipsecerror=1
    count=$((count+1))
    sleep 5s
  fi
  done
else
  echo ""
  echo "Hubo un error con los servicios... Reintentando en 5 segundos."
  echo ""
  error=1
fi

