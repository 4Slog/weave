import 'package:kente_codeweaver/features/patterns/models/pattern_model.dart';
import '../models/challenge_model.dart';
import '../models/validation_result.dart';

/// Interface for challenge validators.
///
/// This interface defines the contract for validators that check if a user's
/// solution meets the success criteria of a challenge.
abstract class ChallengeValidator {
  /// Validate a solution against a challenge.
  ///
  /// [challenge] is the challenge to validate against.
  /// [solution] is the user's solution to the challenge.
  ///
  /// Returns a validation result with success flag and feedback.
  Future<ValidationResult> validate({
    required ChallengeModel challenge,
    required PatternModel solution,
  });

  /// Check if this validator can handle a specific challenge type.
  ///
  /// [challengeType] is the type of challenge to check.
  ///
  /// Returns true if this validator can handle the challenge type.
  bool canHandle(String challengeType);

  /// Get the educational standards demonstrated by a solution.
  ///
  /// [challenge] is the challenge being solved.
  /// [solution] is the user's solution to the challenge.
  /// [success] indicates whether the solution meets the basic success criteria.
  ///
  /// Returns a list of standard IDs demonstrated by the solution.
  Future<List<String>> getStandardsDemonstrated({
    required ChallengeModel challenge,
    required PatternModel solution,
    required bool success,
  });

  /// Get the skills demonstrated by a solution.
  ///
  /// [challenge] is the challenge being solved.
  /// [solution] is the user's solution to the challenge.
  /// [success] indicates whether the solution meets the basic success criteria.
  ///
  /// Returns a map of skill IDs to skill levels demonstrated by the solution.
  Future<Map<String, double>> getSkillsDemonstrated({
    required ChallengeModel challenge,
    required PatternModel solution,
    required bool success,
  });

  /// Assess a solution against the challenge rubric.
  ///
  /// [challenge] is the challenge being solved.
  /// [solution] is the user's solution to the challenge.
  /// [issues] are any validation issues found.
  ///
  /// Returns an assessment of the solution against the rubric.
  SolutionAssessment assessSolution({
    required ChallengeModel challenge,
    required PatternModel solution,
    required List<ValidationIssue> issues,
  });

  /// Create feedback for a solution.
  ///
  /// [challenge] is the challenge being solved.
  /// [success] indicates whether the solution meets the basic success criteria.
  /// [issues] are any validation issues found.
  /// [assessment] is the assessment of the solution against the rubric.
  ///
  /// Returns feedback for the user.
  ValidationFeedback createFeedback({
    required ChallengeModel challenge,
    required bool success,
    required List<ValidationIssue> issues,
    required SolutionAssessment assessment,
  });

  /// Get achievements unlocked by a solution.
  ///
  /// [challenge] is the challenge being solved.
  /// [success] indicates whether the solution meets the basic success criteria.
  /// [assessment] is the assessment of the solution against the rubric.
  ///
  /// Returns a list of achievements unlocked by the solution.
  Future<List<Achievement>> getAchievements({
    required ChallengeModel challenge,
    required bool success,
    required SolutionAssessment assessment,
  });
}
