import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {

  // Local cache of known drug interactions to avoid unnecessary API calls.
  // Keys are lowercase medicine name keywords; values are maps of interacting keywords -> reason.
  static const Map<String, Map<String, String>> _knownInteractions = {
    'aspirin': {
      'ibuprofen': 'Both Aspirin and Ibuprofen are NSAIDs. Taking them together significantly increases the risk of gastrointestinal bleeding and reduces the cardioprotective effect of Aspirin.',
      'warfarin': 'Aspirin potentiates the anticoagulant effect of Warfarin, greatly increasing bleeding risk.',
      'naproxen': 'Both are NSAIDs. Concurrent use increases GI bleeding risk and reduces Aspirin\'s platelet effect.',
      'clopidogrel': 'Dual antiplatelet therapy increases bleeding risk significantly.',
    },
    'ibuprofen': {
      'aspirin': 'Both are NSAIDs. Concurrent use significantly increases GI bleeding risk.',
      'warfarin': 'Ibuprofen can increase Warfarin\'s blood-thinning effect, increasing bleeding risk.',
      'lithium': 'NSAIDs like Ibuprofen can raise Lithium levels to toxic ranges.',
      'methotrexate': 'Ibuprofen can reduce Methotrexate excretion, leading to toxicity.',
    },
    'metformin': {
      'alcohol': 'Alcohol combined with Metformin increases risk of lactic acidosis.',
      'contrast': 'Iodinated contrast media with Metformin can cause lactic acidosis.',
    },
    'warfarin': {
      'aspirin': 'Increases anticoagulation and bleeding risk significantly.',
      'ibuprofen': 'NSAIDs increase Warfarin\'s anticoagulant effect, raising bleeding risk.',
      'amoxicillin': 'Antibiotics can alter gut flora and affect Vitamin K absorption, potentiating Warfarin.',
    },
    'amoxicillin': {
      'warfarin': 'Can potentiate Warfarin\'s effect by reducing Vitamin K-producing gut bacteria.',
      'methotrexate': 'Amoxicillin can reduce Methotrexate excretion, leading to toxicity.',
    },
    'atorvastatin': {
      'clarithromycin': 'Clarithromycin inhibits Atorvastatin metabolism, increasing risk of myopathy and rhabdomyolysis.',
      'erythromycin': 'Increases risk of statin-induced myopathy.',
    },
  };

  /// Checks for drug interactions locally first. Only calls Gemini API if no local match found.
  static Future<String?> checkMedicineClashes(List<String> currentMedicines, String newMedicine) async {
    print("--- GEMINI CLASH CHECK ---");
    print("Current Meds: $currentMedicines");
    print("New Med: $newMedicine");

    // 1. Fast local check first
    final localResult = _checkLocalInteractions(currentMedicines, newMedicine);
    if (localResult != null) {
      print("--- LOCAL MATCH FOUND ---");
      print(localResult);
      return localResult;
    }

    // 2. Fall back to Gemini API for unknowns
    return _callGemini(currentMedicines, newMedicine);
  }

  static String? _checkLocalInteractions(List<String> currentMedicines, String newMedicine) {
    final newLower = newMedicine.toLowerCase();
    for (final existing in currentMedicines) {
      final existingLower = existing.toLowerCase();
      // Check if new medicine clashes with an existing one (both directions)
      for (final entry in _knownInteractions.entries) {
        if (newLower.contains(entry.key)) {
          // newMedicine is a known risky drug
          for (final subEntry in entry.value.entries) {
            if (existingLower.contains(subEntry.key)) {
              return "CLASH: ${subEntry.value}";
            }
          }
        }
        if (existingLower.contains(entry.key)) {
          // existing medicine is a known risky drug
          for (final subEntry in entry.value.entries) {
            if (newLower.contains(subEntry.key)) {
              return "CLASH: ${subEntry.value}";
            }
          }
        }
      }
    }
    return null;
  }

  static Future<String?> _callGemini(List<String> currentMedicines, String newMedicine) async {
    String? apiKey;
    try {
      apiKey = dotenv.env['GEMINI_API_KEY'];
    } catch (e) {
      // dotenv not initialized or file missing
      apiKey = null;
    }
    
    if (apiKey == null || apiKey.isEmpty) {
      return null; // No key, skip silently
    }

    final prompt = """
I am a medical professional. Check for severe drug interactions.
Existing patient medicines: ${currentMedicines.isEmpty ? "None" : currentMedicines.join(', ')}.
New medicine to add: $newMedicine.

Respond STRICTLY with "CLASH: <reason>" if there is a severe or notable interaction.
Respond STRICTLY with "NO_CLASH" if there are no interactions. Nothing else.
""";

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
    );

    final body = jsonEncode({
      "contents": [{"parts": [{"text": prompt}]}],
      "generationConfig": {"temperature": 0.1, "maxOutputTokens": 150}
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );
      print("--- GEMINI HTTP STATUS ---");
      print(response.statusCode);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final text = decoded['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        final trimmed = text?.trim();
        print("--- GEMINI RESPONSE ---");
        print(trimmed);
        return trimmed;
      } else if (response.statusCode == 429) {
        // Rate limited - quietly skip to not block the doctor
        print("--- GEMINI RATE LIMITED (skipping) ---");
        return null;
      } else {
        print("--- GEMINI ERROR: ${response.statusCode} ---");
        return null;
      }
    } catch (e) {
      print("--- GEMINI EXCEPTION ---");
      print(e);
      return null;
    }
  }
}
