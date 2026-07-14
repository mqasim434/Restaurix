import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurix/core/config/env_config.dart';

void main() {
  group('EnvConfig', () {
    tearDown(() {
      dotenv.testLoad(fileInput: '');
    });

    test('isSupabaseConfigured is true for real-looking credentials', () {
      dotenv.testLoad(
        fileInput: 'SUPABASE_URL=https://abc123.supabase.co\n'
            'SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test',
      );

      expect(EnvConfig.isSupabaseConfigured, isTrue);
    });

    test('isSupabaseConfigured rejects bundled placeholders', () {
      dotenv.testLoad(
        fileInput: 'SUPABASE_URL=https://your-project-ref.supabase.co\n'
            'SUPABASE_ANON_KEY=your-supabase-anon-key',
      );

      expect(EnvConfig.isSupabaseConfigured, isFalse);
    });

    test('deploymentHint mentions .env next to executable', () {
      expect(EnvConfig.deploymentHint(), contains('.env'));
    });
  });
}
