import 'package:flutter_test/flutter_test.dart';
import 'package:mindflow/viewmodels/home_viewmodel.dart';
import 'package:mindflow/models/user_model.dart';
import 'package:mindflow/repositories/auth_repository.dart';
import 'package:mindflow/repositories/user_repository.dart';

class MockAuthRepository implements AuthRepository {
  UserModel? _mockUser;
  
  void setMockUser(UserModel? user) {
    _mockUser = user;
  }

  @override
  UserModel? get currentUserModel => _mockUser;

  @override
  Stream<UserModel?> get userModelStream => Stream.value(_mockUser);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUserRepository implements UserRepository {
  String? mockFeeling;
  final List<String> mockFavorites = [];

  @override
  Future<String?> getUserFeeling(String uid) async => mockFeeling;

  @override
  Future<String?> getOnboardingFeeling(String uid) async => mockFeeling;

  @override
  Future<void> updateUserFeeling(String uid, String feeling) async {
    mockFeeling = feeling;
  }

  @override
  Future<List<String>> getFavoriteSessionTitles(String uid) async => mockFavorites;

  @override
  Future<void> addFavoriteSession(String uid, String sessionTitle) async {
    mockFavorites.add(sessionTitle);
  }

  @override
  Future<void> removeFavoriteSession(String uid, String sessionTitle) async {
    mockFavorites.remove(sessionTitle);
  }
}

void main() {
  group('HomeViewModel Tests', () {
    late MockAuthRepository mockAuthRepository;
    late MockUserRepository mockUserRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockUserRepository = MockUserRepository();
    });

    test('Initial state initializes with default values', () {
      final viewModel = HomeViewModel(
        authRepository: mockAuthRepository,
        userRepository: mockUserRepository,
      );

      expect(viewModel.data.userName, equals('MindFlow User'));
      expect(viewModel.activeTab, equals(0));
      expect(viewModel.isPremium, isFalse);
    });

    test('selectFeeling updates active feeling and mood index correctly', () async {
      mockAuthRepository.setMockUser(
        UserModel(
          uid: 'test_uid',
          email: 'test@mindflow.app',
          name: 'Jane Doe',
          createdAt: DateTime.now(),
        ),
      );

      final viewModel = HomeViewModel(
        authRepository: mockAuthRepository,
        userRepository: mockUserRepository,
      );
      await Future<void>.delayed(Duration.zero);

      await viewModel.selectFeeling('stressed');
      expect(viewModel.data.activeFeeling, equals('stressed'));
      expect(viewModel.data.activeMoodIndex, equals(0)); // Low mood

      await viewModel.selectFeeling('grateful');
      expect(viewModel.data.activeFeeling, equals('grateful'));
      expect(viewModel.data.activeMoodIndex, equals(3)); // Great mood
    });

    test('timeOfDayGreeting returns appropriate string based on current hour', () {
      final viewModel = HomeViewModel(
        authRepository: mockAuthRepository,
        userRepository: mockUserRepository,
      );

      final greeting = viewModel.timeOfDayGreeting;
      expect(
        greeting,
        anyOf([
          equals('Good Morning'),
          equals('Good Afternoon'),
          equals('Good Evening'),
          equals('Good Night'),
        ]),
      );
    });

    test('adaptiveHeroTag returns valid Hero Tag string', () {
      final viewModel = HomeViewModel(
        authRepository: mockAuthRepository,
        userRepository: mockUserRepository,
      );

      final heroTag = viewModel.adaptiveHeroTag;
      expect(
        heroTag,
        anyOf([
          equals('MORNING FOCUS'),
          equals('MIDDAY RESET'),
          equals('EVENING CALM'),
          equals('DEEP SLEEP'),
        ]),
      );
    });
  });
}
