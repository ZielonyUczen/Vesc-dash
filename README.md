# VESC Dash

Pulpit nawigacyjny w czasie rzeczywistym dla zestawu **Marketbase 75200 V2 + BBS02B** (firmware 7.x).  
Aplikacja zbudowana na **Qt 6 / QML** z biblioteką **libsimplebm** do komunikacji BLE z VESC.

## Specyfikacja sprzętu

| Parametr | Wartość |
|---|---|
| Sterownik VESC | Marketbase 75200 V2 |
| Silnik | BBS02B (mid-drive) |
| Przełożenie wewnętrzne | 1 : 21,9 |
| Zębatka przednia | 40 T |
| Kaseta tylna | 11–42 T |
| Pary biegunów | 8 |
| Firmware | 7.0 |

## Funkcje

- Prędkość wyliczana z eRPM z uwzględnieniem pełnego łańcucha napędowego
- Wskazania w czasie rzeczywistym: napięcie, prąd silnika, prąd baterii, moc, duty cycle, temperatury
- Kolorowe wskaźniki kołowe (QML `Shape`) + karty statystyk
- Panel ustawień: dobór aktywnej zębatki kasety, obwód koła, przełożenia
- Wyszukiwanie urządzeń BLE i połączenie z VESC przez Nordic UART Service (NUS)
- Ostrzeżenia przy przekroczeniu temperatury MOSFET > 70 °C / silnika > 80 °C
- Wyświetlanie kodów błędów VESC z opisem po polsku

## Architektura projektu

```
VescDash/
├── main.cpp                      # Punkt wejścia Qt
├── CMakeLists.txt                # Budowanie Qt6 + libsimplebm
├── src/
│   ├── VescController.h/.cpp     # Logika obliczania prędkości, dane telemetryczne
│   └── VescBleClient.h/.cpp      # Komunikacja BLE przez libsimplebm / NUS
├── qml/
│   ├── Main.qml                  # Główny widok (StackLayout)
│   ├── Gauge.qml                 # Wskaźnik kołowy (Qt Shapes)
│   ├── StatCard.qml              # Karta z wartością
│   └── SettingsPage.qml          # Ustawienia BLE i przekładni
├── tests/
│   └── TestVescController.cpp    # Testy Qt Test (obliczenia prędkości, telemetria)
└── third_party/libsimplebm/      # Submoduł git (VESC BLE library)
```

## Obliczanie prędkości

```
eRPM  ──÷ polePairs (8)──▶ mech. RPM
                               │
                         ÷ motorGearRatio (21.9)
                               │
                         × (frontTeeth / rearTeeth)
                               │
                         × wheelCircumference × 60 / 1000
                               │
                             km/h
```

## Wymagania

- Qt 6.5+ (Quick, Bluetooth, Shapes)
- CMake 3.21+
- [libsimplebm](https://github.com/vedderb/vesc_express) (VESC BLE library) — dodaj jako submoduł

## Budowanie

```bash
git submodule update --init --recursive

cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel

# Testy
cd build && ctest --output-on-failure
```

## Protokół BLE (Nordic UART Service)

VESC NUS UUIDs:
- **Service**: `6e400001-b5a3-f393-e0a9-e50e24dcca9e`
- **TX** (notify, VESC→app): `6e400003-b5a3-f393-e0a9-e50e24dcca9e`
- **RX** (write, app→VESC): `6e400002-b5a3-f393-e0a9-e50e24dcca9e`

Pakiet żądania RT data (`COMM_GET_VALUES = 0x04`):
```
02 01 04 <crc_hi> <crc_lo> 03
```