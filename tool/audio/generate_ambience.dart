import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  const sampleRate = 44100;
  
  void writeWav(String path, List<double> floatSamples) {
    double maxAmp = 0.0;
    for (var s in floatSamples) {
      if (s.abs() > maxAmp) maxAmp = s.abs();
    }
    if (maxAmp == 0.0) maxAmp = 1.0;

    final samples = <int>[];
    for (var s in floatSamples) {
      final normalized = s / maxAmp;
      samples.add((normalized * 32767).toInt().clamp(-32768, 32767));
    }

    final dataSize = samples.length * 2;
    final builder = BytesBuilder();
    builder.add([0x52, 0x49, 0x46, 0x46]);
    builder.add(_int32LE(36 + dataSize));
    builder.add([0x57, 0x41, 0x56, 0x45]);
    builder.add([0x66, 0x6D, 0x74, 0x20]);
    builder.add(_int32LE(16));
    builder.add(_int16LE(1));
    builder.add(_int16LE(1));
    builder.add(_int32LE(sampleRate));
    builder.add(_int32LE(sampleRate * 2));
    builder.add(_int16LE(2));
    builder.add(_int16LE(16));
    builder.add([0x64, 0x61, 0x74, 0x61]);
    builder.add(_int32LE(dataSize));
    for (final s in samples) {
      builder.add(_int16LE(s));
    }
    File(path).writeAsBytesSync(builder.toBytes());
  }

  final rng = Random();

  // AMBIENCE: 10 seconds of wind and subtle night sounds (loops beautifully)
  {
    final n = (sampleRate * 10.0).toInt();
    final out = List<double>.filled(n, 0.0);
    
    // Simple low-pass filter state
    double windFilter = 0.0;
    
    for (int i = 0; i < n; i++) {
      final t = i / sampleRate;
      
      // 1. Wind (filtered white noise)
      final noise = rng.nextDouble() * 2 - 1;
      
      // Modulate filter cutoff with a slow LFO to sound like howling wind
      final lfo = (sin(2 * pi * 0.1 * t) + sin(2 * pi * 0.15 * t + 1.0)) * 0.5; // -1 to 1 roughly
      final cutoff = 0.02 + (lfo + 1.0) * 0.02; // Very low cutoff
      
      windFilter += (noise - windFilter) * cutoff;
      
      // Wind volume also modulated
      final windVol = 0.3 + (lfo * 0.1);
      double val = windFilter * windVol;
      
      // 2. Occasional crickets (high frequency bursts)
      // Every ~1 second, with some randomness
      final cricketCycle = (t * 1.5) % 1.0;
      if (cricketCycle < 0.1 && rng.nextDouble() > 0.3) {
        final cricketLfo = sin(2 * pi * 50 * t); // chirp speed
        if (cricketLfo > 0) {
           val += (rng.nextDouble() * 2 - 1) * 0.05 * sin(2 * pi * 4000 * t); // 4kHz chirp
        }
      }
      
      out[i] = val;
    }
    writeWav('assets/audio/ambience.wav', out);
    print('Generated assets/audio/ambience.wav');
  }
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
  if (value < 0) value = value + 65536;
  return [value & 0xFF, (value >> 8) & 0xFF];
}