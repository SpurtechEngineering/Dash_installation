#include <pigpio.h>
#include <iostream>
#include <vector>
#include <tuple>
#include <fstream>
#include <sstream>
#include <string>
#include <stdexcept>

#define PIN 6 // GPIO pin dla NeoPixel
#define NUMPIXELS 16 // Liczba LED
std::vector<std::tuple<int, int, int>> tachColor(NUMPIXELS);
std::vector<unsigned int> lightShiftFreq(NUMPIXELS);

const unsigned int onFrequency = 700;
const unsigned int minFrequency = 6500;
const unsigned int maxFrequency = 9100;
const unsigned int shiftFrequency = 9300;
const unsigned int flashtimer = 20;

bool hasStartupSequenceRun = false;
const int tachPin = 2;
unsigned long igfreq = 0;

// Funkcja do wczytywania danych z pliku
void loadTachColor(const std::string& filePath) {
    std::ifstream file(filePath);
    if (!file.is_open()) {
        throw std::runtime_error("Nie można otworzyć pliku: " + filePath);
    }

    for (int i = 0; i < NUMPIXELS; ++i) {
        int r, g, b;
        file >> r >> g >> b;
        tachColor[i] = std::make_tuple(r, g, b);
    }

    file.close();
}

void loadLightShiftFreq(const std::string& filePath) {
    std::ifstream file(filePath);
    if (!file.is_open()) {
        throw std::runtime_error("Nie można otworzyć pliku: " + filePath);
    }

    for (int i = 0; i < NUMPIXELS; ++i) {
        unsigned int freq;
        file >> freq;
        lightShiftFreq[i] = freq;
    }

    file.close();
}

void showPixels(const std::vector<std::tuple<int, int, int>>& colors) {
    for (int i = 0; i < NUMPIXELS; i++) {
        auto [r, g, b] = colors[i];
        std::cout << "Pixel " << i << " Color: (" << r << ", " << g << ", " << b << ")" << std::endl;
    }
}

unsigned long measurePulse(int pin) {
    gpioSetMode(pin, PI_INPUT);
    unsigned long startTick = gpioTick();
    while (gpioRead(pin) == 0);
    while (gpioRead(pin) == 1);
    return gpioTick() - startTick;
}

void setup() {
    if (gpioInitialise() < 0) {
        std::cerr << "Błąd inicjalizacji GPIO." << std::endl;
        exit(1);
    }

    try {
        loadTachColor("tachColor.txt");
        loadLightShiftFreq("lightShiftFreq.txt");
    } catch (const std::runtime_error& e) {
        std::cerr << e.what() << std::endl;
        exit(1);
    }
}

void loop() {
    unsigned long ighigh = measurePulse(tachPin);
    unsigned long iglow = measurePulse(tachPin);
    unsigned long igcal1 = 1000000 / (ighigh + iglow);

    ighigh = measurePulse(tachPin);
    iglow = measurePulse(tachPin);
    unsigned long igcal2 = 1000000 / (ighigh + iglow);

    if (abs((int)(igcal1 - igcal2)) < 3) {
        igfreq = (igcal1 + igcal2) / 2;
    }

    if (!hasStartupSequenceRun && igfreq > onFrequency) {
        for (int i = NUMPIXELS - 1; i >= 0; --i) {
            showPixels(tachColor);
            std::this_thread::sleep_for(std::chrono::milliseconds(50));
        }
        hasStartupSequenceRun = true;
    } else if (igfreq < onFrequency) {
        hasStartupSequenceRun = false;
    }

    if (igfreq > maxFrequency) {
        for (int i = 0; i < NUMPIXELS; i++) {
            if (igfreq > lightShiftFreq[i]) {
                showPixels(tachColor);
            } else {
                showPixels(std::vector<std::tuple<int, int, int>>(NUMPIXELS, {0, 0, 0}));
            }
        }
    } else if (igfreq >= maxFrequency && igfreq < shiftFrequency) {
        showPixels(std::vector<std::tuple<int, int, int>>(NUMPIXELS, {0, 0, 120}));
        std::this_thread::sleep_for(std::chrono::milliseconds(flashtimer));
        showPixels(std::vector<std::tuple<int, int, int>>(NUMPIXELS, {0, 0, 0}));
        std::this_thread::sleep_for(std::chrono::milliseconds(flashtimer));
    } else if (igfreq >= shiftFrequency) {
        showPixels(std::vector<std::tuple<int, int, int>>(NUMPIXELS, {120, 0, 0}));
        std::this_thread::sleep_for(std::chrono::milliseconds(flashtimer));
        showPixels(std::vector<std::tuple<int, int, int>>(NUMPIXELS, {0, 0, 0}));
        std::this_thread::sleep_for(std::chrono::milliseconds(flashtimer));
    }
}

int main() {
    setup();
    while (true) {
        loop();
    }
    gpioTerminate();
    return 0;
}