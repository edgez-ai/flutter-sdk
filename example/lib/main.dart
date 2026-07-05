import 'dart:async';

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const EdgezExampleApp());
}

class EdgezExampleApp extends StatefulWidget {
  const EdgezExampleApp({super.key});

  @override
  State<EdgezExampleApp> createState() => _EdgezExampleAppState();
}

class _EdgezExampleAppState extends State<EdgezExampleApp> {
  final EdgezMeshSdk sdk = EdgezMeshSdk();
  final Map<int, EdgezMeshNode> nodes = <int, EdgezMeshNode>{};
  final Map<int, List<EdgezConversationMessage>> conversations = <int, List<EdgezConversationMessage>>{};
  final TextEditingController meshIdController = TextEditingController(text: 'edgez-mesh');
  final TextEditingController passphraseController = TextEditingController();
  StreamSubscription<EdgezMeshEvent>? subscription;
  EdgezConnectionType connection = EdgezConnectionType.none;
  EdgezMeshStatus? status;
  int selectedIndex = 0;
  int? selectedNode;
  String logLine = '';

  @override
  void initState() {
    super.initState();
    subscription = sdk.events.listen(_handleEvent);
  }

  @override
  void dispose() {
    subscription?.cancel();
    meshIdController.dispose();
    passphraseController.dispose();
    super.dispose();
  }

  void _handleEvent(EdgezMeshEvent event) {
    setState(() {
      switch (event.type) {
        case EdgezMeshEventType.connection:
          connection = event.connection;
        case EdgezMeshEventType.status:
          status = event.status;
        case EdgezMeshEventType.node:
          final node = event.node;
          if (node != null) nodes[node.nodeNum] = node;
        case EdgezMeshEventType.message:
          final message = event.message;
          if (message != null) {
            conversations[message.nodeNum] = <EdgezConversationMessage>[
              ...(conversations[message.nodeNum] ?? const <EdgezConversationMessage>[]),
              message,
            ];
          }
        case EdgezMeshEventType.log:
          logLine = event.log;
      }
    });
  }

  Future<void> _connectBle() async {
    await sdk.startBleScan();
    setState(() => connection = EdgezConnectionType.ble);
  }

  Future<void> _initializeMesh() {
    return sdk.initializeMesh(
      EdgezMeshConfig(
        countryCode: 'EU',
        meshId: meshIdController.text.trim(),
        passphrase: passphraseController.text,
        maxHop: 4,
        identity: const EdgezUserIdentity(
          userIdHigh: 0,
          userIdLow: 1,
          name: 'Flutter Demo',
          publicKey: <int>[],
        ),
      ),
    );
  }

  void _addDemoNode() {
    final node = EdgezMeshNode(
      nodeNum: DateTime.now().millisecondsSinceEpoch & 0xffffffffffff,
      userUuid: '',
      displayName: 'Demo node ${nodes.length + 1}',
      route: connection.name,
      lastSeenMs: DateTime.now().millisecondsSinceEpoch,
      marker: 'blue',
      deviceType: 'handheld',
    );
    setState(() => nodes[node.nodeNum] = node);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      NodesPage(
        connection: connection,
        status: status,
        nodes: nodes.values.toList()
          ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase())),
        onOpenConversation: (node) => setState(() {
          selectedNode = node.nodeNum;
          selectedIndex = 1;
        }),
        onRemoveNode: (node) => setState(() {
          nodes.remove(node.nodeNum);
          conversations.remove(node.nodeNum);
          if (selectedNode == node.nodeNum) selectedNode = null;
        }),
        onAddDemoNode: _addDemoNode,
      ),
      ConversationPage(
        node: selectedNode == null ? null : nodes[selectedNode],
        messages: selectedNode == null ? const <EdgezConversationMessage>[] : conversations[selectedNode] ?? const <EdgezConversationMessage>[],
        onSend: (text) async {
          final nodeNum = selectedNode;
          if (nodeNum == null) return;
          final message = EdgezConversationMessage(
            nodeNum: nodeNum,
            text: text,
            mine: true,
            timestampMs: DateTime.now().millisecondsSinceEpoch,
            status: 'Queued',
          );
          setState(() {
            conversations[nodeNum] = <EdgezConversationMessage>[
              ...(conversations[nodeNum] ?? const <EdgezConversationMessage>[]),
              message,
            ];
          });
          await sdk.sendTextMessage(toNode: nodeNum, text: text, maxHop: 4);
        },
      ),
      SettingsPage(
        meshIdController: meshIdController,
        passphraseController: passphraseController,
        onConnectBle: _connectBle,
        onDisconnect: () async {
          await sdk.disconnect();
          setState(() => connection = EdgezConnectionType.none);
        },
        onInitializeMesh: _initializeMesh,
        logLine: logLine,
      ),
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: Scaffold(
        body: pages[selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) => setState(() => selectedIndex = index),
          destinations: const <NavigationDestination>[
            NavigationDestination(icon: Icon(Icons.hub_outlined), selectedIcon: Icon(Icons.hub), label: 'Nodes'),
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Chat'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}

class NodesPage extends StatelessWidget {
  const NodesPage({
    required this.connection,
    required this.status,
    required this.nodes,
    required this.onOpenConversation,
    required this.onRemoveNode,
    required this.onAddDemoNode,
    super.key,
  });

  final EdgezConnectionType connection;
  final EdgezMeshStatus? status;
  final List<EdgezMeshNode> nodes;
  final ValueChanged<EdgezMeshNode> onOpenConversation;
  final ValueChanged<EdgezMeshNode> onRemoveNode;
  final VoidCallback onAddDemoNode;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text('Nodes', style: Theme.of(context).textTheme.headlineMedium)),
              Icon(status?.isUsable == true ? Icons.check_circle : Icons.radio_button_unchecked),
            ],
          ),
          const SizedBox(height: 6),
          Text('Interface: ${connection.name.toUpperCase()}'),
          const SizedBox(height: 16),
          if (nodes.isEmpty) const Text('No HaLow users seen yet'),
          for (final node in nodes)
            Card(
              child: ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: Text(node.displayName),
                subtitle: Text('Node ${node.nodeId}\nRoute ${node.route}${node.sleeping ? '\nSleeping' : ''}'),
                isThreeLine: true,
                onTap: () => onOpenConversation(node),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onRemoveNode(node),
                ),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onAddDemoNode,
            icon: const Icon(Icons.add),
            label: const Text('Add demo node'),
          ),
        ],
      ),
    );
  }
}

class ConversationPage extends StatefulWidget {
  const ConversationPage({
    required this.node,
    required this.messages,
    required this.onSend,
    super.key,
  });

  final EdgezMeshNode? node;
  final List<EdgezConversationMessage> messages;
  final FutureOr<void> Function(String text) onSend;

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(node?.displayName ?? 'Select a node', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: <Widget>[
                  if (widget.messages.isEmpty) const Center(child: Text('No messages yet')),
                  for (final message in widget.messages)
                    Align(
                      alignment: message.mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Card(
                        color: message.mine ? Theme.of(context).colorScheme.primaryContainer : null,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(message.text),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: node != null,
                    decoration: const InputDecoration(labelText: 'Message'),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: node == null
                      ? null
                      : () {
                          final text = controller.text.trim();
                          if (text.isEmpty) return;
                          unawaited(Future<void>.value(widget.onSend(text)));
                          controller.clear();
                        },
                  child: const Text('Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.meshIdController,
    required this.passphraseController,
    required this.onConnectBle,
    required this.onDisconnect,
    required this.onInitializeMesh,
    required this.logLine,
    super.key,
  });

  final TextEditingController meshIdController;
  final TextEditingController passphraseController;
  final VoidCallback onConnectBle;
  final VoidCallback onDisconnect;
  final VoidCallback onInitializeMesh;
  final String logLine;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.icon(onPressed: onConnectBle, icon: const Icon(Icons.bluetooth), label: const Text('BLE')),
              OutlinedButton.icon(onPressed: onDisconnect, icon: const Icon(Icons.link_off), label: const Text('Disconnect')),
            ],
          ),
          const SizedBox(height: 16),
          TextField(controller: meshIdController, decoration: const InputDecoration(labelText: 'Mesh ID')),
          const SizedBox(height: 8),
          TextField(controller: passphraseController, decoration: const InputDecoration(labelText: 'Passphrase')),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: onInitializeMesh, icon: const Icon(Icons.hub), label: const Text('Initialize mesh')),
          if (logLine.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(logLine),
          ],
        ],
      ),
    );
  }
}
