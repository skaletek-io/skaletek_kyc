import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';
import 'package:skaletek_kyc/l10n/generated/app_localizations.dart';
import 'app_color.dart';

/// Language switcher dropdown component
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColor.light),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: languageService.currentLocale.languageCode,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: AppColor.text,
                size: 20,
              ),
              style: TextStyle(
                color: AppColor.text,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              onChanged: (String? newLanguage) {
                if (newLanguage != null) {
                  languageService.changeLanguage(newLanguage);
                }
              },
              items: LanguageService.supportedLocales
                  .map<DropdownMenuItem<String>>((Locale locale) {
                    final languageCode = locale.languageCode;
                    String displayName;

                    // Use localized language names when available
                    switch (languageCode) {
                      case 'en':
                        displayName = localizations?.english ?? 'English';
                        break;
                      case 'fr':
                        displayName = localizations?.french ?? 'Français';
                        break;
                      case 'es':
                        displayName = localizations?.spanish ?? 'Español';
                        break;
                      default:
                        displayName = languageService.getLanguageName(
                          languageCode,
                        );
                    }

                    return DropdownMenuItem<String>(
                      value: languageCode,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Language flag emoji could be added here
                          _getLanguageFlag(languageCode),
                          const SizedBox(width: 8),
                          Text(displayName),
                        ],
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  /// Get flag emoji for language (simple implementation)
  Widget _getLanguageFlag(String languageCode) {
    String flag;
    switch (languageCode) {
      case 'en':
        flag = '🇺🇸'; // US flag for English
        break;
      case 'fr':
        flag = '🇫🇷'; // French flag
        break;
      case 'es':
        flag = '🇪🇸'; // Spanish flag
        break;
      default:
        flag = '🌐'; // Globe for unknown
    }

    return Text(flag, style: const TextStyle(fontSize: 16));
  }
}
