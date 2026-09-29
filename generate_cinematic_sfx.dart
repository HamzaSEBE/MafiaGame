import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  const sampleRate = 44100;

  void writeWav(String path, List<double> floatSamples) {
    // Normalize and convert to 16-bit PCM
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
    builder.add([0x52, 0x49, 0x46, 0x46]); // "RIFF"
    builder.add(_int32LE(36 + dataSize));
    builder.add([0x57, 0x41, 0x56, 0x45]); // "WAVE"
    builder.add([0x66, 0x6D, 0x74, 0x20]); // "fmt "
    builder.add(_int32LE(16));
    builder.add(_int16LE(1));
    builder.add(_int16LE(1));
    builder.add(_int32LE(sampleRate));
    builder.add(_int32LE(sampleRate * 2));
    builder.add(_int16LE(2));
    builder.add(_int16LE(16));
    builder.add([0x64, 0x61, 0x74, 0x61]); // "data"
    builder.add(_int32LE(dataSize));
    for (final s in samples) {
      builder.add(_int16LE(s));
    }
    File(path).writeAsBytesSync(builder.toBytes());
  }

  final rng = Random(42);

  // 1. CLICK: Elegant soft UI pop
  {
    final n = (sampleRate * 0.08).toInt();
    final out = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      final t = i / sampleRate;
      final env = exp(-t * 80);
      out[i] = sin(2 * pi * 800 * t) * env * 0.5 + sin(2 * pi * 1500 * t) * exp(-t * 200) * 0.5;
    }
    writeWav('assets/audio/click.wav', out);
  }

  // 2. KILL: Gunshot (White noise + low punch, clipped)
  {
    final n = (sampleRate * 1.5).toInt();
    final out = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      final t = i / sampleRate;
      final noise = rng.nextDouble() * 2 - 1;
      final noiseEnv = exp(-t * 15);
      
      final punchFreq = max(40.0, 150.0 - (t * 800.0));
      final punch = sin(2 * pi * punchFreq * t);
      final punchEnv = exp(-t * 10);
      
      double val = (noise * noiseEnv * 1.5) + (punch * punchEnv * 2.0);
      // Soft clipping for distortion
      val = (val / (1.0 + val.abs())) * 1.5;
      
      // Add some reverberation tail (simple exponential decay on noise)
      final tailEnv = exp(-t * 3);
      val += (rng.nextDouble() * 2 - 1) * tailEnv * 0.1;
      
      out[i] = val;
    }
    writeWav('assets/audio/kill.wav', out);
  }

  // 3. PROTECT: Magical shield (FM synthesis + shimmer)
  {
    final n = (sampleRate * 2.0).toInt();
    final out = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      final t = i / sampleRate;
      final env = (t < 0.1) ? (t / 0.1) : exp(-(t - 0.1) * 2);
      
      // Carrier frequencies
      final c1 = sin(2 * pi * 880 * t + 2 * sin(2 * pi * 5 * t));
      final c2 = sin(2 * pi * 1320 * t + 1 * sin(2 * pi * 3.5 * t));
      final c3 = sin(2 * pi * 1760 * t + 0.5 * sin(2 * pi * 2 * t));
      
      out[i] = (c1 + c2 * 0.7 + c3 * 0.4) * env;
    }
    writeWav('assets/audio/protect.wav', out);
  }

  // 4. VOTE: Heavy cinematic impact (Gavel / Heartbeat)
  {
    final n = (sampleRate * 1.5).toInt();
    final out = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      final t = i / sampleRate;
      // Frequency drop from 100Hz to 40Hz quickly
      final freq = max(40.0, 120.0 * exp(-t * 20));
      final env = (t < 0.01) ? (t / 0.01) : exp(-(t - 0.01) * 5);
      final val = sin(2 * pi * freq * t) * env;
      
      // Slight noise for texture
      final noise = (rng.nextDouble() * 2 - 1) * exp(-t * 30) * 0.2;
      out[i] = val + noise;
    }
    writeWav('assets/audio/vote.wav', out);
  }

  // 5. REVEAL: Cinematic whoosh to impact
  {
    final n = (sampleRate * 2.5).toInt();
    final out = List<double>.filled(n, 0.0);
    final impactTime = 1.0;
    for (int i = 0; i < n; i++) {
      final t = i / sampleRate;
      double val = 0.0;
      
      // Whoosh (sucks in before impact)
      if (t < impactTime) {
        final whooshEnv = pow(t / impactTime, 3); // Exponential rise
        final noise = rng.nextDouble() * 2 - 1;
        // Sweeping filter effect approximated by modulating noise amplitude rapidly
        val += noise * whooshEnv * sin(2 * pi * (100 + t * 400) * t) * 0.5;
      } 
      // Impact
      else {
        final t2 = t - impactTime;
        final boomEnv = exp(-t2 * 2);
        final boomFreq = max(30.0, 80.0 * exp(-t2 * 10));
        val += sin(2 * pi * boomFreq * t2) * boomEnv * 2.0;
        
        final noiseEnv = exp(-t2 * 4);
        val += (rng.nextDouble() * 2 - 1) * noiseEnv * 0.3;
      }
      out[i] = val;
    }
    writeWav('assets/audio/reveal.wav', out);
  }

  // 6. INTRO: Deep Inception BRAAAM
  {
    final n = (sampleRate * 4.0).toInt();
    final out = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      final t = i / sampleRate;
      // ADSR Envelope
      double env = 0.0;
      if (t < 0.5) env = t / 0.5;
      else if (t < 3.0) env = 1.0;
      else env = max(0.0, 1.0 - (t - 3.0) / 1.0);
      
      // Distorted brassy synth
      final baseFreq = 55.0; // Low A
      double val = 0.0;
      for (int h = 1; h <= 8; h++) {
        final hEnv = exp(-h * 0.5);
        val += sin(2 * pi * baseFreq * h * t) * hEnv;
      }
      // Detuned saw-like layer
      val += sin(2 * pi * baseFreq * 1.01 * t) * 0.5;
      val += sin(2 * pi * baseFreq * 0.99 * t) * 0.5;
      
      // Soft clip
      val = (val / (1.0 + val.abs())) * 1.2;
      
      out[i] = val * env;
    }
    writeWav('assets/audio/intro.wav', out);
  }

  print('Cinematic SFX generated!');
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