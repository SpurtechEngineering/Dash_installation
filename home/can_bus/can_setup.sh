#!/bin/bash

# Sprawdzanie uprawnień root
if [ "$EUID" -ne 0 ]; then
  echo "Uruchom ten skrypt jako root lub za pomocą sudo."
  exit 1
fi

# Wczytywanie pliku konfiguracyjnego
CONFIG_FILE="can_config.cfg"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Plik konfiguracyjny $CONFIG_FILE nie istnieje. Utwórz go przed uruchomieniem."
  exit 1
fi

source "$CONFIG_FILE"

# Edycja pliku /boot/config.txt
BOOT_CONFIG="/boot/config.txt"
echo "Dodawanie konfiguracji do $BOOT_CONFIG..."

if ! grep -q "dtparam=spi=on" $BOOT_CONFIG; then
  echo "dtparam=spi=on" >> $BOOT_CONFIG
fi

if ! grep -q "dtoverlay=mcp2515-can0,oscillator=16000000,interrupt=25" $BOOT_CONFIG; then
  echo "dtoverlay=mcp2515-can0,oscillator=16000000,interrupt=25" >> $BOOT_CONFIG
fi

if ! grep -q "dtoverlay=spi-bcm2835-overlay" $BOOT_CONFIG; then
  echo "dtoverlay=spi-bcm2835-overlay" >> $BOOT_CONFIG
fi

echo "Konfiguracja $BOOT_CONFIG zakończona."

# Instalowanie narzędzi CAN, jeśli nie są zainstalowane
echo "Sprawdzanie obecności can-utils..."
if ! dpkg -l | grep -qw can-utils; then
  echo "Instalowanie can-utils..."
  apt update && apt install -y can-utils
else
  echo "can-utils jest już zainstalowane."
fi

# Ustawienie interfejsu can0 na podstawie pliku konfiguracyjnego
echo "Konfigurowanie interfejsu can0 z prędkością $CAN_BITRATE bps..."
ip link set can0 up type can bitrate "$CAN_BITRATE"

if [ $? -eq 0 ]; then
  echo "Interfejs can0 został poprawnie skonfigurowany."
else
  echo "Błąd podczas konfiguracji interfejsu can0." >&2
  exit 1
fi

# Sprawdzenie statusu
echo "Sprawdzanie logów dmesg dla interfejsu CAN..."
dmesg | grep -i can

echo "Konfiguracja CAN bus zakończona. Uruchom Raspberry Pi ponownie, aby zmiany w pliku config.txt zostały wprowadzone."
