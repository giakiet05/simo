import '../agent_tool.dart';

/// Navigation tool allowing the AI Agent to trigger route transitions to specific app screens.
class NavigateScreenTool extends SimoAgentTool<Map<String, dynamic>, bool> {
  @override
  String get name => 'navigate_screen';

  @override
  String get description => 'Điều hướng mở màn hình trong ứng dụng (Báo cáo, Ngân sách, Ví, Sao lưu, Cài đặt)';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'required': ['destination'],
    'properties': {
      'destination': {
        'type': 'string',
        'enum': [
          'dashboard',
          'reports',
          'wallets',
          'budgets',
          'loans',
          'goals',
          'export_backup',
          'settings',
          'categories',
        ],
      },
    },
  };

  @override
  Future<bool> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final destination = input['destination'] as String? ?? 'dashboard';
    if (context.onNavigate != null) {
      await context.onNavigate!(destination);
      return true;
    }
    return false;
  }
}
