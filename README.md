<img src="assets/icon.svg" width="64" height="64" alt="">

# matrix-guitar

A Flutter app for learning guitar scales and arpeggios. Browse a library of both, see each one on a fretboard, practice it with real-time feedback from the microphone, and review a summary of each session.

## Run

```
flutter pub get
flutter run
flutter test
```

In debug builds, `flutter run --dart-define=FAKE_AUDIO=true` plays simulated audio instead of using the microphone.

## Practice

Pick a scale or arpeggio from the two tabs, then any of the 12 root notes and a fret window.

Before starting, choose direction (ascending, descending, both), note order (straight, thirds, groups of 3 or 4, random), repeats (1-3), and hints (full, no names, from memory).

## Limitations

- Notes are detected one at a time, so mute each string as you go. In synthetic tests with strings muted, every scale, arpeggio and note order was heard correctly at two notes a second or slower. With strings left to ring, arpeggios and the thirds and group orders often failed at two notes a second and still failed at one; only six straight scale runs held up.
- Overlapping undamped strings can miss a note or invent a pitch.
- Replaying a note that is still ringing is reliable at about 2.5 times the ringing level, not 2 times.
- A volume swell of 80 ms or longer that rises about 2 times every 50 ms can report the note more than once.
- Deep beating in a ringing note, with its level dipping 70% or more several times a second, can report false repeats.
- The expected note always passes the harmonic filter so runs don't stall, which means a strong octave harmonic of a ringing note can occasionally count as the expected note an octave up.
- Latency and accuracy have been measured only on synthetic signals, not on a real guitar and phone.

Created in [T3 Code](https://t3.codes).
