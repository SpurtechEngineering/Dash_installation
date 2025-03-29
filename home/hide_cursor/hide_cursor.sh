#!/bin/bash

# �cie�ka do pliku konfiguracji
CONFIG_FILE="/etc/hide_cursor_config"

# Utw�rz plik konfiguracji, je�li nie istnieje
if [ ! -f "$CONFIG_FILE" ]; then
    echo "DELAY=10" > "$CONFIG_FILE"
fi

# G��wna funkcja
hide_cursor() {
    local prev_delay=0

    while true; do
        # Za�aduj op�nienie z pliku konfiguracji
        source "$CONFIG_FILE"

        # Sprawd�, czy op�nienie zosta�o zmienione
        if [ "$prev_delay" -ne "$DELAY" ]; then
            echo "Zaktualizowano op�nienie na $DELAY sekund."
            prev_delay=$DELAY
        fi

        IDLE_TIME=$(xprintidle) # Wymaga pakietu 'xprintidle'

        if [ "$IDLE_TIME" -ge "$((DELAY * 1000))" ]; then
            # Ukryj kursor
            unclutter -idle 0.1 -root & # Wymaga pakietu 'unclutter'
        else
            # Zako�cz proces unclutter, je�li kursor zostanie poruszony
            pkill unclutter
        fi
        sleep 1
    done
}

# Uruchomienie funkcji
hide_cursor