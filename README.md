# VN DJ - App DJ Professionale per Mac e iPad

App DJ che replica **2 CDJ-3000 + Mixer Pioneer** con integrazione Spotify.

## Funzionalita'

### 2 Deck Completi
- Play / Pause / Cue
- 8 Hot Cue per deck (A-H) con colori
- Loop: 1/2, 1, 4, 8, 16 beat + halve/double
- Beat Jump avanti/indietro
- Tempo slider con range regolabile (±6%, ±10%, ±16%, WIDE)
- Master Tempo (key lock)
- Beat Sync + Master
- Quantize

### Mixer Centrale
- EQ 3 bande (Hi/Mid/Lo) per canale
- Volume fader per canale
- Crossfader con curva regolabile
- CUE/PFL per monitoraggio in cuffia
- Master Volume

### Waveform
- Waveform colorata con progress
- Indicatori Hot Cue sulla waveform
- Evidenziazione loop attivo
- Overview del brano completo

### Browse / Libreria
- Import file locali (MP3, WAV, AIFF, M4A, FLAC, AAC)
- Ricerca per titolo, artista, album
- Caricamento su Deck A o B con un tap

### Spotify
- Login con account Spotify Premium
- Browse playlist personali
- Ricerca catalogo Spotify
- Caricamento brani sui deck

### Analisi Audio
- Rilevamento BPM automatico
- Generazione waveform
- Beat grid automatica

## Requisiti
- **Mac**: macOS 14 (Sonoma) o successivo
- **iPad**: iPadOS 17 o successivo
- Xcode 15+ per la compilazione

## Setup Sviluppo

```bash
git clone https://github.com/Vitileiaandrea/VN-DJ.git
cd VN-DJ
open Package.swift  # Apre in Xcode
```

Seleziona il target "My Mac" o un iPad connesso e premi Run.

## Architettura

- **Swift 5.9** + **SwiftUI** - Stessa app su Mac e iPad
- **AVAudioEngine** - Motore audio a bassa latenza
- **Accelerate/vDSP** - DSP ottimizzato per Apple Silicon
- **Spotify Web API** + **iOS SDK** - Integrazione Spotify
- **MVVM** - Architettura pulita e testabile

## Struttura

```
VN-DJ/
├── App/              # Entry point e layout principale
├── Views/
│   ├── Deck/         # UI deck (player, hot cue, loop, waveform)
│   ├── Mixer/        # UI mixer (EQ, crossfader, volume)
│   ├── Browser/      # Navigazione libreria e Spotify
│   └── Settings/     # Impostazioni
├── ViewModels/       # Logica business
├── Audio/
│   ├── AudioEngine/  # AVAudioEngine setup
│   └── Analysis/     # BPM detection, waveform analysis
├── Models/           # Modelli dati
├── Services/         # Spotify, analisi, import file
└── Utilities/        # Costanti e helper
```
