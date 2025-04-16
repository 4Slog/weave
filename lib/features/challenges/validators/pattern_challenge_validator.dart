import 'package:kente_codeweaver/features/patterns/models/pattern_model.dart';
import '../models/challenge_model.dart';
import '../models/validation_result.dart';
import 'challenge_validator.dart';

/// Validator for pattern-based challenges.
///
/// This validator checks if a pattern solution meets the success criteria
/// of a pattern-based challenge.
class PatternChallengeValidator implements ChallengeValidator {
  /// Create a new PatternChallengeValidator.
  PatternChallengeValidator();

  @override
  bool canHandle(String challengeType) {
    return challengeType == 'pattern';
  }

  @override
  Future<ValidationResult> validate({
    required ChallengeModel challenge,
    required PatternModel solution,
  }) async {
    // Check if this validator can handle the challenge type
    if (!canHandle(challenge.type)) {
      throw ArgumentError('This validator cannot handle challenges of type ${challenge.type}');
    }

    // Validate the solution against the success criteria
    final issues = _validateSuccessCriteria(challenge, solution);

    // Determine if the solution meets the basic success criteria
    final success = !issues.any((issue) => issue.severity == 'error');

    // Assess the solution against the rubric
    final assessment = assessSolution(
      challenge: challenge,
      solution: solution,
      issues: issues,
    );

    // Create feedback for the user
    final feedback = createFeedback(
      challenge: challenge,
      success: success,
      issues: issues,
      assessment: assessment,
    );

    // Get standards demonstrated by the solution
    final standardsDemonstrated = await getStandardsDemonstrated(
      challenge: challenge,
      solution: solution,
      success: success,
    );

    // Get skills demonstrated by the solution
    final skillsDemonstrated = await getSkillsDemonstrated(
      challenge: challenge,
      solution: solution,
      success: success,
    );

    // Get achievements unlocked by the solution
    final achievements = await getAchievements(
      challenge: challenge,
      success: success,
      assessment: assessment,
    );

    // Create and return the validation result
    return ValidationResult(
      success: success,
      challenge: challenge,
      solution: solution,
      feedback: feedback,
      assessment: assessment,
      issues: issues,
      achievements: achievements,
      skillsDemonstrated: skillsDemonstrated,
      standardsDemonstrated: standardsDemonstrated,
    );
  }

  @override
  Future<List<String>> getStandardsDemonstrated({
    required ChallengeModel challenge,
    required PatternModel solution,
    required bool success,
  }) async {
    // If the solution doesn't meet the basic success criteria,
    // no standards are demonstrated
    if (!success) return [];

    // Get the standards aligned with this challenge
    final standardIds = challenge.getStandardIds();

    // For a basic solution, return all standards
    if (success) {
      return standardIds;
    }

    return [];
  }

  @override
  Future<Map<String, double>> getSkillsDemonstrated({
    required ChallengeModel challenge,
    required PatternModel solution,
    required bool success,
  }) async {
    // If the solution doesn't meet the basic success criteria,
    // no skills are demonstrated
    if (!success) return {};

    // Get the skill requirements for this challenge
    final skillRequirements = challenge.skillRequirements;

    // For a basic solution, return all skills at their required levels
    if (success) {
      return Map<String, double>.from(skillRequirements);
    }

    return {};
  }

  @override
  SolutionAssessment assessSolution({
    required ChallengeModel challenge,
    required PatternModel solution,
    required List<ValidationIssue> issues,
  }) {
    // Check if the solution meets the basic success criteria
    final success = !issues.any((issue) => issue.severity == 'error');

    // If the solution doesn't meet the basic success criteria,
    // it's not assessed against the rubric
    if (!success) {
      return SolutionAssessment(
        achievementLevel: 'incomplete',
        pointsEarned: 0,
        criteriaMet: {},
      );
    }

    // Get the assessment rubric
    final rubric = challenge.assessmentRubric;

    // Check which criteria are met at each level
    final criteriaMet = <String, List<String>>{};

    // Check basic criteria
    final basicCriteriaMet = _checkCriteriaMet(
      rubric.basicCriteria,
      solution,
      issues,
    );
    if (basicCriteriaMet.isNotEmpty) {
      criteriaMet['basic'] = basicCriteriaMet;
    }

    // Check proficient criteria
    final proficientCriteriaMet = _checkCriteriaMet(
      rubric.proficientCriteria,
      solution,
      issues,
    );
    if (proficientCriteriaMet.isNotEmpty) {
      criteriaMet['proficient'] = proficientCriteriaMet;
    }

    // Check advanced criteria
    final advancedCriteriaMet = _checkCriteriaMet(
      rubric.advancedCriteria,
      solution,
      issues,
    );
    if (advancedCriteriaMet.isNotEmpty) {
      criteriaMet['advanced'] = advancedCriteriaMet;
    }

    // Determine the achievement level
    String achievementLevel;
    if (advancedCriteriaMet.length == rubric.advancedCriteria.length &&
        advancedCriteriaMet.isNotEmpty) {
      achievementLevel = 'advanced';
    } else if (proficientCriteriaMet.length == rubric.proficientCriteria.length &&
               proficientCriteriaMet.isNotEmpty) {
      achievementLevel = 'proficient';
    } else if (basicCriteriaMet.length == rubric.basicCriteria.length &&
               basicCriteriaMet.isNotEmpty) {
      achievementLevel = 'basic';
    } else {
      achievementLevel = 'incomplete';
    }

    // Calculate points earned
    int pointsEarned = 0;
    if (achievementLevel == 'advanced') {
      pointsEarned = rubric.getPointsForLevel('advanced');
    } else if (achievementLevel == 'proficient') {
      pointsEarned = rubric.getPointsForLevel('proficient');
    } else if (achievementLevel == 'basic') {
      pointsEarned = rubric.getPointsForLevel('basic');
    }

    return SolutionAssessment(
      achievementLevel: achievementLevel,
      pointsEarned: pointsEarned,
      criteriaMet: criteriaMet,
    );
  }

  @override
  ValidationFeedback createFeedback({
    required ChallengeModel challenge,
    required bool success,
    required List<ValidationIssue> issues,
    required SolutionAssessment assessment,
  }) {
    // Create feedback based on success and achievement level
    if (!success) {
      // Feedback for unsuccessful solutions
      return _createUnsuccessfulFeedback(challenge, issues);
    } else {
      // Feedback for successful solutions
      return _createSuccessfulFeedback(challenge, assessment);
    }
  }

  @override
  Future<List<Achievement>> getAchievements({
    required ChallengeModel challenge,
    required bool success,
    required SolutionAssessment assessment,
  }) async {
    // If the solution doesn't meet the basic success criteria,
    // no achievements are unlocked
    if (!success) return [];

    // Create achievements based on the assessment
    final achievements = <Achievement>[];

    // Add achievement for completing the challenge
    achievements.add(Achievement(
      id: 'challenge_${challenge.id}',
      name: 'Completed: ${challenge.title}',
      description: 'Successfully completed the "${challenge.title}" challenge.',
      points: assessment.pointsEarned,
      type: 'challenge',
    ));

    // Add achievement for achievement level
    if (assessment.achievementLevel == 'advanced') {
      achievements.add(Achievement(
        id: 'advanced_${challenge.id}',
        name: 'Advanced: ${challenge.title}',
        description: 'Achieved advanced level in the "${challenge.title}" challenge.',
        points: 5,
        type: 'achievement_level',
      ));
    } else if (assessment.achievementLevel == 'proficient') {
      achievements.add(Achievement(
        id: 'proficient_${challenge.id}',
        name: 'Proficient: ${challenge.title}',
        description: 'Achieved proficient level in the "${challenge.title}" challenge.',
        points: 3,
        type: 'achievement_level',
      ));
    }

    return achievements;
  }

  /// Validate a solution against the success criteria.
  List<ValidationIssue> _validateSuccessCriteria(
    ChallengeModel challenge,
    PatternModel solution,
  ) {
    final issues = <ValidationIssue>[];
    final criteria = challenge.successCriteria;

    // Check required block types
    for (final blockType in criteria.requiresBlockType) {
      if (!solution.hasBlockType(blockType)) {
        issues.add(ValidationIssue(
          type: 'missing_block_type',
          message: 'Missing required block type: $blockType',
          details: {'blockType': blockType},
          severity: 'error',
        ));
      }
    }

    // Check minimum connections
    if (solution.connectionCount < criteria.minConnections) {
      issues.add(ValidationIssue(
        type: 'insufficient_connections',
        message: 'Insufficient connections: ${solution.connectionCount} (required: ${criteria.minConnections})',
        details: {
          'connectionCount': solution.connectionCount,
          'requiredConnectionCount': criteria.minConnections,
        },
        severity: 'error',
      ));
    }

    // Check maximum blocks (if specified)
    if (criteria.maxBlocks != null && solution.blockCount > criteria.maxBlocks!) {
      issues.add(ValidationIssue(
        type: 'too_many_blocks',
        message: 'Too many blocks: ${solution.blockCount} (maximum: ${criteria.maxBlocks})',
        details: {
          'blockCount': solution.blockCount,
          'maxBlocks': criteria.maxBlocks,
        },
        severity: 'error',
      ));
    }

    // Check required structure (if specified)
    if (criteria.requiredStructure != null) {
      final hasRequiredStructure = _checkRequiredStructure(
        solution,
        criteria.requiredStructure!,
      );

      if (!hasRequiredStructure) {
        issues.add(ValidationIssue(
          type: 'incorrect_structure',
          message: 'Pattern does not match the required structure',
          details: {'requiredStructure': criteria.requiredStructure},
          severity: 'error',
        ));
      }
    }

    // Check required output (if specified)
    if (criteria.requiredOutput != null) {
      final hasRequiredOutput = _checkRequiredOutput(
        solution,
        criteria.requiredOutput!,
      );

      if (!hasRequiredOutput) {
        issues.add(ValidationIssue(
          type: 'incorrect_output',
          message: 'Pattern does not produce the required output',
          details: {'requiredOutput': criteria.requiredOutput},
          severity: 'error',
        ));
      }
    }

    // Check custom criteria (if any)
    if (criteria.customCriteria.isNotEmpty) {
      final customIssues = _checkCustomCriteria(
        solution,
        criteria.customCriteria,
      );

      issues.addAll(customIssues);
    }

    return issues;
  }

  /// Check if a solution matches a required structure.
  bool _checkRequiredStructure(PatternModel solution, String requiredStructure) {
    // This is a simplified implementation
    // A more sophisticated approach would use pattern matching

    // For now, we'll just check if the solution contains the required structure
    return solution.structure.contains(requiredStructure);
  }

  /// Check if a solution produces a required output.
  bool _checkRequiredOutput(PatternModel solution, String requiredOutput) {
    // This is a simplified implementation
    // A more sophisticated approach would execute the pattern

    // For now, we'll just check if the solution's output contains the required output
    return solution.output.contains(requiredOutput);
  }

  /// Check custom criteria for a solution.
  List<ValidationIssue> _checkCustomCriteria(
    PatternModel solution,
    Map<String, dynamic> customCriteria,
  ) {
    // This is a simplified implementation
    // A more sophisticated approach would use a custom criteria evaluator

    // For now, we'll just return an empty list
    return [];
  }

  /// Check which criteria are met by a solution.
  List<String> _checkCriteriaMet(
    Map<String, String> criteria,
    PatternModel solution,
    List<ValidationIssue> issues,
  ) {
    // This is a simplified implementation
    // A more sophisticated approach would evaluate each criterion

    // For now, we'll assume all criteria are met if there are no errors
    if (issues.any((issue) => issue.severity == 'error')) {
      return [];
    }

    return criteria.keys.toList();
  }

  /// Create feedback for an unsuccessful solution.
  ValidationFeedback _createUnsuccessfulFeedback(
    ChallengeModel challenge,
    List<ValidationIssue> issues,
  ) {
    // Create a title based on the issues
    String title = 'Almost there!';

    // Create a message based on the issues
    String message = 'Your solution needs some adjustments.';

    // Create detailed feedback based on the issues
    String details = 'Here\'s what needs to be fixed:';

    // Create suggestions based on the issues
    final suggestions = <String>[];

    // Process each issue
    for (final issue in issues) {
      if (issue.severity == 'error') {
        details += '\n- ${issue.message}';

        // Add suggestions based on issue type
        if (issue.type == 'missing_block_type') {
          final blockType = issue.details['blockType'] as String;
          suggestions.add('Add a $blockType block to your pattern.');
        } else if (issue.type == 'insufficient_connections') {
          final connectionCount = issue.details['connectionCount'] as int;
          final requiredConnectionCount = issue.details['requiredConnectionCount'] as int;
          suggestions.add('Connect more blocks. You need at least $requiredConnectionCount connections (you have $connectionCount).');
        } else if (issue.type == 'too_many_blocks') {
          final blockCount = issue.details['blockCount'] as int;
          final maxBlocks = issue.details['maxBlocks'] as int;
          suggestions.add('Use fewer blocks. You can use at most $maxBlocks blocks (you have $blockCount).');
        } else if (issue.type == 'incorrect_structure') {
          suggestions.add('Arrange your blocks to match the required structure.');
        } else if (issue.type == 'incorrect_output') {
          suggestions.add('Modify your pattern to produce the required output.');
        }
      }
    }

    // Add educational context
    String educationalContext = 'This challenge helps you practice ';
    educationalContext += challenge.requiredConcepts.join(', ');
    educationalContext += '.';

    return ValidationFeedback(
      title: title,
      message: message,
      details: details,
      suggestions: suggestions,
      educationalContext: educationalContext,
    );
  }

  /// Create feedback for a successful solution.
  ValidationFeedback _createSuccessfulFeedback(
    ChallengeModel challenge,
    SolutionAssessment assessment,
  ) {
    // Create a title based on the assessment
    String title;
    String message;
    String details;
    final suggestions = <String>[];

    switch (assessment.achievementLevel) {
      case 'advanced':
        title = 'Outstanding Work!';
        message = 'You\'ve mastered this challenge at an advanced level!';
        details = 'Your solution demonstrates exceptional understanding of the concepts.';
        break;
      case 'proficient':
        title = 'Great Job!';
        message = 'You\'ve completed this challenge at a proficient level!';
        details = 'Your solution shows good understanding of the concepts.';
        suggestions.add('Try to improve your solution to reach the advanced level.');
        break;
      case 'basic':
        title = 'Good Work!';
        message = 'You\'ve completed this challenge at a basic level!';
        details = 'Your solution meets the basic requirements.';
        suggestions.add('Try to improve your solution to reach the proficient level.');
        break;
      default:
        title = 'Challenge Completed!';
        message = 'You\'ve successfully completed this challenge!';
        details = 'Your solution meets the requirements.';
    }

    // Add criteria met to details
    if (assessment.criteriaMet.isNotEmpty) {
      details += '\n\nYou\'ve met the following criteria:';

      for (final entry in assessment.criteriaMet.entries) {
        final level = entry.key;
        final criteria = entry.value;

        details += '\n\n$level level:';
        for (final criterion in criteria) {
          details += '\n- $criterion';
        }
      }
    }

    // Add educational context
    String educationalContext = 'This challenge helps you practice ';
    educationalContext += challenge.requiredConcepts.join(', ');
    educationalContext += '.';

    return ValidationFeedback(
      title: title,
      message: message,
      details: details,
      suggestions: suggestions,
      educationalContext: educationalContext,
    );
  }
}
