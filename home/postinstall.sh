#!/bin/bash

# Tworzenie tymczasowego folderu do pobrania repozytorium
TEMP_DIR=$(mktemp -d)

# Klonowanie repozytorium GitHub do tymczasowego folderu
git clone https://github.com/SpurtechEngineering/Dash.git "$TEMP_DIR"

# Sprawdzenie, czy operacja klonowania się powiodła
if [ $? -eq 0 ]; then
    echo "Pobieranie repozytorium zakończone sukcesem."
else
    echo "Błąd podczas pobierania repozytorium." >&2
    exit 1
fi

# Przeniesienie pobranych plików do folderu docelowego
TARGET_DIR="/pi/home"
mv "$TEMP_DIR"/* "$TARGET_DIR"

# Sprawdzenie, czy operacja przenoszenia się powiodła
if [ $? -eq 0 ]; then
    echo "Pliki zostały przeniesione do folderu $TARGET_DIR."
else
    echo "Błąd podczas przenoszenia plików." >&2
    exit 1
fi

# Usunięcie tymczasowego folderu
rm -rf "$TEMP_DIR"

#Install Realdash
sudo dpkg -i *.deb
sudo apt-get -f install -y
sudo apt-get kdialog -y
sudo apt --fix-broken install



