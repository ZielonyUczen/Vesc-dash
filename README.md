# VESC Dash

Pulpit nawigacyjny w czasie rzeczywistym dla zestawu **Marketbase 75200 V2 + BBS02B** (firmware 7.x).

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
- Kolorowe wskaźniki okrągłe (gauge) + karty statystyk
- Konfigurowalny panel przekładni i konfiguracji WebSocket
- Ostrzeżenia przy przekroczeniu temperatury MOSFET/silnika
- Wyświetlanie kodów błędów VESC

## Architektura projektu

```
src/
├── lib/
│   ├── speed.ts      # Przelicznik eRPM → km/h (BBS02B)
│   ├── vesc.ts       # Typy telemetrii VESC, kody błędów
│   └── client.ts     # Klient WebSocket (auto-reconnect)
├── hooks/
│   └── useVesc.ts    # React hook zarządzający połączeniem
├── components/
│   ├── Dashboard.tsx     # Główny layout
│   ├── Gauge.tsx         # Wskaźnik kołowy SVG
│   ├── StatCard.tsx      # Karta z pojedynczą wartością
│   ├── ConnectionBadge.tsx
│   └── SettingsPanel.tsx # Panel konfiguracji
└── __tests__/
    └── speed.test.ts     # Testy jednostkowe przelicznika prędkości
```

## Obliczanie prędkości

```
eRPM  ──÷ polePairs──▶ mech. RPM
                           │
                     ÷ motorGearRatio (21.9)
                           │
                     × (frontTeeth / rearTeeth)
                           │
                     × wheelCircumference × 60 / 1000
                           │
                         km/h
```

## Uruchomienie

### Wymagania

- Node.js ≥ 18
- Serwer WebSocket przekazujący dane RT z VESC (np. skrypt serial-to-ws lub VESC Express)

### Instalacja i uruchomienie

```bash
npm install
npm run dev
```

Otwórz `http://localhost:5173`. W panelu ⚙ Ustawienia wpisz adres WebSocket swojego mostka VESC.

### Format wiadomości WebSocket

Most powinien wysyłać dane w formacie JSON:

```json
{
  "type": "rt_data",
  "payload": {
    "voltageInput": 42.5,
    "currentMotor": 15.2,
    "currentInput": 8.1,
    "dutyCycle": 45,
    "erpm": 22000,
    "ampHours": 1.23,
    "wattHours": 52.1,
    "tempMosfet": 38.5,
    "tempMotor": 41.0,
    "faultCode": 0
  }
}
```

### Budowanie produkcyjne

```bash
npm run build
```

Wynik trafia do katalogu `dist/`.

### Testy

```bash
npm test
```