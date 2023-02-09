import 'question.dart';

class QuizBrain {

  int _questionNumber = 0;

  List<Question> _questionBank = [
    Question('It is safe to open an email attachment from an unknown sender.', false),
    Question('Anti-virus software can protect against all forms of malware.', false),
    Question('You should always give out personal information when asked for it online.', false),
    Question('Public Wi-Fi networks are always secure.', false),
    Question('You should use the same password for all of your accounts.', false),
    Question('It is safe to use public charging stations for your devices.', false),
    Question(
        'You should download software from unverified sources.',
        false),
    Question(
        'Social engineering attacks can only occur through email.',
        false),
    Question(
        'Two-factor authentication is not necessary for all accounts.',
        false),
    Question(
        'You should ignore software updates and security patches.',
        false),
    Question('Strong passwords should be at least 12 characters long and include a mix of letters, numbers, and symbols.', true),
    Question(
        ' Regular backups of important data can help prevent data loss in the event of a cyber attack or system failure.',
        true),
    Question(
        'It\'s a good idea to regularly review and update privacy settings on social media accounts.',
        true),
  ];

  void nextQuestion() {
    if (_questionNumber < _questionBank.length -1) {
      _questionNumber++;
    }
  }

  String getQuestionText() {
    return _questionBank[_questionNumber].questionText;
  }

  bool getCorrectAnswer() {
    return _questionBank[_questionNumber].questionAnswer;
  }

  bool isFinished() {
    if (_questionNumber >= _questionBank.length - 1) {
      print('Now returing true');
      return true;
    } else {
      return false;
    }
  }

  void reset() {
    _questionNumber = 0;
  }
}
