import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  const sampleRate = 44100;

  // Helper: write WAV file
  void writeWav(String path, List<int> samples) {
    final dataSize = samples.length * 2;
    final builder = BytesBuilder();
    
    // RIFF header
    builder.add([0x52, 0x49, 0x46, 0x46]); // "RIFF"
    builder.add(_int32LE(36 + dataSize));
    builder.add([0x57, 0x41, 0x56, 0x45]); // "WAVE"
    
    // fmt chunk
    builder.add([0x66, 0x6D, 0x74, 0x20]); // "fmt "
    builder.add(_int32LE(16)); // chunk size
    builder.add(_int16LE(1));  // PCM format
    builder.add(_int16LE(1));  // mono
    builder.add(_int32LE(sampleRate));
    builder.add(_int32LE(sampleRate * 2)); // byte rate
    builder.add(_int16LE(2));  // block align
    builder.add(_int16LE(16)); // bits per sample
    
    // data chunk
    builder.add([0x64, 0x61, 0x74, 0x61]); // "data"
    builder.add(_int32LE(dataSize));
    for (final s in samples) {
      builder.add(_int16LE(s));
    }
    
    File(path).writeAsBytesSync(builder.toBytes());
  }

  // 1. CLICK: crisp short tap (1200Hz, 50ms)
  {
    final n = (sampleRate * 0.05).toInt();
    final samples = <int>[];
    for (int i = 0; i < n; i++) {
      final t = i / sampleRate;
      final env = (1.0 - (i / n) * 1.5).clamp(0.0, 1.0);
      final val = 0.8 * env * sin(2 * pi * 1200 * t);
      samples.add((val * 32767).toInt().clamp(-32767, 32767));
    }
    writeWav('assets/audio/click.wav', samples);
    print('click.wav: ${samples.length * 2} bytes');
  }

  // 2. KILL: deep dramatic boom (80Hz + 200Hz, 500ms)
  {
    final n = (sampleRate * 0.5).toInt();
    final samples = <int>[];
    for (int i = 0; i < n; i++) {
      final t = i / sampleRate;
      final env = (1.0 - (i / n) * 1.2).clamp(0.0, 1.0);
      final val = 0.7 * env * (sin(2*pi*80*t) + 0.5*sin(2*pi*200*t) + 0.3*sin(2*pi*50*t));
      samples.add((val.clamp(-1.0, 1.0) * 32767).toInt());
    }
    writeWav('assets/audio/kill.wav', samples);
    print('kill.wav: ${samples.length * 2} bytes');
  }

  // 3. PROTECT: gentle ascending chime (800Hz + 1200Hz, 300ms)
  {
    final n = (sampleRate * 0.3).toInt();
    final samples = <int>[];
    for (int i = 0; i < n; i++) {
      final t = i / sampleRate;
      final env = (1.0 - (i / n)).clamp(0.0, 1.0);
      final val = 0.5 * env * (sin(2*pi*800*t) + 0.7*sin(2*pi*1200*t) + 0.3*sin(2*pi*1600*t));
      samples.add((val.clamp(-1.0, 1.0) * 32767).toInt());
    }
    writeWav('assets/audio/protect.wav', samples);
    print('protect.wav: ${samples.length * 2} bytes');
  }

  // 4. VOTE: suspenseful rising tone (300->600Hz, 250ms)
  {
    final n = (sampleRate * 0.25).toInt();
    final samples = <int>[];
    for (int i = 0; i < n; i++) {
      final t = i / sampleRate;
      final f = 300.0 + (300.0 * i / n);
      final env = (1.0 - (i / n) * 0.8).clamp(0.0, 1.0);
      final val = 0.5 * env * sin(2 * pi * f * t);
      samples.add((val.clamp(-1.0, 1.0) * 32767).toInt());
    }
    writeWav('assets/audio/vote.wav', samples);
    print('vote.wav: ${samples.length * 2} bytes');
  }

  // 5. REVEAL: dramatic whoosh (noise burst 150ms)
  {
    final rng = Random(42);
    final n = (sampleRate * 0.15).toInt();
    final samples = <int>[];
    for (int i = 0; i < n; i++) {
      final env = (1.0 - (i / n) * 1.5).clamp(0.0, 1.0);
      final val = 0.4 * env * (rng.nextDouble() * 2 - 1);
      samples.add((val.clamp(-1.0, 1.0) * 32767).toInt());
    }
    writeWav('assets/audio/reveal.wav', samples);
    print('reveal.wav: ${samples.length * 2} bytes');
  }

  // 6. INTRO: cinematic deep rumble + hit (600ms)
  {
    final n = (sampleRate * 0.6).toInt();
    final samples = <int>[];
    for (int i = 0; i < n; i++) {
      final t = i / sampleRate;
      final phase = i / n;
      double env;
      if (phase < 0.3) {
        env = phase / 0.3;
      } else if (phase < 0.35) {
        env = 1.0;
      } else {
        env = (1.0 - (phase - 0.35) / 0.65).clamp(0.0, 1.0);
      }
      final val = 0.7 * env * (sin(2*pi*60*t) + 0.5*sin(2*pi*120*t) + 0.2*sin(2*pi*40*t));
      samples.add((val.clamp(-1.0, 1.0) * 32767).toInt());
    }
    writeWav('assets/audio/intro.wav', samples);
    print('intro.wav: ${samples.length * 2} bytes');
  }

  print('All SFX generated successfully!');
}

List<int> _int32LE(int value) {
  return [
    value & 0xFF,
    (value >> 8) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 24) & 0xFF,
  ];
}

List<int> _int16LE(int value) {
  // Handle signed 16-bit
  if (value < 0) value = value + 65536;
  return [value & 0xFF, (value >> 8) & 0xFF];
}
