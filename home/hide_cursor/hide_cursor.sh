#!/bin/bash

# Œcie¿ka do pliku konfiguracji
CONFIG_FILE="/etc/hide_cursor_config"

# Utwórz plik konfiguracji, jeœli nie istnieje
if [ ! -f "$CONFIG_FILE" ]; then
    echo "DELAY=10" > "$CONFIG_FILE"
fi

# G³ówna funkcja
hide_cursor() {
    local prev_delay=0

    while true; do
        # Za³aduj opóŸnienie z pliku konfiguracji
        source "$CONFIG_FILE"

        # SprawdŸ, czy opóŸnienie zosta³o zmienione
        if [ "$prev_delay" -ne "$DELAY" ]; then
            echo "Zaktualizowano opóŸnienie na $DELAY sekund."
            prev_delay=$DELAY
        fi

        IDLE_TIME=$(xprintidle) # Wymaga pakietu 'xprintidle'

        if [ "$IDLE_TIME" -ge "$((DELAY * 1000))" ]; then
            # Ukryj kursor
            unclutter -idle 0.1 -root & # Wymaga pakietu 'unclutter'
        else
            # Zakoñcz proces unclutter, jeœli kursor zostanie poruszony
            pkill unclutter
        fi
        sleep 1
    done
}

# Uruchomienie funkcji
hide_cursor