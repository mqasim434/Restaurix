import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurix/core/config/env_config.dart';
import 'package:restaurix/data/remote/imagekit_upload_service.dart';

void main() {
  group('ImageKitUploadService helpers', () {
    test('detects remote vs local paths', () {
      expect(ImageKitUploadService.isRemoteUrl('https://ik.imagekit.io/x/a.jpg'),
          isTrue);
      expect(ImageKitUploadService.isRemoteUrl('http://example.com/a.png'),
          isTrue);
      expect(ImageKitUploadService.isRemoteUrl(r'C:\temp\photo.jpg'), isFalse);
      expect(ImageKitUploadService.isRemoteUrl(null), isFalse);
    });
  });

  group('EnvConfig ImageKit', () {
    tearDown(() {
      dotenv.testLoad(fileInput: '');
    });

    test('isImageKitConfigured rejects placeholders', () {
      dotenv.testLoad(
        fileInput: 'IMAGEKIT_PRIVATE_KEY=your_private_key\n'
            'IMAGEKIT_URL_ENDPOINT=https://ik.imagekit.io/your_imagekit_id\n',
      );
      expect(EnvConfig.isImageKitConfigured, isFalse);
    });

    test('isImageKitConfigured accepts real-looking keys', () {
      dotenv.testLoad(
        fileInput: 'IMAGEKIT_PRIVATE_KEY=private_abc123\n'
            'IMAGEKIT_URL_ENDPOINT=https://ik.imagekit.io/binomran\n',
      );
      expect(EnvConfig.isImageKitConfigured, isTrue);
    });
  });
}
