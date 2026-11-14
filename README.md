<img src="assets/app-icon.png" width="64" height="64" alt="Matrix Guitar app icon">

# matrix-guitar

A Flutter app for learning guitar scales, arpeggios and chords. Browse a library of all three, see each scale or arpeggio on a fretboard and each chord as a diagram, practice it with real-time feedback from the microphone, and review a summary of each session.

## Run

```
flutter pub get
flutter run
flutter test
```

In debug builds, `flutter run --dart-define=FAKE_AUDIO=true` plays simulated audio instead of using the microphone.

## Practice

Pick a scale, arpeggio or chord from the first three tabs. For a scale or arpeggio, then pick any of the 12 root notes and a fret window.

Before starting a scale or arpeggio, choose direction (ascending, descending, both), note order (straight, thirds, groups of 3 or 4, random), repeats (1-3), and hints (full, no names, from memory).

For chords, pick a chord, see its diagram and spelled notes, and strum it 10 times. Every failed strum counts as wrong and tells you which notes were missing or extra.

## Theory practice

The fourth, scrollable Theory tab offers all 12 major keys and ii7–V7–Imaj7, I–vi–IV–V, I–V/ii–ii–V–I and I–IV–iv–I. Roman numerals label function in the key; chord-tone degrees are relative to the current chord root. V/ii is a secondary dominant seventh chord; iv borrows the minor subdominant from parallel minor.

Choose chord-tone targeting (root, third, fifth or seventh), nearest guide-tone voice leading, progression transposition, or construction and inversions. Expand Music theory basics for the vocabulary and How this exercise works for a worked example in your selected key. Quiz reminders explain the method without showing the answer; feedback explains the notes, intervals and bass after an attempt. Quizzes allow retries and track progress. Seventh targeting requires the all-seventh progression; guide tones use only the third on triads. Guide-tone movement stays in frets 3–7, starts nearest middle C (C4), then minimizes semitone movement with lower-pitch ties.

Chord-tone and guide-tone exercises also support microphone practice through the existing single-note listener. Match the shown octave and mute other strings. An advanced shell-voicing and chord-melody example is available for exploration, but theory practice cannot grade polyphonic voicings, inversions or chord melody.

## Limitations

- Notes are detected one at a time, so mute each string as you go. In synthetic tests with strings muted, every scale, arpeggio and note order was heard correctly at two notes a second or slower. With strings left to ring, arpeggios and the thirds and group orders often failed at two notes a second and still failed at one; only six straight scale runs held up.
- Overlapping undamped strings can miss a note or invent a pitch.
- Replaying a note that is still ringing is reliable at about 2.5 times the ringing level, not 2 times.
- A volume swell of 80 ms or longer that rises about 2 times every 50 ms can report the note more than once.
- Deep beating in a ringing note, with its level dipping 70% or more several times a second, can report false repeats.
- The expected note always passes the harmonic filter so runs don't stall, which means a strong octave harmonic of a ringing note can occasionally count as the expected note an octave up.
- Latency and accuracy have been measured only on synthetic signals, not on a real guitar and phone.
- The check is built around the voicing shown, so the same chord in another shape may pass or fail.
- Leave about 0.5 s between strums; strums spaced closer than that are often scored wrong.
- A lone pluck or knock while a chord is still ringing can earn a correct rep, because the verdict hears the ring.
- Strums slower than about 250 ms from first to last string can be misjudged, or counted as two.
- The guitar needs to be in tune, roughly within 20-30 cents; 45 cents sharp fails badly.
- Strum detection has been tested only on synthetic audio, not on a real guitar.

Created in [T3 Code](https://t3.codes).
