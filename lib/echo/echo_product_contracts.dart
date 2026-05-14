import 'package:flutter/material.dart';

import 'package:chatmcp/echo/echo_runtime_service.dart';
import 'package:chatmcp/echo/echo_theme.dart';

class EchoOpportunitySeed {
  final String title;
  final String type;
  final String description;
  final List<String> requiredProof;
  final List<String> missingProof;
  final String nextStep;
  final int readiness;

  const EchoOpportunitySeed({
    required this.title,
    required this.type,
    required this.description,
    required this.requiredProof,
    required this.missingProof,
    required this.nextStep,
    required this.readiness,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': type,
      'description': description,
      'required_proof': requiredProof,
      'missing_proof': missingProof,
      'next_step': nextStep,
      'readiness': readiness,
      'seeded': true,
    };
  }
}

const echoOpportunitySeeds = <EchoOpportunitySeed>[
  EchoOpportunitySeed(
    title: 'Scholarship story',
    type: 'scholarship',
    readiness: 35,
    description: 'Turn lived effort, proof, and a future plan into a scholarship-ready narrative.',
    requiredProof: ['lived challenge', 'two proof items', 'feedback quote', 'future plan', 'safe share version'],
    missingProof: ['feedback quote', 'safe share version'],
    nextStep: 'Save one outcome and ask one person for a sentence of feedback.',
  ),
  EchoOpportunitySeed(
    title: 'Starter portfolio',
    type: 'portfolio',
    readiness: 42,
    description: 'Show one shipped artifact with a clear before/after result and plain-language tradeoff.',
    requiredProof: ['shipped artifact', 'measured result', 'tradeoff note', 'public link'],
    missingProof: ['public link'],
    nextStep: 'Draft a short public artifact from your strongest proof item.',
  ),
  EchoOpportunitySeed(
    title: 'First job application',
    type: 'job',
    readiness: 30,
    description: 'Map proof of skill, communication, and reliability to one realistic role.',
    requiredProof: ['skill proof', 'communication proof', 'reliability proof', 'role narrative'],
    missingProof: ['role narrative', 'reliability proof'],
    nextStep: 'Build one proof item that shows how you worked with another person or deadline.',
  ),
  EchoOpportunitySeed(
    title: 'Community project',
    type: 'community',
    readiness: 25,
    description: 'Use proof to make a credible ask for a local, school, or online project.',
    requiredProof: ['problem statement', 'contribution proof', 'collaborator feedback', 'next ask'],
    missingProof: ['collaborator feedback', 'next ask'],
    nextStep: 'Write the problem in one sentence and attach one piece of contribution proof.',
  ),
  EchoOpportunitySeed(
    title: 'Open-source contribution',
    type: 'project',
    readiness: 20,
    description: 'Turn a small technical fix into public proof that other people can verify.',
    requiredProof: ['issue context', 'pull request or patch', 'review response', 'learning note'],
    missingProof: ['pull request or patch', 'review response'],
    nextStep: 'Find one small issue where your current proof already gives you context.',
  ),
  EchoOpportunitySeed(
    title: 'Personal goal',
    type: 'personal_goal',
    readiness: 50,
    description: 'Convert repeated practice into evidence that behavior is changing.',
    requiredProof: ['baseline', 'repeated practice', 'outcome trend', 'reflection'],
    missingProof: ['outcome trend'],
    nextStep: 'Log the same practice outcome for three days so Echo can show a trend.',
  ),
];

class EchoRuntimeCapability {
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final bool available;

  const EchoRuntimeCapability({required this.title, required this.body, required this.icon, required this.color, required this.available});
}

List<EchoRuntimeCapability> echoRuntimeCapabilities({
  required EchoRuntimeService runtime,
  required bool memoryReady,
  required int queuedOutcomes,
  bool backendReachable = true,
}) {
  final connected = runtime.isDesktop || runtime.isCloud;
  final homeBrainTraining = runtime.isDesktop && backendReachable;
  return [
    EchoRuntimeCapability(
      title: 'Talk',
      body: runtime.isDevice ? 'Offline answers with compressed context.' : 'Connected to ${runtime.modeLabel}.',
      icon: Icons.chat_bubble_outline_rounded,
      color: EchoColors.primaryAi,
      available: runtime.isDeviceReady || connected,
    ),
    EchoRuntimeCapability(
      title: 'Today',
      body: runtime.isDevice ? 'Cached next step and local outcomes.' : 'Live priority, mission, and practice.',
      icon: Icons.flag_outlined,
      color: EchoColors.practice,
      available: runtime.isDevice ? memoryReady : backendReachable,
    ),
    EchoRuntimeCapability(
      title: 'Proof',
      body: queuedOutcomes > 0 ? '$queuedOutcomes outcomes queued for sync.' : 'Proof capture is ready.',
      icon: Icons.inventory_2_outlined,
      color: EchoColors.proof,
      available: true,
    ),
    EchoRuntimeCapability(
      title: 'Opportunities',
      body: runtime.isDevice ? 'Seeded scoring until sync returns.' : 'Rule-scored proof gaps from Echo.',
      icon: Icons.workspace_premium_outlined,
      color: EchoColors.opportunity,
      available: true,
    ),
    EchoRuntimeCapability(
      title: 'Improve Echo',
      body: homeBrainTraining ? 'Learns from outcomes and best-answer picks.' : 'Queues lessons until Home Brain returns.',
      icon: Icons.model_training_rounded,
      color: EchoColors.memory,
      available: homeBrainTraining,
    ),
  ];
}
