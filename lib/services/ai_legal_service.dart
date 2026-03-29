import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_config.dart';

class AILegalService {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ));

  // ── System Prompts ──

  static const String _cyberHelpPrompt = '''
You are a specialized Cyber Safety Assistant. Your goal is to analyze reported digital harassment.
Response Guidelines:
1. RESPONSE MUST BE IN STRUCTURED MARKDOWN (Headings, Bold, Lists).
2. Maintain a calm, supportive tone.
3. Categorize the type of bullying (doxing, flaming, exclusion, etc.) using `### Category`.
4. Provide immediate 'Digital First Aid' steps (block, report, privacy settings) in a bulleted list.
5. Advise the user on how to save evidence (logs, timestamps).
6. Crucial: If the user expresses self-harm or extreme distress, prioritize providing local helpline numbers immediately.
''';

  static const String _autoFirPrompt = '''
You are an AI Legal Scribe. Your task is to take raw, often emotional descriptions of a crime and format them into a structured, chronological draft for an FIR.
Response Guidelines:
1. RESPONSE MUST BE IN STRUCTURED MARKDOWN.
2. Use formal, objective language.
3. Organize the output into clear sections using `### Headings`: ### Incident Details, ### Victim Info, ### Accused Description, and ### Narrative description.
4. Do not include personal opinions or hearsay.
5. Disclaimer: Add a mandatory notice that this is a draft and must be verified and filed by an authorized police officer to become a legal document.
''';

  static const String _lawCounselingPrompt = '''
You are a Legal Information Assistant specializing in Tourist Rights and Criminal Law.
Response Guidelines:
1. RESPONSE MUST BE IN STRUCTURED MARKDOWN.
2. Identify relevant legal sections (e.g., IPC/BNS) based on the user's description using `### Legal Sections`.
3. Explain legal jargon in simple, layman's terms.
4. Outline the 'Next Steps' (e.g., contacting the Embassy, finding a local lawyer) in a specific bulleted section named `### Next Steps`.
5. Constraint: Never guarantee a legal outcome. Always include: 'I am an AI, not a lawyer. This information is for educational purposes only.'
''';

  /// Generic method to call OpenRouter Gemini API
  static Future<String> _callAI(String systemPrompt, String userMessage) async {
    try {
      final response = await _dio.post(
        ApiConfig.aiUrl,
        data: {
          'model': 'openai/gpt-4o-mini',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'max_tokens': 2048,
          'temperature': 0.7,
        },
      );

      if (response.statusCode == 200) {
        final choices = response.data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          return choices[0]['message']['content'] as String? ?? 'No response from AI.';
        }
      }
      return 'Failed to get a response. Please try again.';
    } on DioException catch (e) {
      debugPrint('AILegalService Dio Error: ${e.response?.data ?? e.message}');
      String errMsg = 'API Error';
      if (e.response != null && e.response!.data is Map) {
        final errorData = e.response!.data['error'];
        if (errorData is Map) {
          errMsg = errorData['message'] ?? 'Service Error';
        } else {
          errMsg = errorData?.toString() ?? e.response!.data.toString();
        }
      } else {
        errMsg = e.message ?? 'Unknown network error';
      }
      return 'Error: AI Service reported an issue ($errMsg). Please ensure your configuration is correct.';
    } catch (e) {
      debugPrint('AILegalService internal error: $e');
      return 'Error: An internal error occurred. Please try again later.';
    }
  }

  // ── Public API ──

  static Future<String> getCyberHelp({
    required String description,
    required String platform,
    required String frequency,
    required String emotionalState,
  }) {
    final userMessage = '''
Incident Description: $description
Platform: $platform
Frequency: $frequency
Current Emotional State: $emotionalState
''';
    return _callAI(_cyberHelpPrompt, userMessage);
  }

  static Future<String> generateFIR({
    required String crimeType,
    required String dateTime,
    required String location,
    required String incidentDescription,
    required String accusedDescription,
    required String witnesses,
  }) {
    final userMessage = '''
Nature of Crime: $crimeType
Date & Time: $dateTime
Location: $location
Incident Description: $incidentDescription
Accused Description: $accusedDescription
Witnesses: $witnesses
''';
    return _callAI(_autoFirPrompt, userMessage);
  }

  static Future<String> getLawCounseling({
    required String situation,
    required String nationality,
    required String goal,
  }) {
    final userMessage = '''
Situation: $situation
Nationality: $nationality
Primary Goal: $goal
''';
    return _callAI(_lawCounselingPrompt, userMessage);
  }
}
