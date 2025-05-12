abstract class ChatEntrypointEntity {
  String? get predefinedQuestion;
}

class IzinEntrypointEntity extends ChatEntrypointEntity {
  IzinEntrypointEntity() : super();

  @override
  String? get predefinedQuestion => null;
}

class CardEntrypointEntity extends ChatEntrypointEntity {
  CardEntrypointEntity({String? predefinedQuestion})
    : _predefinedQuestion = predefinedQuestion,
      super();
  final String? _predefinedQuestion;

  @override
  String? get predefinedQuestion => _predefinedQuestion;
}

class BazsuEntrypointEntity extends ChatEntrypointEntity {
  BazsuEntrypointEntity() : super();

  @override
  String? get predefinedQuestion => null;
}
