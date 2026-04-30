import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'package:chatmcp/utils/color.dart';
import 'package:chatmcp/widgets/composio_auth_button.dart';

SpanNodeGeneratorWithTag linkGenerator = SpanNodeGeneratorWithTag(
  tag: _linkTag,
  generator: (e, config, visitor) => MyLinkNode(e.attributes, e.textContent, config),
);

const _linkTag = 'a';

class MyLinkNode extends SpanNode {
  final Map<String, String> attributes;
  final String textContent;
  final MarkdownConfig config;

  MyLinkNode(this.attributes, this.textContent, this.config);

  @override
  InlineSpan build() {
    final href = attributes['href'] ?? '';
    final content = attributes['content'] ?? href;
    if (_isComposioAuthLink(href)) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: ComposioAuthButton(
          url: href,
          label: content.isEmpty ? 'Connect account' : content,
          toolkit: _inferToolkit(content),
        ),
      );
    }
    return TextSpan(
      text: content,
      style: TextStyle(color: AppColors.getLinkColor(), decoration: TextDecoration.none),
      recognizer: TapGestureRecognizer()
        ..onTap = () {
          final url = href;
          if (url.startsWith("#")) {
            return;
          }
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        },
    );
  }

  bool _isComposioAuthLink(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) return false;
    // Composio-hosted auth link (redirects to OAuth provider).
    if ((uri.host == 'connect.composio.dev' || uri.host == 'platform.composio.dev') &&
        uri.path.startsWith('/link/')) {
      return true;
    }
    // Direct OAuth URL returned by some Composio configurations.
    final path = uri.path.toLowerCase();
    final host = uri.host.toLowerCase();
    return host.contains('composio') ||
        path.contains('/oauth') ||
        path.contains('/auth/') ||
        (host == 'accounts.google.com' && path.contains('/o/oauth2'));
  }

  String? _inferToolkit(String value) {
    final text = value.toLowerCase();
    final match = RegExp(r'connect\s+([a-z0-9_-]+)').firstMatch(text);
    if (match != null) return match.group(1);
    if (text.contains('gmail')) return 'gmail';
    return null;
  }
}

class LinkSyntax extends md.InlineSyntax {
  LinkSyntax() : super(r'\[([^\]]*)\]\(([^\)]+)\)');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final element = md.Element.text('a', match.group(1) ?? '');
    element.attributes['href'] = match.group(2) ?? '';
    element.attributes['content'] = match.group(1) ?? '';
    parser.addNode(element);
    return true;
  }
}
