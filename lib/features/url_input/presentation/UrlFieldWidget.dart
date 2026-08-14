import 'package:NoJob/features/logs/presentation/verification_webview.dart';
import 'package:NoJob/features/url_input/presentation/UrlFieldProvider.dart';
import 'package:NoJob/shared/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UrlFieldWidget extends ConsumerStatefulWidget {
  const UrlFieldWidget({super.key});

  @override
  ConsumerState<UrlFieldWidget> createState() => _UrlFieldWidgetState();
}

class _UrlFieldWidgetState extends ConsumerState<UrlFieldWidget> {
  final TextEditingController _urlController = TextEditingController();

  void _showVerificationDialog() async {
    final url = _urlController.text;
    final result = await showDialog(
      context: context,
      builder: (context) => VerificationDialog(url: url),
    );

    // If verification completed - retry parsing
    if (result) {
      _onTextInput();
    }
  }

  void _onTextInput() async {
    "_onTextInput called: ${_urlController.text}".e;

    final notifier = ref.read(urlFieldProvider.notifier);
    await notifier.parse(_urlController.text);
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(urlFieldProvider);

    return asyncState.when(
      data: (state) {
        final isLoading = state is UrlFieldLoading;
        final errorText = state is UrlFieldError ? state.errorMessage : null;
        final verificationRequired = state is VerificationRequired;

        // If ok - clear text
        if (state is UrlFieldSuccess) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _urlController.clear();
            ref.read(urlFieldProvider.notifier).reset();
          });
        }

        // If verificationRequired - show verification dialog
        if (verificationRequired) {
          _showVerificationDialog();
        }

        return Container(
          alignment: Alignment.topCenter,
          height: 150,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Stack(
            alignment: Alignment.center,
            children: [
              TextField(
                enabled: !isLoading,
                controller: _urlController,
                onSubmitted: (_) => _onTextInput(),
                onChanged: (_) {
                  _onTextInput();
                },
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.go,
                decoration: InputDecoration(
                  errorText: errorText,
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: TextButton(
                      onPressed: !isLoading
                          ? () => _pasteFromClipboard()
                          : null,
                      child: Text(context.res.paste),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 24.0,
                  ),
                  hintText: context.res.inputLink,
                  filled: true,
                  fillColor: context.theme.cardColor,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: context.appTheme.colorTheme.backgroundColor,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: context.appTheme.colorTheme.accentColor,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
              ),
              if (isLoading) const CircularProgressIndicator(),
            ],
          ),
        );
      },
      error: (err, stack) => const Text("Critical Error"),
      loading: () => const CircularProgressIndicator(),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      setState(() {
        _urlController.text = data.text!;
        _onTextInput();
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
