import 'package:flutter_test/flutter_test.dart';
import 'package:mindflow/models/assessment_model.dart';

void main() {
  group('Feeling and Assessment Tests', () {
    test('AssessmentResponse deserializes Feeling values correctly', () {
      final happyResponse = AssessmentResponse.fromMap({'feeling': 'happy'});
      expect(happyResponse.feeling, Feeling.happy);

      final calmResponse = AssessmentResponse.fromMap({'feeling': 'calm'});
      expect(calmResponse.feeling, Feeling.calm);

      final lonelyResponse = AssessmentResponse.fromMap({'feeling': 'lonely'});
      expect(lonelyResponse.feeling, Feeling.lonely);
    });

    test('AssessmentResponse maps legacy "relaxed" feeling to "calm"', () {
      final legacyResponse = AssessmentResponse.fromMap({'feeling': 'relaxed'});
      expect(legacyResponse.feeling, Feeling.calm);
    });

    test('AssessmentResponse deserializes CommitmentTime values correctly', () {
      final response3Min = AssessmentResponse.fromMap({'commitment': 'threeMin'});
      expect(response3Min.commitment, CommitmentTime.threeMin);

      final response15Min = AssessmentResponse.fromMap({'commitment': 'fifteenMin'});
      expect(response15Min.commitment, CommitmentTime.fifteenMin);
    });
  });
}
